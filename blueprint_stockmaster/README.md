# Blueprint StockMaster-Pro

Dossier d'Architecture Technique (DAT) du module de gestion d'inventaire
physique de MegaShop-B2B.

Ce blueprint constitue le plan de construction remis à l'équipe de
développement. Il décrit un système de suivi de stock fondé sur un journal
de mouvements immuable, en remplacement des fichiers Excel du gestionnaire
d'entrepôt.

---

## Principe directeur

**Le stock n'est jamais stocké : il est calculé.**

Aucune colonne `quantite_totale` modifiable n'existe dans le modèle. Le stock
disponible d'un emplacement résulte de l'agrégation de son journal de
mouvements :

```
stock = SOMME(quantités des ENTREE) - SOMME(quantités des SORTIE)
```

Ce choix garantit la traçabilité exigée par le cahier des charges. Une valeur
d'état modifiable par `UPDATE` ne permet pas de répondre aux questions du
métier : quand le stock a-t-il baissé, de combien, et à la suite de quelle
opération.

---

## Livrables

| Fichier | Rôle | Format |
|---|---|---|
| `01_database_schema.sql` | Socle physique des données | PostgreSQL 14+ |
| `02_behavioral_architecture.md` | Mapping des couches, flux de traitement, décisions | Markdown + Mermaid |
| `03_api_contract.yaml` | Contrat d'interface exposé aux clients | OpenAPI 3.0.3 |
| `04_business_specs.feature` | Spécifications métier exécutables | Gherkin / Cucumber |

---

## Modèle de données

Trois entités.

**`produit`** - référentiel des articles. Deux identifiants distincts :
`id_produit` (technique) et `reference_produit` (clé métier scannée par le
manutentionnaire, contrainte `UNIQUE`).

**`emplacement`** - cases physiques de l'entrepôt. La règle « chaque
emplacement contient un et un seul type de produit » se traduit par une clé
étrangère `NOT NULL` vers `produit` et par l'absence de table d'association.
Un même produit peut en revanche occuper plusieurs emplacements.

**`mouvement_stock`** - journal en écriture seule. Chaque ligne enregistre une
entrée ou une sortie sur un emplacement, horodatée en `TIMESTAMPTZ`.

**`stock_courant`** - vue d'agrégation. `LEFT JOIN` et `COALESCE` garantissent
qu'un emplacement sans aucun mouvement affiche `0` et non `NULL`.

### Contraintes structurantes

| Contrainte | Garantie apportée |
|---|---|
| `chk_quantite_positive` | La quantité est toujours strictement positive. Le sens est porté par `type_mouvement`, jamais par le signe. |
| `chk_type_mouvement` | Seules les valeurs `ENTREE` et `SORTIE` sont admises. |
| `ON DELETE RESTRICT` | Impossible de supprimer un emplacement ou un produit portant un historique. La destruction de traçabilité est physiquement bloquée. |
| `idx_mouvement_emplacement` | Index sur la colonne filtrée par chaque calcul de stock, sur un journal destiné à croître indéfiniment. |

---

## Alignement inter-couches

Chaque concept métier porte un nom unique. Seule la convention de casse change
selon la couche technique.

| Concept | SQL | OpenAPI | Gherkin |
|---|---|---|---|
| Emplacement | `id_emplacement` | `emplacementId` | « l'emplacement ALLEE-A-RAYON-2 » |
| Sens du mouvement | `type_mouvement` | `typeMouvement` | `ENTREE` / `SORTIE` |
| Quantité | `quantite` | `quantite` | « unités » |
| Stock calculé | `quantite_disponible` | `quantiteDisponible` | « stock disponible » |

Les identifiants sont des entiers auto-générés (`GENERATED ALWAYS AS
IDENTITY`), et non des UUID. Le contrat OpenAPI reflète strictement ce choix
(`type: integer`, sans `format: uuid`).

Le fichier Gherkin est le seul à ne pas s'aligner sur les noms techniques :
il s'aligne sur les concepts, conformément au principe BDD. Les valeurs de
données (`ENTREE`, `SORTIE`, codes d'emplacement) y restent identiques aux
autres couches.

---

## Contrat d'interface

Route unique : `POST /inventory/movements`.

Le payload impose `emplacementId`, `typeMouvement` (énumération) et
`quantite` (`minimum: 1`, traduction exacte de `chk_quantite_positive`).
`additionalProperties: false` rejette tout champ non prévu.

Quatre réponses documentées, dont deux erreurs de nature distincte :

- **400** — le payload ne respecte pas le contrat. Détecté avant tout accès
  à la base.
- **409** — la requête est valide mais entre en conflit avec l'état réel du
  stock. Une sortie de 100 unités sur un emplacement qui en contient 42 est
  syntaxiquement correcte et métier-ement impossible.

---

## Spécifications métier

Le fichier `.feature` traduit la règle de gouvernance en langage lisible par
un directeur d'entrepôt. Aucun terme technique n'y figure : ni `POST`, ni
`INSERT`, ni code HTTP.

Le `Scenario Outline` couvre les limites mathématiques du métier sur un stock
initial de 42 unités :

| Sortie demandée | Résultat | Intention du test |
|---|---|---|
| 10 | acceptée | Cas nominal |
| 41 | acceptée | Juste sous la limite |
| 42 | acceptée | Stock ramené à zéro - autorisé |
| 43 | refusée | Premier dépassement |
| 100 | refusée | Dépassement franc |

Les valeurs 42 et 43 encadrent la frontière. Elles détectent un `>=` écrit à
la place d'un `>`. Sur les lignes refusées, le stock reste inchangé : une
opération rejetée ne modifie rien.

---

## Décision d'architecture — portée de la garde

Conformément au brief, la règle de non-négativité est portée par la couche
applicative, qui produit le message d'erreur métier. Le moteur SQL constitue
le rempart d'infrastructure : `chk_quantite_positive` interdit
structurellement l'insertion d'une quantité négative, quel que soit le chemin
d'accès aux données.

**Limitation documentée.** Le contrôle applicatif lit le stock puis écrit le
mouvement en deux opérations distinctes. En environnement fortement concurrent,
deux sorties simultanées sur un même emplacement peuvent toutes deux lire un
stock suffisant avant qu'aucune ne soit enregistrée. La levée de cette
limitation relève d'un verrouillage au niveau base (verrou explicite sur la
ligne `emplacement`, ou isolation `SERIALIZABLE`). Elle est identifiée comme
dette technique à traiter avant une mise en production multi-postes.

---

## Validation

**Traçabilité sémantique** : la racine `mouvement` est présente dans les
quatre livrables :

```bash
grep -rin "mouvement" . --include="*.sql" --include="*.md" \
  --include="*.yaml" --include="*.feature" -c
```

**Étanchéité SQL** : l'insertion d'une quantité négative est rejetée par le
moteur :

```bash
sudo -u postgres psql -d stockmaster -c \
  "INSERT INTO mouvement_stock (id_emplacement, type_mouvement, quantite) \
   VALUES (1, 'SORTIE', -500);"
```

Retour attendu : violation de `chk_quantite_positive`.

**Compilation stricte** : le contrat OpenAPI passe le linter sans erreur ni
avertissement :

```bash
npx @stoplight/spectral-cli lint 03_api_contract.yaml
```

Le diagramme Mermaid compile sans erreur de syntaxe.

**Absence de jargon technique dans le Gherkin** :

```bash
grep -inwE "post|insert|select|http|sql|table|endpoint|api" \
  04_business_specs.feature
```

Aucun résultat attendu. L'option `-w` est nécessaire : sans elle, `api`
matche dans « papier ».

---

## Environnement

- PostgreSQL 16
- Spectral CLI (via `npx`, sans installation globale)
- Extensions VS Code : Mermaid, OpenAPI (Swagger Editor), Cucumber (Gherkin)
  Full Support
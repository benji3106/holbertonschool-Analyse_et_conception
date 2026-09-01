# Modélisation Relationnelle

Projet d'analyse et conception : transformer un export CSV "legacy" chaotique en une base de données relationnelle PostgreSQL propre, normalisée et robuste.

## Contexte

MegaShop-B2B, un grossiste en matériel de bureau, gère ses commandes via un export CSV monolithique (`data/legacy_data.csv`). Ce fichier souffre d'anomalies classiques d'une donnée non normalisée : redondance des informations client et produit, perte de données historiques en cas de suppression. Voir `docs/README.md` pour le détail du contexte métier.

## Démarche du projet

1. **Audit du legacy** (`docs/rules.md`) : extraction des règles de gestion et des cardinalités à partir de l'analyse ligne par ligne du CSV.
2. **Modélisation conceptuelle** (`Schema.md`) : diagramme entité-association (MCD) au format Mermaid, dérivé directement des règles de gestion.
3. **Implémentation SQL** (`scripts/init_database.sql`) : traduction du MCD en script DDL PostgreSQL, avec contraintes d'intégrité au niveau du moteur.

## Structure du dépôt

```
Modelisation_Relationnelle/
├── data/
│   └── legacy_data.csv        # Export brut à analyser
├── docs/
│   ├── README.md               # Contexte métier MegaShop-B2B
│   └── rules.md                # Règles de gestion et cardinalités
├── scripts/
│   └── init_database.sql       # Script DDL PostgreSQL (idempotent)
└── Schema.md                   # MCD (diagramme Mermaid erDiagram)
```

## Modèle de données

Quatre entités :

| Entité | Rôle | Clé primaire |
|---|---|---|
| `client` | Client B2B passant des commandes | `id_client` (UUID) |
| `commande` | Commande passée par un client | `id_cmd` |
| `produit` | Article du catalogue, avec prix catalogue actuel | `code_prod` |
| `ligne_commande` | Association porteuse entre commande et produit (quantité, prix figé) | `(id_cmd, code_prod)` |

Le diagramme complet avec attributs et cardinalités est disponible dans `Schema.md`.

### Point clé de conception : deux prix, deux usages

- `produit.prix_unitaire_ht` : le prix catalogue **actuel**, qui peut évoluer dans le temps.
- `ligne_commande.prix_unitaire_ht` : le prix **figé** au moment où la commande a été passée, qui ne doit jamais changer rétroactivement.

Cette séparation évite qu'une évolution tarifaire ne réécrive l'historique des commandes passées.

## Exécuter le script

```bash
sudo -u postgres createdb megashop
sudo -u postgres psql -d megashop < scripts/init_database.sql
```

Le script est idempotent : il peut être relancé autant de fois que nécessaire sans erreur (`DROP TABLE IF EXISTS ... CASCADE` en tête de script).

## Critères de validation

| # | Test | Attendu |
|---|---|---|
| 1 | `psql -f init_database.sql` | Aucune erreur `FATAL`/`ERROR` |
| 2 | Relancer le script une 2e fois | Aucune erreur (idempotence) |
| 3 | `\d ligne_commande` | Aucune colonne de total ni de texte produit |
| 4 | Insertion d'un prix négatif dans `produit` | Rejet explicite via `CHECK` |

Tous les tests sont passants : détail dans l'historique de la conversation de conception du projet.

## Contraintes d'intégrité appliquées

- `NOT NULL` sur tous les attributs obligatoires (traduction directe des cardinalités `(1,1)`)
- `FOREIGN KEY` avec politiques de suppression réfléchies :
  - `commande → client` : `ON DELETE RESTRICT` (protège l'historique client)
  - `ligne_commande → commande` : `ON DELETE CASCADE` (une ligne n'a pas de sens sans sa commande)
  - `ligne_commande → produit` : `ON DELETE RESTRICT` (protège l'historique des ventes)
- `CHECK (qte > 0)` et `CHECK (prix_unitaire_ht > 0)` : empêchent des valeurs aberrantes au niveau du SGBD, pas de l'application

## Outils

- PostgreSQL 16
- Diagramme Mermaid (`erDiagram`), rendu natif GitHub
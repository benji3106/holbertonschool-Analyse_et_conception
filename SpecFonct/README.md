# Spécifications Fonctionnelles, User Stories & Gherkin — MegaShop-B2B

Formalisation du besoin métier d'un système anti-fraude pour la plateforme B2B
MegaShop-B2B, depuis un brief client brut jusqu'à un contrat comportemental
exécutable en Gherkin.

## Contexte

Le département de la Gouvernance Financière a transmis une demande de
fonctionnalité urgente face à la recrudescence des fraudes sur les paiements.
Le brief d'origine mêle besoin métier et solutions techniques présupposées
(requête SQL, code HTTP, composant d'interface).

L'objet de ce projet est de « nettoyer » cette demande : isoler les règles
d'affaires, les traduire en User Stories conformes aux critères INVEST, puis
les modéliser en scénarios BDD lisibles par un profil non technique.

## Arborescence

```text
Analyse_et_conception/SpecFonct/
├── docs/
│   └── brief_metier_gouvernance.md   # Brief brut du client (non modifié)
└── specs/
    └── anti_fraude.feature           # Contrat comportemental en Gherkin
```

## Règles métier retenues

Après élimination des éléments d'implémentation, trois règles subsistent :

1. Un paiement dont le montant dépasse 10 000 € à destination d'un pays
   figurant au registre des embargos est refusé.
2. Le client est notifié du motif de refus.
3. Un client au statut privilégié (VIP) est exempté du contrôle, quels que
   soient le montant et la destination.

### Dé-parasitage technique

| Formulation du client | Nature | Reformulation métier |
|---|---|---|
| `SELECT * FROM blacklist_pays` | Persistance | Le pays est évalué au regard du registre des embargos |
| Vérification de l'adresse IP | Moyen de détection | La localisation du client est déterminée |
| Erreur HTTP 403 | Protocole | Le paiement est refusé |
| Popup `div.alert-danger` | Interface | Le client est notifié du refus |

Critère appliqué : chaque formulation retenue reste valide si le système migre
vers une architecture événementielle ou une application mobile native. Les
règles métier survivent aux technologies.

## User Stories

**US-01 : Évaluer le risque de fraude d'un paiement**

> En tant que Responsable de la Gouvernance Financière
> Je veux que le système évalue le risque de chaque paiement selon son montant
> et la localisation du client
> Afin de bloquer les transactions frauduleuses

**US-02 : Exempter les clients privilégiés**

> En tant que Responsable de la Gouvernance Financière
> Je veux que les paiements des clients au statut privilégié soient acceptés
> sans évaluation de risque
> Afin de préserver la fluidité commerciale avec les comptes stratégiques

La dépendance de US-02 envers US-01 est assumée : une exemption suppose une
règle à contourner. Le découpage est maintenu pour permettre une priorisation
indépendante des deux besoins.

## Couverture de test

Le fichier `anti_fraude.feature` contient deux scénarios simples et un
`Scenario Outline` paramétré.

| Montant | Destination | Résultat | Branche couverte |
|---|---|---|---|
| 3000 | France | accepté | Cas nominal |
| 20000 | France | accepté | Montant élevé, pays autorisé |
| 8000 | Syldavie | accepté | Montant faible, pays sous embargo |
| 9999 | Syldavie | accepté | Borne inférieure |
| 10000 | Syldavie | accepté | **Valeur frontière** |
| 10001 | Syldavie | refusé | Borne supérieure |
| 25000 | Bordurie | refusé | Second pays sous embargo |

Les lignes `20000 / France` et `8000 / Syldavie` établissent que la règle est
une conjonction et non une disjonction : un montant élevé seul ne suffit pas à
déclencher un blocage.

Le triplet 9999 / 10000 / 10001 matérialise l'analyse des valeurs limites
(*Boundary Value Analysis*) et rend explicite l'interprétation du seuil.

## Hypothèses retenues

En l'absence de précision du demandeur :

- **H1** : « Dépasse 10 000 € » est interprété comme strictement supérieur.
  Un paiement de 10 000,00 € exactement n'est pas soumis au contrôle.
- **H2** : Le montant considéré est le total toutes taxes comprises du panier.
- **H3** : Le statut du client est évalué en premier et court-circuite les
  autres règles.

## Questions adressées au demandeur

- **Q1** : Un paiement de 10 000,00 € exactement est-il contrôlé ?
- **Q2** : Quelle donnée fait foi pour la localisation : adresse de
  facturation, adresse de livraison ou origine de la connexion ?
- **Q3** : Le contrôle ne se déclenchant qu'au-delà du seuil, un fraudeur peut
  fractionner ses paiements. Le besoin est-il de contrôler les montants élevés
  ou de détecter la fraude quel que soit le montant ?
- **Q4** : L'exemption totale accordée aux comptes privilégiés en fait la cible
  prioritaire d'une usurpation. Un plafond est-il envisageable ?
- **Q5** : Un paiement refusé est-il annulé ou placé en revue manuelle ?
- **Q6** : Les décisions doivent-elles être consignées à des fins d'audit ?

## Validation

**Syntaxique** : Le fichier `.feature` est validé par l'extension
[Cucumber (Gherkin) Full Support](https://marketplace.visualstudio.com/items?itemName=alexkrechik.cucumberautoformatter)
pour VS Code : coloration des mots-clés, alignement du tableau `Examples` et
détection des variables orphelines.

**Sémantique** : Le fichier ne contient aucun terme technique. Vérification :

```bash
grep -inE "sql|table|ip |403|api|popup|div|front|endpoint" specs/anti_fraude.feature
```

Aucun résultat attendu. Le vocabulaire employé (client, statut, commande,
montant, destination, paiement, gouvernance) relève exclusivement du domaine
métier, conformément au principe du BDD.

## Notes de conception

- Les mots-clés Gherkin sont en anglais sans directive `# language`, les
  phrases métier en français.
- Le bloc `When` ne contient qu'une action atomique unique, conformément au
  pattern *Arrange-Act-Assert* : un scénario ne doit avoir qu'un seul point de
  rupture possible.
- Les formulations d'étapes sont strictement identiques d'un scénario à
  l'autre, condition nécessaire à la factorisation des futures step
  definitions.
- Le statut client n'est pas paramétré dans le `Scenario Outline` : il s'agit
  d'une précondition fixe, l'exemption VIP relevant d'une règle distincte
  disposant de son propre scénario.
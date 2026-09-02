# API Design, Protocoles RESTful & Spécification OpenAPI 3.0

Conception d'un endpoint webhook public permettant à la banque partenaire de
MegaShop-B2B de notifier la plateforme du résultat d'une transaction de paiement,
spécifié en approche *contract-first* avec OpenAPI 3.0.3.

## Contexte

À la suite de la conception du système de paiement asynchrone, la banque partenaire
doit pouvoir rappeler notre système dès qu'une transaction est validée ou refusée.
Ce projet livre le contrat d'API de ce callback, avant toute implémentation c'est
la démarche *API-first*.

L'ancienne équipe proposait `POST /api/v1/updatePaymentStatus`, qui ne respecte pas
les conventions REST. Une partie du travail consiste à identifier et corriger cet
anti-pattern.

## Arborescence du projet

```text
API_first/
├── .spectral.yaml            # Ruleset Spectral (extends spectral:oas)
├── docs/
│   └── brief_api_paiement.md # Besoins bruts du Product Manager
└── api/
    └── openapi.yaml          # Spécification OpenAPI 3.0.3
```

## L'endpoint

```
POST /payments/webhook
```

### Pourquoi pas `/api/v1/updatePaymentStatus`

Le path d'origine contient un verbe d'action (`update`). En REST, l'URL identifie
une **ressource** (un nom) et c'est la méthode HTTP qui porte l'action. Garder
`update` dans le chemin duplique ce que `POST` exprime déjà et empêche l'URL de
représenter quoi que ce soit de réutilisable.

### Pourquoi `/payments/webhook` plutôt que `/orders/{orderId}/payments`

Les deux sont des designs REST valides. `/payments/webhook` a été retenu parce que
l'appelant est un système **externe**. Un endpoint webhook à plat découple la
banque de notre hiérarchie de ressources interne : elle n'a pas besoin de connaître
la façon dont MegaShop-B2B structure ses URLs de commandes et le contrat reste
stable même si le modèle de commande évolue en interne. L'identifiant de commande
transite dans le corps de la requête plutôt que dans le chemin.

## Contrat de requête

La banque envoie de l'`application/json` avec trois champs obligatoires :

| Champ           | Type   | Contrainte                    |
| --------------- | ------ | ----------------------------- |
| `orderId`       | string | `format: uuid`                |
| `status`        | string | `enum: [SUCCESS, FAILED]`     |
| `transactionId` | string | `pattern: ^TXN-[0-9]{8}$`     |

`additionalProperties: false` est positionné sur le schéma du payload : tout champ
hors de ce contrat provoque le rejet de la requête au lieu d'être transmis
silencieusement à la couche applicative.

La regex de `transactionId` est ancrée aux deux extrémités (`^` et `$`). Sans les
ancres, des valeurs comme `PREFIX-TXN-12345678` ou `TXN-12345678<payload>`
passeraient la validation.

## Réponses

| Code | Signification                                          |
| ---- | ------------------------------------------------------ |
| 204  | Notification acceptée. Aucun corps de réponse.          |
| 400  | Payload invalide. Retourne un objet `ErrorResponse`.    |

`204 No Content` est utilisé plutôt que `200 OK` car le brief précise qu'aucun
corps n'est renvoyé en cas de succès. Une réponse `204` ne doit jamais déclarer de
bloc `content` dans la spécification.

Seuls ces deux codes sont déclarés : chaque code listé dans un document OpenAPI est
une promesse faite au consommateur de l'API, lister des codes hypothétiques rendrait
donc le contrat trompeur.

## Composants réutilisables

Ni le corps de requête ni la réponse d'erreur ne sont déclarés inline sous `paths`.
Les deux pointent vers `components/schemas` via `$ref` :

- `WebhookPayload` : le corps de la notification bancaire
- `ErrorResponse` : un unique champ textuel `message`

Cela garde le nœud `paths` lisible, permet de réutiliser le même schéma pour de
futurs endpoints, et laisse les générateurs de code produire des types correctement
nommés plutôt que des classes anonymes de type `InlineObject`.

## Validation

### Linting avec Spectral

Depuis la racine `API_first/` :

```bash
npx @stoplight/spectral-cli lint api/openapi.yaml
```

Sortie attendue :

```
No results with a severity of 'error' found!
```

Le ruleset `.spectral.yaml` est versionné afin que le lint soit reproductible. Il
étend `spectral:oas`, le ruleset standard des bonnes pratiques OpenAPI.

Warnings résolus au cours du projet :

- `info-contact` : ajout d'un bloc `contact` sous `info`
- `operation-operationId` : ajout de `operationId: receivePaymentWebhook`
- `operation-tag-defined` : déclaration de `Payments` dans la liste `tags` racine

Ce dernier point mérite d'être noté : un tag utilisé sur une opération doit aussi
être déclaré globalement. La clé `tags` racine contient une liste d'**objets**
(`name` + `description`), tandis que la clé `tags` d'une opération contient une
simple liste de **chaînes** qui y font référence.

### Vérification visuelle

Ouvrir `api/openapi.yaml` dans [Swagger Editor](https://editor.swagger.io) ou
l'extension VS Code *Swagger Editor* :

- Aucun marqueur d'erreur rouge dans le panneau de rendu
- Dans la section **Schemas**, `orderId`, `status` et `transactionId` affichent
  chacun un astérisque rouge, confirmant que le tableau `required` est bien pris en
  compte
- La ligne `204` n'affiche ni media type ni exemple, contrairement à la ligne `400`

### Payloads qui doivent être rejetés

| Payload                                              | Raison                        |
| ---------------------------------------------------- | ----------------------------- |
| `orderId: "abc"`                                     | UUID invalide                 |
| `status: "PENDING"`                                  | hors de l'enum                |
| `transactionId: "TXN-1234567"`                       | 7 chiffres au lieu de 8       |
| `orderId` absent                                     | champ obligatoire manquant    |
| tout champ supplémentaire                            | `additionalProperties: false` |

## Points clés retenus

- Une URL nomme une ressource ; c'est la méthode HTTP qui fournit l'action.
- Pour les webhooks consommés par des tiers, un endpoint à plat est souvent
  préférable à un endpoint imbriqué : il évite d'exposer la structure interne des
  ressources à un appelant externe.
- `required` est un tableau frère de `properties`, pas un attribut par champ. En
  JSON Schema, toute propriété est optionnelle par défaut.
- `additionalProperties: false` transforme un schéma permissif en contrat fermé.
- Les ancres de regex sont ce qui fait d'un `pattern` une véritable validation
  plutôt qu'une recherche de sous-chaîne.
- Un UUID n'est pas entièrement aléatoire : le troisième groupe commence par le
  chiffre de version et le quatrième par le caractère de variant (`8`, `9`, `a` ou
  `b`). Les exemples qui ignorent cette règle échouent à une validation stricte de
  `format: uuid`.

## Outillage

- OpenAPI 3.0.3
- Spectral CLI (`@stoplight/spectral-cli`)
- Swagger Editor
- WSL2 / Ubuntu, VS Code
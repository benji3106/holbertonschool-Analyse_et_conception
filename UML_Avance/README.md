# UML Avancé : Diagrammes de Comportement & Patterns Architecturaux

## Contexte

MegaShop-B2B (grossiste fictif) souhaite intégrer un module de paiement par carte bancaire. Les appels vers l'API bancaire partenaire pouvant prendre jusqu'à 15 secondes, l'architecture doit être **asynchrone** afin de ne jamais bloquer le client ni saturer les serveurs.

Ce projet modélise en UML "as-code" (Mermaid.js), la structure statique et le comportement dynamique de ce flux de paiement, avant toute implémentation.

## Objectifs

- Maîtriser la syntaxe Mermaid.js pour produire de l'UML directement versionnable en Markdown.
- Différencier l'Agrégation de la Composition en conception orientée objet.
- Appliquer le principe d'Inversion des Dépendances (SOLID) via le Pattern Repository.
- Modéliser une chorégraphie asynchrone impliquant une API, un Message Broker (RabbitMQ) et un Worker.
- Concevoir une Machine à États Finis (FSM) sécurisant le cycle de vie d'une commande.

## Structure du dépôt

```
UML_Avance/
├── specs/
│   └── cahier_des_charges_paiement.md
├── architecture/
│   ├── 01_class_diagram.md
│   ├── 02_sequence_diagram.md
│   └── 03_state_machine.md
└── README.md
```

## Contenu des diagrammes

### 1. `architecture/01_class_diagram.md` : Diagramme de classes

Modélise l'isolation du domaine métier (`OrderService`) vis-à-vis de l'infrastructure de persistance via le Pattern Repository :

- `IOrderRepository` : interface définissant le contrat métier (`save`, `findById`).
- `PostgresOrderRepository` : implémentation concrète, seule classe à connaître PostgreSQL.
- `OrderService` : dépend uniquement de l'interface (agrégation), jamais de l'implémentation concrète — garantissant testabilité et indépendance technologique.

### 2. `architecture/02_sequence_diagram.md` : Diagramme de séquence

Modélise le flux temporel du paiement du clic client jusqu'à la mise à jour finale de la commande :

- Appel client → API → mise à jour DB (`PENDING_PAYMENT`) → publication d'un événement asynchrone sur RabbitMQ → réponse immédiate `202 Accepted` au client.
- En parallèle, découplé du client : le `PaymentWorker` consomme l'événement, appelle la banque (synchrone), puis met à jour la commande selon le résultat (`PAID` ou `FAILED`).
- Le retour HTTP au client est positionné **avant** tout appel au Worker et à la Banque, garantissant le non-blocage.

### 3. `architecture/03_state_machine.md` : Machine à états

Modélise le cycle de vie déterministe d'une commande :

```
[*] → DRAFT → PENDING_PAYMENT → PAID → SHIPPED → [*]
                    ↑    ↓
                  FAILED
```

Aucune transition directe n'existe entre `DRAFT`/`PENDING_PAYMENT` et `SHIPPED` : une commande ne peut être expédiée sans être passée par l'état `PAID`. Une boucle de résilience (`retry_payment`) permet de retenter un paiement après un échec.

## Critères de validation

| # | Critère | Statut |
|---|---|---|
| 1 | Rendu Mermaid sans erreur de syntaxe (VS Code + GitHub) | ✅ |
| 2 | Aucune dépendance directe ou indirecte de `OrderService` vers `PostgresOrderRepository` | ✅ |
| 3 | Aucune action du `Worker` ou de la `Bank` avant le retour HTTP 202 au client | ✅ |

## Outils

- **Langage de modélisation** : Mermaid.js (UML as-code, rendu natif GitHub)
- **Éditeur** : VS Code (extension Markdown Preview Mermaid Support)
- **Environnement** : WSL2 (Windows)
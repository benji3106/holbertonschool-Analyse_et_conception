# Audit du Legacy : Règles de Gestion
## Projet MegaShop-B2B : Modélisation Relationnelle

---

## 1. Sujets identifiés (futures entités)

À partir de l'analyse du fichier `legacy_data.csv`, quatre sujets métier ont été identifiés :

| Sujet | Description |
|---|---|
| **Client** | L'entreprise cliente qui passe des commandes |
| **Commande** | Une commande passée par un client, à une date donnée, avec un statut |
| **LigneCommande** | Une ligne au sein d'une commande, reliant une commande à un produit avec une quantité et un prix appliqué |
| **Produit** | Un article du catalogue MegaShop-B2B |

> **Piège évité** : `total_ligne` n'est **pas** un sujet. C'est une donnée calculée (`prix_unitaire_ht × qte`), qui ne doit pas être stockée ni traitée comme un attribut structurant.

---

## 2. Règles de gestion

### RG1 : Client / Commande
**Un client peut passer plusieurs commandes. Une commande est passée par un seul client.**

| Entité | Vers | Cardinalité |
|---|---|---|
| Client | → Commande | (0,n) |
| Commande | → Client | (1,1) |

*Justification : un client peut exister en base sans avoir encore commandé (min = 0). Une commande en revanche, n'a de sens que rattachée à un client précis et un seul (1,1).*

---

### RG2 : Commande / LigneCommande
**Une commande est composée de plusieurs lignes de commande. Chaque ligne de commande appartient à une seule commande.**

| Entité | Vers | Cardinalité |
|---|---|---|
| Commande | → LigneCommande | (1,n) |
| LigneCommande | → Commande | (1,1) |

*Justification : une commande sans aucune ligne n'a pas de sens métier (min = 1). Une ligne de commande ne peut exister indépendamment d'une commande et n'appartient jamais qu'à une seule.*

---

### RG3 : LigneCommande / Produit
**Une ligne de commande concerne un seul produit. Un produit peut apparaître sur plusieurs lignes de commande ou sur aucune.**

| Entité | Vers | Cardinalité |
|---|---|---|
| LigneCommande | → Produit | (1,1) |
| Produit | → LigneCommande | (0,n) |

*Justification : une ligne de commande désigne toujours exactement un produit. À l'inverse un produit peut exister au catalogue sans avoir jamais été commandé (min = 0), et peut apparaître sur de multiples lignes au fil du temps.*

---

## 3. Schéma de synthèse

```
Client (0,n) ──── passe ──── (1,1) Commande
                                    │
                                (1,n)
                                    │
                            LigneCommande
                                    │
                                (1,1)
                                    │
Produit (0,n) ──── concerne ──── (1,1) LigneCommande
```

---

## 4. Anomalies du legacy justifiant cette modélisation

| Anomalie observée dans le CSV | Cause | Résolue par |
|---|---|---|
| Adresse et contact d'Acme Corp répétés sur CMD-901 (x2) et CMD-903 | Pas d'entité Client séparée | Entité **Client** unique, référencée par clé étrangère |
| Désignation et prix de "Bureau Chêne" (P-01) répétés sur CMD-901 et CMD-902 | Pas d'entité Produit séparée | Entité **Produit** unique, référencée par clé étrangère |
| Perte de "Chaise Ergonomique" si CMD-901 est supprimée | Le produit n'existe qu'à travers la commande | Le **Produit** existe indépendamment de la **LigneCommande** |
| `total_ligne` stocké en dur (redondant avec `prix_unitaire_ht × qte`) | Donnée dérivée traitée comme donnée brute | Non stockée : recalculée à la demande |

---

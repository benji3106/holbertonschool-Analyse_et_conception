# Brouillon : US anti-fraude

## À jeter (technique)
SQL / adresse IP / erreur 403 / popup rouge

## Règles métier
1. Montant > 10 000 € + pays sous embargo → paiement refusé
2. Client notifié du refus
3. Client VIP → toujours accepté

---

## US-01 — Évaluer le risque de fraude d'un paiement

En tant que Responsable de la Gouvernance Financière
Je veux que le système évalue le risque de chaque paiement selon son montant
et la localisation du client
Afin de bloquer les transactions frauduleuses

CA :
- CA-01 : montant > 10 000 € + pays sous embargo → refusé
- CA-02 : paiement refusé → client notifié du motif
- CA-03 : montant > 10 000 € + pays autorisé → accepté
- CA-04 : montant ≤ 10 000 € → accepté quelle que soit la localisation

INVEST : OK sur les 6 critères. Livrable seule valeur métier directe,
chaque CA se traduit en un scénario testable.

---

## US-02 — Exempter les clients privilégiés

En tant que Responsable de la Gouvernance Financière
Je veux que les paiements des clients au statut privilégié soient acceptés
sans évaluation de risque
Afin de préserver la fluidité commerciale avec les comptes stratégiques

CA :
- CA-05 : client privilégié → accepté quels que soient montant et localisation

INVEST : dépendance à US-01 assumée (une exemption suppose une règle
à contourner). Découpée à part pour permettre la priorisation.

---

## Hypothèses retenues
- H1 : « dépasse » = strictement supérieur → 10 000,00 € pile n'est pas contrôlé
- H2 : montant TTC du panier
- H3 : le statut VIP est évalué en premier et court-circuite les autres règles

---

## Questions au client

Q1 : Seuil : un paiement de 10 000,00 € exactement est-il contrôlé ou non ?

Q2 : Localisation : quelle donnée fait foi ? Adresse de facturation, adresse
de livraison ou origine de la connexion ? Ces trois valeurs peuvent diverger
pour un même client, et le brief mentionne l'adresse IP sans préciser
si c'est le critère de référence.

Q3 : Fractionnement : le contrôle ne se déclenchant qu'au-delà de 10 000 €,
un fraudeur peut émettre plusieurs paiements de 9 999 €. Le besoin est-il
de contrôler les montants élevés ou de détecter la fraude quel que soit
le montant ?

Q4 : Statut VIP : l'exemption totale fait des comptes privilégiés la cible
prioritaire d'une usurpation. Un plafond est-il envisageable ?

Q5 : Après refus : le paiement est-il définitivement annulé ou placé en file
de revue manuelle ? Le panier est-il conservé ?

Q6 : Traçabilité : les décisions d'acceptation et de refus doivent-elles être
consignées pour audit ? Le brief n'en parle pas, mais le rôle demandeur
le suggère.
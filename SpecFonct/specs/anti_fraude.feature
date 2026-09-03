Feature: Gouvernance et blocage des paiements frauduleux
  En tant que Responsable de la Gouvernance Financière
  Je veux que le système évalue le niveau de risque de chaque paiement
  Afin de bloquer les transactions potentiellement frauduleuses protégeant ainsi l'entreprise

Scenario: Validation d'un paiement standard sans risque:
  Given un client au statut standar
  And une commande d'un montant de 5000 euros à destination de la "France"
  When le client soumet son paiement
  Then le paiement est accepté par la gouvernance

Scenario: Exemption de contrôle pour les clients VIP
  Given un client au statut VIP
  And une commande d'un montant de 15000 euros à destination de la "Syldavie"
  When le client soumet son paiement
  Then le paiement est accepté par la gouvernance
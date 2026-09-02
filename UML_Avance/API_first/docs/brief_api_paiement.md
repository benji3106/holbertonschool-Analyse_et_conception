# Brief : Webhook de notification de paiement

La banque va appeler notre système dès qu'une transaction est validée ou refusée.

**Besoins :**
- L'URL doit permettre de recevoir une notification de paiement. (L'ancienne équipe proposait `/api/v1/updatePaymentStatus`, ce qui ne respecte pas REST. À vous de corriger).
- Les données envoyées par la banque seront en JSON.
- Il nous faut l'identifiant de la commande (doit être un format UUID exact).
- Il nous faut le statut du paiement. Seules deux valeurs sont autorisées par la banque : "SUCCESS" ou "FAILED".
- Il nous faut l'identifiant de transaction bancaire (une chaîne qui commence obligatoirement par "TXN-" suivi de 8 chiffres).
- Si tout est correct, on ne renvoie pas de corps, juste un succès. Si les données sont invalides, on renvoie une erreur avec un message textuel.
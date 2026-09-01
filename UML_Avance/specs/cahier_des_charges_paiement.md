# Spécifications du Flux de Paiement Asynchrone

**Contexte :** Le paiement d'une commande (MegaShop-B2B).

**Règles de comportement :**
1. L'utilisateur clique sur "Payer" depuis l'application Web.
2. L'API (OrderService) reçoit la demande. Elle modifie immédiatement le statut de la commande en `PENDING_PAYMENT` dans la base de données.
3. L'API pousse un message `ProcessPaymentEvent` dans une file d'attente (Message Queue : RabbitMQ) et ne bloque pas.
4. L'API retourne un code HTTP 202 (Accepted) à l'utilisateur.
5. En arrière-plan, un `PaymentWorker` consomme le message de la file d'attente.
6. Le Worker appelle l'API externe de la Banque (Appel synchrone lent).
7. **Alternative (Succès) :** La banque valide. Le Worker met la base à jour à `PAID`.
8. **Alternative (Échec) :** La banque refuse (fonds insuffisants). Le Worker met la base à jour à `FAILED`.
9. Une commande en état `FAILED` ne peut repasser qu'à `PENDING_PAYMENT` (nouvelle tentative). Une commande `PAID` passe à `SHIPPED`.
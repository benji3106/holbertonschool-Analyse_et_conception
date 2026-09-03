# Brief : Système Anti-Fraude (Brouillon du client)

Salut l'équipe technique,

Nous avons un gros problème de fraude. Je veux qu'on ajoute un contrôle au moment du paiement. 
Si le montant du panier dépasse 10 000 euros, le système doit faire une requête SQL (SELECT * FROM blacklist_pays) pour vérifier l'adresse IP du client.
Si le pays est sur la liste noire (ex: "Syldavie", "Bordurie"), l'API doit renvoyer une erreur 403 et l'écran du front-end doit afficher une popup rouge (div class="alert-danger") avec écrit "Transaction bloquée pour suspicion de fraude".
Aussi, si le client est un "Client VIP", on s'en fiche du pays et du montant, on valide toujours.

Merci de coder ça vite.
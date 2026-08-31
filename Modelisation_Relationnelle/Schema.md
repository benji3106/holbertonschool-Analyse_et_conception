​```mermaid
    erDiagram
    CLIENT||--o{ COMMANDE : places
    COMMANDE ||--|{ LIGNECOMMANDE : contains
    PRODUIT ||--o{ LIGNECOMMANDE : includes
    CLIENT {
        int id_client PK
        string client_nom
        string client_contact
    }
    COMMANDE {
        string id_cmd PK
        date date_achat
        string adr_livraison
        string statut_cmd
    }
    PRODUIT {
        string code_prod PK
        string designation
    }
    LIGNECOMMANDE {
        string id_cmd PK,FK
        string code_prod PK,FK
        float prix_unitaire_ht
        int qte
    }
​```
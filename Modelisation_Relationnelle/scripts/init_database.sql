-- Script d'initialisation de la base MegaShop-B2B
-- Auteur : Benjamin

BEGIN;

-- ============================================
-- 1. Nettoyage
-- ============================================
DROP TABLE IF EXISTS ligne_commande CASCADE;
DROP TABLE IF EXISTS commande CASCADE;
DROP TABLE IF EXISTS produit CASCADE;
DROP TABLE IF EXISTS client CASCADE;

-- ============================================
-- 2. Tables sans dépendance
-- ============================================

CREATE TABLE client (
    id_client       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_nom      VARCHAR(100) NOT NULL,
    client_contact  VARCHAR(150) NOT NULL
);

CREATE TABLE produit (
    code_prod       VARCHAR(20) PRIMARY KEY,
    designation     VARCHAR(150) NOT NULL
);

-- ============================================
-- 3. Tables dépendantes
-- ============================================

CREATE TABLE commande (
    id_cmd          VARCHAR(20) PRIMARY KEY,
    id_client       UUID NOT NULL,
    date_achat      DATE NOT NULL,
    adr_livraison   VARCHAR(255) NOT NULL,
    statut_cmd      VARCHAR(20) NOT NULL,
    CONSTRAINT fk_commande_client
        FOREIGN KEY (id_client)
        REFERENCES client(id_client)
        ON DELETE RESTRICT
);

CREATE TABLE ligne_commande (
    id_cmd              VARCHAR(20) NOT NULL,
    code_prod            VARCHAR(20) NOT NULL,
    prix_unitaire_ht     DECIMAL(10,2) NOT NULL,
    qte                  INT NOT NULL,
    PRIMARY KEY (id_cmd, code_prod),
    CONSTRAINT fk_ligne_commande
        FOREIGN KEY (id_cmd)
        REFERENCES commande(id_cmd)
        ON DELETE CASCADE,
    CONSTRAINT fk_ligne_produit
        FOREIGN KEY (code_prod)
        REFERENCES produit(code_prod)
        ON DELETE RESTRICT,
    CONSTRAINT chk_qte_positive
        CHECK (qte > 0)
);

COMMIT;
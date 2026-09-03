-- =====================================================================
-- StockMaster-Pro | 01_database_schema.sql
-- SGBD cible : PostgreSQL 14+
-- Principe directeur : le stock n'est jamais stocke, il est calcule.
--                      La table mouvement_stock est un journal append-only.
-- =====================================================================

-- Nettoyage idempotent (ordre inverse de la creation)
DROP VIEW  IF EXISTS stock_courant;
DROP TABLE IF EXISTS mouvement_stock;
DROP TABLE IF EXISTS emplacement;
DROP TABLE IF EXISTS produit;

-- ---------------------------------------------------------------------
-- Referentiel produit
-- ---------------------------------------------------------------------
CREATE TABLE produit (
    id_produit        INTEGER      GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    reference_produit VARCHAR(50)  NOT NULL UNIQUE,
    libelle_produit   VARCHAR(255) NOT NULL
);

-- ---------------------------------------------------------------------
-- Emplacements physiques de l'entrepot
-- ---------------------------------------------------------------------
CREATE TABLE emplacement (
    id_emplacement   INTEGER     GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code_emplacement VARCHAR(50) NOT NULL UNIQUE,
    id_produit       INTEGER     NOT NULL,

    -- Regle metier : "Chaque Emplacement contient un et un seul type de Produit"
    -- La cardinalite (1,1) se traduit par une FK NOT NULL portee par l'emplacement.
    CONSTRAINT fk_emplacement_produit
        FOREIGN KEY (id_produit) REFERENCES produit (id_produit)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

-- ---------------------------------------------------------------------
-- Journal des mouvements (append-only)
-- ---------------------------------------------------------------------
CREATE TABLE mouvement_stock (
    id_mouvement   INTEGER     GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_emplacement INTEGER     NOT NULL,
    type_mouvement VARCHAR(20) NOT NULL,
    quantite       INTEGER     NOT NULL,
    date_mouvement TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Immutabilite : un mouvement errone se corrige par un mouvement inverse,
    -- jamais par un UPDATE ou un DELETE sur la ligne existante.
    -- ON DELETE RESTRICT interdit la destruction d'un historique de mouvements.
    CONSTRAINT fk_mouvement_emplacement
        FOREIGN KEY (id_emplacement) REFERENCES emplacement (id_emplacement)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    -- Le sens est porte par le type, jamais par le signe de la quantite.
    CONSTRAINT chk_type_mouvement
        CHECK (type_mouvement IN ('ENTREE', 'SORTIE')),

    CONSTRAINT chk_quantite_positive
        CHECK (quantite > 0)
);

-- Chaque calcul de stock filtre sur l'emplacement : index indispensable
-- sur un journal destine a croitre indefiniment.
CREATE INDEX idx_mouvement_emplacement ON mouvement_stock (id_emplacement);

-- ---------------------------------------------------------------------
-- Etat courant du stock : agregation du journal, jamais stocke en dur.
-- Anti-pattern evite : aucune colonne "quantite_totale" modifiable par UPDATE.
-- ---------------------------------------------------------------------
CREATE VIEW stock_courant AS
SELECT
    e.id_emplacement,
    e.code_emplacement,
    p.reference_produit,
    p.libelle_produit,
    -- LEFT JOIN + COALESCE : un emplacement sans mouvement affiche 0, pas NULL.
    COALESCE(
        SUM(m.quantite) FILTER (WHERE m.type_mouvement = 'ENTREE'), 0
    ) - COALESCE(
        SUM(m.quantite) FILTER (WHERE m.type_mouvement = 'SORTIE'), 0
    ) AS quantite_disponible
FROM emplacement e
JOIN produit p
    ON p.id_produit = e.id_produit
LEFT JOIN mouvement_stock m
    ON m.id_emplacement = e.id_emplacement
GROUP BY
    e.id_emplacement,
    e.code_emplacement,
    p.reference_produit,
    p.libelle_produit;
Feature: Traçabilité et sécurisation des mouvements d'inventaire

  En tant que gestionnaire d'entrepôt
  Je veux que chaque mouvement de stock soit tracé et contrôlé
  Afin que le stock affiché corresponde toujours au stock physique
  et qu'aucun emplacement ne puisse afficher une quantité négative.

  Background:
    Given l'emplacement "ALLEE-A-RAYON-2" contient le produit "Ramette papier A4 80g"
    And le stock disponible de cet emplacement est de 42 unités

  Scenario: Une entrée de marchandise augmente le stock disponible
    When le manutentionnaire déclare une ENTREE de 30 unités sur cet emplacement
    Then le mouvement est accepté
    And le stock disponible de cet emplacement est de 72 unités
    And l'historique de l'emplacement conserve la trace de ce mouvement

  Scenario Outline: Contrôle des sorties selon le stock disponible
    When le manutentionnaire déclare une SORTIE de <quantite> unités sur cet emplacement
    Then l'opération est <resultat>
    And le stock disponible de cet emplacement est de <stock_final> unités

    Examples:
      | quantite | resultat | stock_final |
      | 10       | acceptée | 32          |
      | 41       | acceptée | 1           |
      | 42       | acceptée | 0           |
      | 43       | refusée  | 42          |
      | 100      | refusée  | 42          |

  Scenario: Une sortie refusée ne laisse aucune trace dans l'historique
    When le manutentionnaire déclare une SORTIE de 100 unités sur cet emplacement
    Then l'opération est refusée
    And le manutentionnaire est informé que le stock est insuffisant
    And aucun mouvement n'est ajouté à l'historique de l'emplacement
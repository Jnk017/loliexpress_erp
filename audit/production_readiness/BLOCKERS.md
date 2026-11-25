# Blocages externes

| Chantiers | Condition manquante | Action minimale |
|---|---|---|
| DB-001, DB-003 | Le PAT disponible obtient HTTP 403 sur Production | Accorder un accès de lecture au catalogue ou fournir un export contrôlé des métadonnées sans valeurs secrètes. |
| DB-002, DB-003, OPS-001 | Projet vierge et cible de restauration isolée autorisés | Confirmer référence et autorisation. Utiliser une copie sécurisée pour la répétition Production. |
| AUTH-001, EDGE-002 | Boîte contrôlée et fournisseur e-mail de test opérationnels | Configurer le transport via le tableau de bord et fournir une adresse de test réellement accessible. |
| MOB-002–003 | APK Android récent traçable, téléphone pour la recette et signature pour la diffusion | Fournir artefact Appcircle et captures par SHA. Configurer la signature dans le service de build si nécessaire. |
| REL-001 | Autorisation de promotion et déploiement | Décision humaine seulement après gate complet. |

Aucune dépense, intervention destructive ni écriture en production n’est autorisée par ces constats.

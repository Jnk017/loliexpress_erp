# Revue UI mobile Flutter

Périmètre : présentation sur la branche du gate. Les services métier, requêtes Supabase, migrations, clés de données et règles de calcul sont hors du diff.

## Passe 1 — thème et typographie

| Fichier | Changement |
|---|---|
| `lib/theme/app_theme.dart` | Palette sombre lisible, couleurs de premier plan associées et chiffres tabulaires dans les styles partagés. |
| `lib/widgets/custom_app_bar.dart` | Synchronisation et retour en français. |
| `lib/presentation/main_dashboard/widgets/sync_status_widget.dart` | Libellé de synchronisation et durées en français. |
| `lib/presentation/main_dashboard/main_dashboard.dart` | État de synchronisation affiché une seule fois et marge de fin de liste. |
| `lib/presentation/settings_configuration/settings_configuration.dart` | Icône neutre pour les devises, libellés et marge de fin de liste. |

## Passe 2 — navigation

| Fichier | Changement |
|---|---|
| `lib/widgets/custom_bottom_bar.dart` | Sélection par route, onglet d’accueil en français et hauteur minimum compatible avec l’agrandissement du texte. |
| `lib/widgets/custom_app_bar.dart` | Bouton retour désactivé sur les écrans racines identifiés. |
| `lib/presentation/main_dashboard/main_dashboard.dart` | Barre de navigation par rôle à la place du pilotage des onglets internes par index. |
| `lib/presentation/financial_dashboard/financial_dashboard.dart` | Navigation par rôle, titre « Tableau financier » et espace au-dessus des actions flottantes. |
| `lib/presentation/admin_dashboard/admin_dashboard.dart` | Titre « Rapports administrateur », barre commune et grille adaptée aux petits écrans. |
| `lib/presentation/customer_management/customer_management.dart` | Suppression de la correspondance locale entre index et destinations. |
| `lib/presentation/product_catalog/product_catalog.dart` | Navigation commune, avec rattachement visuel à Stock. |
| `lib/presentation/inventory_management/inventory_management.dart` | Retour implicite retiré sur la racine stock et couleur du bouton d’actions alignée. |
| `lib/presentation/purchases/purchases_screen.dart` | Barre racine et couleur des onglets inactifs harmonisées. |
| `lib/presentation/reports_analytics/reports_analytics.dart` | Titre français et retour implicite retiré sur la racine rapports. |
| `lib/presentation/expenses/expenses_screen.dart` | Barre commune, titre et bouton de création homogènes. |

## Passe 3 — KPI et états

| Fichier | Changement |
|---|---|
| `lib/widgets/screen_state_view.dart` | Présentation partagée pour une liste vide ou une erreur, avec action facultative. |
| `lib/widgets/custom_error_widget.dart` | Écran générique en français, adapté au thème, avec la navigation de secours existante. |
| `lib/presentation/main_dashboard/widgets/kpi_card_widget.dart` | Indicateur descriptif neutre pour les compteurs. |
| `lib/presentation/financial_dashboard/widgets/{expense,receivables,revenue}_card_widget.dart` | Variations nulles neutres, flèches réservées aux variations et styles à contraste renforcé. |
| `lib/presentation/{main_dashboard/main_dashboard,admin_dashboard/admin_dashboard,purchases/purchases_screen,sales_order_processing/sales_order_processing}.dart` | Erreurs de chargement formulées côté interface, avec rappel du handler existant. État vide harmonisé pour les achats et ventes du rapport admin. |
| `lib/presentation/inventory_management/widgets/{stock_overview_widget,movements_view_widget}.dart` | États vides et relance sur les lectures de stock et des mouvements, listes dégagées du bouton d’actions. |
| `lib/presentation/expenses/expenses_screen.dart` | Messages d’échec utilisateur et marge de liste pour les actions flottantes. |

## Passe 4 — création et paramètres

| Fichier | Changement |
|---|---|
| `lib/presentation/sales_order_processing/sales_order_processing.dart` | Retrait du raccourci Historique sans action, marge compacte au-dessus du récapitulatif fixe, même parcours de création. |
| `lib/presentation/sales_order_processing/widgets/customer_info_section.dart` | Affichage des coordonnées absentes, contrôle visuel du téléphone fictif et avatar sans erreur si le nom est vide. |
| `lib/presentation/sales_order_processing/widgets/product_selection_section.dart` | Recherche et résultats rapprochés, liste plafonnée en hauteur sans remplissage inutile. |
| `lib/presentation/purchases/purchases_screen.dart` | Espacement du dialogue, libellé d’ajout explicite, total dans le thème et marge de liste sous le bouton flottant. |
| `lib/presentation/settings_configuration/widgets/user_profile_header_widget.dart` | Adresse e-mail sur une ligne avec ellipsis. |
| `lib/presentation/settings_configuration/settings_configuration.dart` | Dialogues en français. Le bouton de réinitialisation simulée avait été retiré avant cette revue. |

## Libellés et erreurs transverses

Les fichiers suivants ont reçu des libellés génériques en français ou des erreurs affichées sans détail technique.

- `lib/presentation/security_dashboard/security_dashboard.dart`
- `lib/presentation/user_role_management/user_role_management.dart`
- `lib/presentation/security_alert_center/security_alert_center.dart`
- `lib/presentation/audit_log/audit_log.dart`
- `lib/presentation/incident_management_center/incident_management_center.dart`
- `lib/presentation/barcode_scanner/barcode_scanner.dart`
- `lib/presentation/automation_rules_manager/widgets/rules_list_widget.dart`
- `lib/presentation/automation_rules_manager/widgets/blocked_users_widget.dart`
- `lib/presentation/automation_rules_manager/widgets/rule_builder_dialog_widget.dart`
- `lib/presentation/security_dashboard/widgets/anomaly_card_widget.dart`
- `lib/presentation/incident_investigation_workspace/widgets/upload_evidence_dialog_widget.dart`
- `lib/presentation/incident_investigation_workspace/widgets/add_task_dialog_widget.dart`
- `lib/presentation/incident_investigation_workspace/widgets/team_communications_widget.dart`
- `lib/presentation/user_role_management/widgets/user_list_widget.dart`
- `lib/presentation/user_role_management/widgets/user_card_widget.dart`
- `lib/presentation/user_role_management/widgets/edit_user_dialog.dart`
- `lib/presentation/user_role_management/widgets/role_management_widget.dart`
- `lib/presentation/user_role_management/widgets/create_user_dialog.dart`
- `lib/presentation/security_alert_center/widgets/alert_configuration_dialog_widget.dart`
- `lib/presentation/audit_log/widgets/ip_geolocation_map_widget.dart`
- `lib/presentation/audit_log/widgets/forensic_export_dialog_widget.dart`
- `lib/presentation/audit_log/widgets/device_fingerprinting_widget.dart`
- `lib/presentation/audit_log/widgets/anomaly_correlation_widget.dart`
- `lib/presentation/audit_log/widgets/forensic_timeline_widget.dart`
- `lib/presentation/audit_log/widgets/filter_panel_widget.dart`
- `lib/presentation/product_catalog/widgets/add_product_dialog_widget.dart`
- `lib/presentation/incident_management_center/widgets/assign_investigator_dialog_widget.dart`
- `lib/presentation/incident_management_center/widgets/create_incident_dialog_widget.dart`
- `lib/presentation/incident_management_center/widgets/incident_details_dialog_widget.dart`

- `lib/presentation/customer_portal/widgets/documents_tab_widget.dart` (écran de chargement)
- `lib/presentation/delivery_tracking/delivery_tracking.dart` (écran de chargement)
- `lib/presentation/security_dashboard/security_dashboard.dart` (écran de chargement)
- `lib/presentation/security_alert_center/security_alert_center.dart` (écran de chargement)

## Vérification

Le CLI `dart analyze` a été essayé à la fin des quatre passes. Le chemin d’analytique par défaut est inaccessible en écriture sur cet hôte. La vérification consolidée utilise donc le moteur d’analyse Flutter avec un répertoire d’état dans le workspace. Le rendu du nouvel APK sur appareil reste à vérifier.

- `flutter analyze --no-pub --no-fatal-infos` avec `ANALYZER_STATE_LOCATION_OVERRIDE` dans le workspace : zéro erreur, zéro avertissement, quatre lints informatifs préexistants.
- `flutter test --no-pub` : 18 tests passés, dont les deux cas de contraste des paramètres.
- Les zones reprises sont francisées. La traduction intégrale des modules secondaires et la vérification visuelle sur le nouvel APK restent ouvertes.

import 'package:flutter/material.dart';

import '../presentation/audit_log/audit_log.dart';
import '../presentation/automation_rules_manager/automation_rules_manager.dart';
import '../presentation/barcode_scanner/barcode_scanner.dart';
import '../presentation/customer_management/customer_management.dart';
import '../presentation/customer_portal/customer_portal.dart';
import '../presentation/delivery_tracking/delivery_tracking.dart';
import '../presentation/documents_screen/documents_screen.dart';
import '../presentation/financial_dashboard/financial_dashboard.dart';
import '../presentation/incident_investigation_workspace/incident_investigation_workspace.dart';
import '../presentation/incident_management_center/incident_management_center.dart';
import '../presentation/inventory_management/inventory_management.dart';
import '../presentation/invoice_generation/invoice_generation.dart';
import '../presentation/login_screen/login_screen.dart';
import '../presentation/main_dashboard/main_dashboard.dart';
import '../presentation/notifications_center/notifications_center.dart';
import '../presentation/product_catalog/product_catalog.dart';
import '../presentation/reports_analytics/reports_analytics.dart';
import '../presentation/sales_order_processing/sales_order_processing.dart';
import '../presentation/security_alert_center/security_alert_center.dart';
import '../presentation/security_dashboard/security_dashboard.dart';
import '../presentation/settings_configuration/settings_configuration.dart';
import '../presentation/splash_screen/splash_screen.dart';
import '../presentation/purchases/purchases_screen.dart';
import '../presentation/expenses/expenses_screen.dart';
import '../presentation/user_role_management/user_role_management.dart';

class AppRoutes {
  // TODO: Add your routes here
  static const String initial = '/';
  static const String mainDashboard = '/main-dashboard';
  static const String financialDashboard = '/financial-dashboard';
  static const String splash = '/splash-screen';
  static const String invoiceGeneration = '/invoice-generation';
  static const String deliveryTracking = '/delivery-tracking';
  static const String customerManagement = '/customer-management';
  static const String barcodeScanner = '/barcode-scanner';
  static const String login = '/login-screen';
  static const String salesOrderProcessing = '/sales-order-processing';
  static const String inventoryManagement = '/inventory-management';
  static const String productCatalog = '/product-catalog';
  static const String customerPortal = '/customer-portal';
  static const String documentsScreen = '/documents-screen';
  static const String notificationsScreen = '/notifications-screen';
  static const String notificationsCenter = '/notifications-center';
  static const String reportsAnalytics = '/reports-analytics';
  static const String settingsConfiguration = '/settings-configuration';
  static const String userRoleManagement = '/user-role-management';
  static const String auditLog = '/audit-log';
  static const String securityDashboard = '/security-dashboard';
  static const String securityAlertCenter = '/security-alert-center';
  static const String automationRulesManager = '/automation-rules-manager';
  static const String incidentManagementCenter = '/incident-management-center';
  static const String incidentInvestigationWorkspace =
      '/incident-investigation-workspace';
  static const String purchases = '/purchases';
  static const String expenses = '/expenses';
  static const String productDetail = '/product-detail';

  static Map<String, WidgetBuilder> get routes => {
        initial: (context) => const SplashScreen(),
        mainDashboard: (context) => const MainDashboard(),
        financialDashboard: (context) => const FinancialDashboard(),
        splash: (context) => const SplashScreen(),
        invoiceGeneration: (context) => const InvoiceGeneration(),
        deliveryTracking: (context) => const DeliveryTracking(),
        customerManagement: (context) => const CustomerManagement(),
        barcodeScanner: (context) => const BarcodeScanner(),
        login: (context) => const LoginScreen(),
        salesOrderProcessing: (context) => const SalesOrderProcessing(),
        inventoryManagement: (context) => const InventoryManagement(),
        productCatalog: (context) => const ProductCatalog(),
        customerPortal: (context) => const CustomerPortal(),
        documentsScreen: (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;
          return DocumentsScreen(
            entityType: args['entityType'],
            entityId: args['entityId'],
            entityName: args['entityName'],
          );
        },
        notificationsScreen: (context) => const NotificationsCenter(),
        notificationsCenter: (context) => const NotificationsCenter(),
        reportsAnalytics: (context) => const ReportsAnalyticsScreen(),
        settingsConfiguration: (context) => const SettingsConfigurationScreen(),
        userRoleManagement: (context) => const UserRoleManagementScreen(),
        auditLog: (context) => const AuditLogScreen(),
        securityDashboard: (context) => const SecurityDashboard(),
        securityAlertCenter: (context) => const SecurityAlertCenter(),
        automationRulesManager: (context) => const AutomationRulesManager(),
        incidentManagementCenter: (context) => const IncidentManagementCenter(),
        incidentInvestigationWorkspace: (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;
          return IncidentInvestigationWorkspaceScreen(
            incidentId: args['incidentId'],
            incidentTitle: args['incidentTitle'],
            severity: args['severity'],
          );
        },
        purchases: (context) => const PurchasesScreen(),
        expenses: (context) => const ExpensesScreen(),
        productDetail: (context) => const ProductCatalog(),
      };
}

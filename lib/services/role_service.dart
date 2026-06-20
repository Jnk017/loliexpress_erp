import 'package:flutter/material.dart';
import 'auth_service.dart';

enum UserRole {
  admin,
  salesRep,
  warehouseStaff,
  customer,
  comptable,
  acheteur,
  deliveryAgent,
  unknown
}

class RoleService {
  static RoleService? _instance;
  static RoleService get instance => _instance ??= RoleService._();
  RoleService._();

  UserRole _currentRole = UserRole.unknown;
  UserRole get currentRole => _currentRole;

  Future<void> refreshRole() async {
    final roleStr = await AuthService.instance.getUserRole();
    _currentRole = _parseRole(roleStr);
  }

  UserRole _parseRole(String? role) {
    switch (role) {
      case 'admin':
        return UserRole.admin;
      case 'commercial_staff':
        return UserRole.salesRep;
      case 'warehouse_staff':
        return UserRole.warehouseStaff;
      case 'client_b2b':
        return UserRole.customer;
      case 'comptable':
        return UserRole.comptable;
      case 'acheteur':
        return UserRole.acheteur;
      case 'delivery_agent':
        return UserRole.deliveryAgent;
      default:
        return UserRole.unknown;
    }
  }

  void setRole(String? roleStr) {
    _currentRole = _parseRole(roleStr);
  }

  bool canAccess(String route) {
    switch (_currentRole) {
      case UserRole.admin:
        return true;
      case UserRole.salesRep:
        return _salesRepRoutes.contains(route);
      case UserRole.warehouseStaff:
        return _warehouseRoutes.contains(route);
      case UserRole.customer:
        return _customerRoutes.contains(route);
      case UserRole.comptable:
        return _comptableRoutes.contains(route);
      case UserRole.acheteur:
        return _acheteurRoutes.contains(route);
      case UserRole.deliveryAgent:
        return _deliveryAgentRoutes.contains(route);
      case UserRole.unknown:
        return false;
    }
  }

  bool get canEditPrices => _currentRole == UserRole.admin;
  bool get canViewFinancials =>
      _currentRole == UserRole.admin || _currentRole == UserRole.comptable;
  bool get canViewProfitReports =>
      _currentRole == UserRole.admin || _currentRole == UserRole.comptable;
  bool get canViewStockReports =>
      _currentRole == UserRole.admin || _currentRole == UserRole.warehouseStaff;
  bool get canManageUsers => _currentRole == UserRole.admin;
  bool get canViewAllOrders =>
      _currentRole == UserRole.admin || _currentRole == UserRole.salesRep;
  bool get canCreateOrders =>
      _currentRole == UserRole.admin ||
      _currentRole == UserRole.salesRep ||
      _currentRole == UserRole.customer;
  bool get canApprovePurchases => _currentRole == UserRole.admin;
  bool get canApproveExpenses => _currentRole == UserRole.admin;
  bool get canPayExpenses => _currentRole == UserRole.comptable;
  bool get canCreatePurchases => _currentRole == UserRole.acheteur;

  String getHomeRoute() {
    switch (_currentRole) {
      case UserRole.admin:
        return '/admin-dashboard';
      case UserRole.salesRep:
        return '/main-dashboard';
      case UserRole.warehouseStaff:
        return '/inventory-management';
      case UserRole.customer:
        return '/customer-portal';
      case UserRole.comptable:
        return '/main-dashboard';
      case UserRole.acheteur:
        return '/purchases';
      case UserRole.deliveryAgent:
        return '/delivery-tracking';
      case UserRole.unknown:
        return '/login-screen';
    }
  }

  static const _salesRepRoutes = {
    '/main-dashboard',
    '/product-catalog',
    '/product-detail',
    '/customer-management',
    '/sales-order-processing',
    '/invoice-generation',
    '/delivery-tracking',
    '/barcode-scanner',
    '/notifications-screen',
    '/notifications-center',
    '/settings-configuration',
    '/expenses',
  };

  static const _warehouseRoutes = {
    '/inventory-management',
    '/barcode-scanner',
    '/notifications-screen',
    '/notifications-center',
    '/settings-configuration',
    '/expenses',
  };

  static const _customerRoutes = {
    '/customer-portal',
    '/product-catalog',
    '/product-detail',
    '/sales-order-processing',
    '/invoice-generation',
    '/notifications-screen',
    '/documents-screen',
  };

  static const _comptableRoutes = {
    '/main-dashboard',
    '/product-catalog',
    '/product-detail',
    '/customer-management',
    '/sales-order-processing',
    '/invoice-generation',
    '/delivery-tracking',
    '/inventory-management',
    '/barcode-scanner',
    '/financial-dashboard',
    '/reports-analytics',
    '/purchases',
    '/notifications-screen',
    '/notifications-center',
    '/settings-configuration',
    '/expenses',
  };

  static const _acheteurRoutes = {
    '/purchases',
    '/product-catalog',
    '/product-detail',
    '/inventory-management',
    '/barcode-scanner',
    '/notifications-screen',
    '/notifications-center',
    '/settings-configuration',
    '/expenses',
  };

  static const _deliveryAgentRoutes = {
    '/delivery-tracking',
    '/notifications-screen',
    '/notifications-center',
    '/settings-configuration',
  };

  List<BottomNavItem> getBottomNavItems() {
    switch (_currentRole) {
      case UserRole.admin:
        return [
          BottomNavItem(
              icon: Icons.dashboard,
              label: 'Dashboard',
              route: '/admin-dashboard'),
          BottomNavItem(
              icon: Icons.inventory_2,
              label: 'Stock',
              route: '/inventory-management'),
          BottomNavItem(
              icon: Icons.shopping_cart,
              label: 'Ventes',
              route: '/sales-order-processing'),
          BottomNavItem(
              icon: Icons.shopping_bag, label: 'Achats', route: '/purchases'),
          BottomNavItem(
              icon: Icons.receipt_long, label: 'Dépenses', route: '/expenses'),
          BottomNavItem(
              icon: Icons.analytics,
              label: 'Rapports',
              route: '/reports-analytics'),
        ];
      case UserRole.salesRep:
        return [
          BottomNavItem(
              icon: Icons.dashboard,
              label: 'Dashboard',
              route: '/main-dashboard'),
          BottomNavItem(
              icon: Icons.shopping_cart,
              label: 'Ventes',
              route: '/sales-order-processing'),
          BottomNavItem(
              icon: Icons.people,
              label: 'Clients',
              route: '/customer-management'),
          BottomNavItem(
              icon: Icons.local_shipping,
              label: 'Livraisons',
              route: '/delivery-tracking'),
        ];
      case UserRole.warehouseStaff:
        return [
          BottomNavItem(
              icon: Icons.inventory_2,
              label: 'Stock',
              route: '/inventory-management'),
          BottomNavItem(
              icon: Icons.qr_code_scanner,
              label: 'Scanner',
              route: '/barcode-scanner'),
        ];
      case UserRole.customer:
        return [
          BottomNavItem(
              icon: Icons.storefront,
              label: 'Catalogue',
              route: '/product-catalog'),
          BottomNavItem(
              icon: Icons.shopping_bag,
              label: 'Commandes',
              route: '/customer-portal'),
        ];
      case UserRole.comptable:
        return [
          BottomNavItem(
              icon: Icons.dashboard,
              label: 'Dashboard',
              route: '/main-dashboard'),
          BottomNavItem(
              icon: Icons.inventory_2,
              label: 'Stock',
              route: '/inventory-management'),
          BottomNavItem(
              icon: Icons.receipt_long, label: 'Dépenses', route: '/expenses'),
          BottomNavItem(
              icon: Icons.shopping_bag, label: 'Achats', route: '/purchases'),
          BottomNavItem(
              icon: Icons.analytics,
              label: 'Rapports',
              route: '/reports-analytics'),
        ];
      case UserRole.acheteur:
        return [
          BottomNavItem(
              icon: Icons.shopping_bag, label: 'Achats', route: '/purchases'),
          BottomNavItem(
              icon: Icons.storefront,
              label: 'Catalogue',
              route: '/product-catalog'),
          BottomNavItem(
              icon: Icons.inventory_2,
              label: 'Stock',
              route: '/inventory-management'),
        ];
      case UserRole.deliveryAgent:
        return [
          BottomNavItem(
              icon: Icons.local_shipping,
              label: 'Livraisons',
              route: '/delivery-tracking'),
          BottomNavItem(
              icon: Icons.notifications,
              label: 'Alertes',
              route: '/notifications-center'),
        ];
      case UserRole.unknown:
        return [];
    }
  }
}

class BottomNavItem {
  final IconData icon;
  final String label;
  final String route;
  const BottomNavItem(
      {required this.icon, required this.label, required this.route});
}

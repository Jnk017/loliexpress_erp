import 'package:flutter/material.dart';
import 'auth_service.dart';

enum UserRole { admin, sales, warehouse, unknown }

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
      case 'comptable':
      case 'acheteur':
        return UserRole.admin;
      case 'sales':
      case 'sales_rep':
      case 'b2b_customer':
        return UserRole.sales;
      case 'warehouse':
      case 'warehouse_staff':
        return UserRole.warehouse;
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
      case UserRole.sales:
        return _salesRoutes.contains(route);
      case UserRole.warehouse:
        return _warehouseRoutes.contains(route);
      case UserRole.unknown:
        return false;
    }
  }

  bool get canEditPrices => _currentRole == UserRole.admin;
  bool get canViewFinancials => _currentRole == UserRole.admin;
  bool get canViewProfitReports => _currentRole == UserRole.admin;
  bool get canViewStockReports => _currentRole == UserRole.admin || _currentRole == UserRole.warehouse;
  bool get canManageUsers => _currentRole == UserRole.admin;
  bool get canViewAllOrders => _currentRole == UserRole.admin || _currentRole == UserRole.sales;
  bool get canCreateOrders => _currentRole == UserRole.admin || _currentRole == UserRole.sales;
  bool get canApprovePurchases => _currentRole == UserRole.admin;
  bool get canApproveExpenses => _currentRole == UserRole.admin;
  bool get canPayExpenses => _currentRole == UserRole.admin;
  bool get canCreatePurchases => _currentRole == UserRole.admin;

  String getHomeRoute() {
    switch (_currentRole) {
      case UserRole.admin: return '/main-dashboard';
      case UserRole.sales: return '/main-dashboard';
      case UserRole.warehouse: return '/inventory-management';
      case UserRole.unknown: return '/login-screen';
    }
  }

  static const _salesRoutes = {
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
  };

  static const _warehouseRoutes = {
    '/inventory-management',
    '/barcode-scanner',
    '/notifications-screen',
    '/notifications-center',
    '/settings-configuration',
  };

  List<BottomNavItem> getBottomNavItems() {
    switch (_currentRole) {
      case UserRole.admin:
        return [
          BottomNavItem(icon: Icons.dashboard, label: 'Dashboard', route: '/main-dashboard'),
          BottomNavItem(icon: Icons.inventory_2, label: 'Stock', route: '/inventory-management'),
          BottomNavItem(icon: Icons.shopping_cart, label: 'Ventes', route: '/sales-order-processing'),
          BottomNavItem(icon: Icons.shopping_bag, label: 'Achats', route: '/purchases'),
          BottomNavItem(icon: Icons.receipt_long, label: 'Dépenses', route: '/expenses'),
          BottomNavItem(icon: Icons.analytics, label: 'Rapports', route: '/reports-analytics'),
        ];
      case UserRole.sales:
        return [
          BottomNavItem(icon: Icons.dashboard, label: 'Dashboard', route: '/main-dashboard'),
          BottomNavItem(icon: Icons.shopping_cart, label: 'Ventes', route: '/sales-order-processing'),
          BottomNavItem(icon: Icons.people, label: 'Clients', route: '/customer-management'),
          BottomNavItem(icon: Icons.local_shipping, label: 'Livraisons', route: '/delivery-tracking'),
        ];
      case UserRole.warehouse:
        return [
          BottomNavItem(icon: Icons.inventory_2, label: 'Stock', route: '/inventory-management'),
          BottomNavItem(icon: Icons.qr_code_scanner, label: 'Scanner', route: '/barcode-scanner'),
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
  const BottomNavItem({required this.icon, required this.label, required this.route});
}

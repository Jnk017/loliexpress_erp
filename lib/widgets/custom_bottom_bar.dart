import 'package:flutter/material.dart';

/// Navigation item configuration for bottom bar
class CustomBottomBarItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final String route;

  const CustomBottomBarItem({
    required this.icon,
    this.activeIcon,
    required this.label,
    required this.route,
  });
}

/// Custom bottom navigation bar for Loliexpress ERP
/// Implements hybrid tab bar pattern with role-based core functions
class CustomBottomBar extends StatelessWidget {
  final int currentIndex;
  final Function(int)? onTap;
  final List<CustomBottomBarItem>? customItems;

  const CustomBottomBar({
    super.key,
    required this.currentIndex,
    this.onTap,
    this.customItems,
  });

  /// Default navigation items based on Mobile Navigation Hierarchy
  static final List<CustomBottomBarItem> _defaultItems = [
    const CustomBottomBarItem(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
      label: 'Dashboard',
      route: '/main-dashboard',
    ),
    const CustomBottomBarItem(
      icon: Icons.inventory_2_outlined,
      activeIcon: Icons.inventory_2,
      label: 'Inventory',
      route: '/inventory-management',
    ),
    const CustomBottomBarItem(
      icon: Icons.shopping_cart_outlined,
      activeIcon: Icons.shopping_cart,
      label: 'Orders',
      route: '/sales-order-processing',
    ),
    const CustomBottomBarItem(
      icon: Icons.people_outline,
      activeIcon: Icons.people,
      label: 'Customers',
      route: '/customer-management',
    ),
    const CustomBottomBarItem(
      icon: Icons.analytics_outlined,
      activeIcon: Icons.analytics,
      label: 'Reports',
      route: '/financial-dashboard',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = customItems ?? _defaultItems;

    return Container(
      decoration: BoxDecoration(
        color: theme.bottomNavigationBarTheme.backgroundColor,
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              items.length,
              (index) => _buildNavItem(
                context: context,
                item: items[index],
                index: index,
                isSelected: currentIndex == index,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required CustomBottomBarItem item,
    required int index,
    required bool isSelected,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final color = isSelected
        ? colorScheme.primary
        : theme.bottomNavigationBarTheme.unselectedItemColor;

    final icon =
        isSelected && item.activeIcon != null ? item.activeIcon! : item.icon;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (onTap != null) {
              onTap!(index);
            } else {
              Navigator.pushReplacementNamed(context, item.route);
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon with subtle scale animation
                AnimatedScale(
                  scale: isSelected ? 1.1 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  child: Icon(
                    icon,
                    size: 24,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                // Label
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  style: (isSelected
                          ? theme.bottomNavigationBarTheme.selectedLabelStyle
                          : theme
                              .bottomNavigationBarTheme.unselectedLabelStyle) ??
                      TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: color,
                      ),
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Variant with floating action button integration
class CustomBottomBarWithFAB extends StatelessWidget {
  final int currentIndex;
  final Function(int)? onTap;
  final VoidCallback? onFabPressed;
  final IconData fabIcon;
  final String fabTooltip;
  final List<CustomBottomBarItem>? customItems;

  const CustomBottomBarWithFAB({
    super.key,
    required this.currentIndex,
    this.onTap,
    this.onFabPressed,
    this.fabIcon = Icons.qr_code_scanner,
    this.fabTooltip = 'Scan Barcode',
    this.customItems,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = customItems ?? CustomBottomBar._defaultItems;

    // Split items for FAB placement (2 items on each side)
    final leftItems = items.take(2).toList();
    final rightItems = items.skip(2).take(3).toList();

    return Container(
      decoration: BoxDecoration(
        color: theme.bottomNavigationBarTheme.backgroundColor,
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Left items
              ...leftItems.asMap().entries.map((entry) {
                return Expanded(
                  child: _buildNavItem(
                    context: context,
                    item: entry.value,
                    index: entry.key,
                    isSelected: currentIndex == entry.key,
                  ),
                );
              }),
              // FAB placeholder
              const SizedBox(width: 56),
              // Right items
              ...rightItems.asMap().entries.map((entry) {
                final actualIndex = entry.key + 2;
                return Expanded(
                  child: _buildNavItem(
                    context: context,
                    item: entry.value,
                    index: actualIndex,
                    isSelected: currentIndex == actualIndex,
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required CustomBottomBarItem item,
    required int index,
    required bool isSelected,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final color = isSelected
        ? colorScheme.primary
        : theme.bottomNavigationBarTheme.unselectedItemColor;

    final icon =
        isSelected && item.activeIcon != null ? item.activeIcon! : item.icon;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (onTap != null) {
            onTap!(index);
          } else {
            Navigator.pushReplacementNamed(context, item.route);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: isSelected ? 1.1 : 1.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: Icon(
                  icon,
                  size: 24,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                style: (isSelected
                        ? theme.bottomNavigationBarTheme.selectedLabelStyle
                        : theme
                            .bottomNavigationBarTheme.unselectedLabelStyle) ??
                    TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: color,
                    ),
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

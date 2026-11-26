import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_bottom_bar.dart';
import './widgets/account_tab_widget.dart';
import './widgets/documents_tab_widget.dart';
import './widgets/orders_tab_widget.dart';
import './widgets/support_tab_widget.dart';

/// Customer Portal Screen
/// Provides secure B2B customer access for order placement, document viewing, and account management
class CustomerPortal extends StatefulWidget {
  const CustomerPortal({super.key});

  @override
  State<CustomerPortal> createState() => _CustomerPortalState();
}

class _CustomerPortalState extends State<CustomerPortal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTabIndex = 0;

  final List<Map<String, dynamic>> _tabs = [
    {'icon': 'shopping_bag', 'label': 'Commandes'},
    {'icon': 'description', 'label': 'Documents'},
    {'icon': 'account_circle', 'label': 'Compte'},
    {'icon': 'support_agent', 'label': 'Support'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      bottomNavigationBar: const CustomBottomBar(currentIndex: 1),
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Portail Client',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Loliexpress Distribution',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: CustomIconWidget(
              iconName: 'notifications',
              color: theme.colorScheme.onPrimary,
              size: 24,
            ),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.notificationsScreen),
            tooltip: 'Notifications',
          ),
          SizedBox(width: 2.w),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(6.h),
          child: Container(
            color: theme.colorScheme.primary,
            child: TabBar(
              controller: _tabController,
              indicatorColor: theme.colorScheme.onPrimary,
              indicatorWeight: 3,
              labelColor: theme.colorScheme.onPrimary,
              unselectedLabelColor:
                  theme.colorScheme.onPrimary.withValues(alpha: 0.6),
              labelStyle: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: theme.textTheme.labelMedium,
              tabs: _tabs.map((tab) {
                return Tab(
                  icon: CustomIconWidget(
                    iconName: tab['icon'],
                    color: _currentTabIndex == _tabs.indexOf(tab)
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onPrimary.withValues(alpha: 0.6),
                    size: 20,
                  ),
                  text: tab['label'],
                );
              }).toList(),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          OrdersTabWidget(),
          DocumentsTabWidget(),
          AccountTabWidget(),
          SupportTabWidget(),
        ],
      ),
    );
  }

}

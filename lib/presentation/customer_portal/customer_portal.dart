import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
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
            onPressed: () {
              _showNotifications(context);
            },
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

  void _showNotifications(BuildContext context) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(4.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Notifications',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: CustomIconWidget(
                      iconName: 'close',
                      color: theme.colorScheme.onSurface,
                      size: 24,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              _buildNotificationItem(
                context,
                'Commande #CMD-2024-1156 expédiée',
                'Votre commande a été expédiée et sera livrée demain',
                'Il y a 2 heures',
                Icons.local_shipping,
                theme.colorScheme.primary,
              ),
              Divider(height: 3.h),
              _buildNotificationItem(
                context,
                'Nouvelle facture disponible',
                'Facture #FAC-2024-0892 est maintenant disponible',
                'Il y a 5 heures',
                Icons.receipt_long,
                AppTheme.warningLight,
              ),
              Divider(height: 3.h),
              _buildNotificationItem(
                context,
                'Rappel de paiement',
                'Paiement de 125 000 XOF dû le 30/11/2025',
                'Hier',
                Icons.payment,
                AppTheme.errorLight,
              ),
              SizedBox(height: 2.h),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotificationItem(
    BuildContext context,
    String title,
    String message,
    String time,
    IconData icon,
    Color iconColor,
  ) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(2.w),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 20,
          ),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 0.5.h),
              Text(
                message,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 0.5.h),
              Text(
                time,
                style: theme.textTheme.labelSmall?.copyWith(
                  color:
                      theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/notification_service.dart';
import '../../widgets/custom_app_bar.dart';
import './widgets/notification_swipe_card_widget.dart';
import './widgets/category_filter_widget.dart';
import './widgets/notification_settings_widget.dart';

/// Comprehensive Notifications Center with priority-based organization and actionable responses
class NotificationsCenter extends StatefulWidget {
  const NotificationsCenter({super.key});

  @override
  State<NotificationsCenter> createState() => _NotificationsCenterState();
}

class _NotificationsCenterState extends State<NotificationsCenter> {
  final _notificationService = NotificationService();
  final _searchController = TextEditingController();

  List<Map<String, dynamic>> _allNotifications = [];
  List<Map<String, dynamic>> _filteredNotifications = [];
  String _selectedCategory = 'All';
  bool _isLoading = true;
  String? _error;

  final List<String> _categories = [
    'All',
    'Orders',
    'Inventory',
    'Payments',
    'System',
  ];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final hiddenTypes = await _notificationService.loadCenterPreferences();
      final notifications = await _notificationService.getUserNotifications(
        hiddenTypes: hiddenTypes,
      );
      if (!mounted) return;
      setState(() {
        _allNotifications = notifications;
        _filterNotifications();
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Impossible de charger les notifications.';
        _isLoading = false;
      });
    }
  }

  void _filterNotifications() {
    List<Map<String, dynamic>> filtered = _allNotifications;

    // Filter by category
    if (_selectedCategory != 'All') {
      filtered = filtered.where((notification) {
        final type = notification['notification_type'] as String;
        switch (_selectedCategory) {
          case 'Orders':
            return type.contains('order') || type.contains('delivery');
          case 'Inventory':
            return type.contains('stock') || type.contains('inventory');
          case 'Payments':
            return type.contains('payment') || type.contains('invoice');
          case 'System':
            return type.contains('system') || type.contains('alert');
          default:
            return true;
        }
      }).toList();
    }

    // Filter by search
    if (_searchController.text.isNotEmpty) {
      filtered = filtered.where((notification) {
        final searchLower = _searchController.text.toLowerCase();
        final subject = (notification['subject'] as String).toLowerCase();
        final message = (notification['message'] as String).toLowerCase();
        return subject.contains(searchLower) || message.contains(searchLower);
      }).toList();
    }

    setState(() {
      _filteredNotifications = filtered;
    });
  }

  String _getPriorityLevel(String notificationType) {
    switch (notificationType) {
      case 'low_stock':
      case 'system_error':
      case 'overdue_invoice':
        return 'critical';
      case 'payment_pending':
      case 'order_delayed':
        return 'important';
      default:
        return 'informational';
    }
  }

  Future<void> _handleMarkAsRead(String notificationId) async {
    try {
      await _notificationService.markAsRead(notificationId);
      _loadNotifications();
    } catch (e) {
      _showSnackbar('Erreur: ${e.toString()}', Colors.red);
    }
  }

  Future<void> _handleTakeAction(Map<String, dynamic> notification) async {
    final type = notification['notification_type'] as String;

    // Navigate to relevant screen based on notification type
    if (type.contains('order')) {
      Navigator.pushNamed(context, '/sales-order-processing');
    } else if (type.contains('stock')) {
      Navigator.pushNamed(context, '/inventory-management');
    } else if (type.contains('payment') || type.contains('invoice')) {
      Navigator.pushNamed(context, '/financial-dashboard');
    }

    _handleMarkAsRead(notification['id']);
  }

  Future<void> _handleDismiss(String notificationId) async {
    try {
      await _notificationService.markAsRead(notificationId);
      _loadNotifications();
      _showSnackbar('Notification rejetée', Colors.grey);
    } catch (e) {
      _showSnackbar('Erreur: ${e.toString()}', Colors.red);
    }
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  Future<void> _showNotificationSettings() async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (context) => NotificationSettingsWidget(service: _notificationService),
    );
    if (mounted && saved == true) await _loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Centre de Notifications',
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: EdgeInsets.all(3.w),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => _filterNotifications(),
              decoration: InputDecoration(
                hintText: 'Rechercher par contenu, date ou module...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterNotifications();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
            ),
          ),

          // Category filters
          CategoryFilterWidget(
            categories: _categories,
            selectedCategory: _selectedCategory,
            onCategorySelected: (category) {
              setState(() {
                _selectedCategory = category;
                _filterNotifications();
              });
            },
          ),

          // Unread count badge
          if (_filteredNotifications.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 3.w,
                      vertical: 0.5.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: Text(
                      '${_filteredNotifications.where((n) => n['read_at'] == null).length} non lues',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Notifications list
          Expanded(child: _buildBody()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showNotificationSettings,
        icon: const Icon(Icons.settings),
        label: const Text('Paramètres'),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            SizedBox(height: 2.h),
            Text('Erreur: $_error'),
            SizedBox(height: 2.h),
            ElevatedButton(
              onPressed: _loadNotifications,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_filteredNotifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none, size: 64, color: Colors.grey[400]),
            SizedBox(height: 2.h),
            Text(
              _searchController.text.isNotEmpty || _selectedCategory != 'All'
                  ? 'Aucune notification trouvée'
                  : 'Aucune notification',
              style: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView.builder(
        padding: EdgeInsets.all(3.w),
        itemCount: _filteredNotifications.length,
        itemBuilder: (context, index) {
          final notification = _filteredNotifications[index];
          final priority = _getPriorityLevel(notification['notification_type']);

          return NotificationSwipeCardWidget(
            notification: notification,
            priority: priority,
            onMarkAsRead: () => _handleMarkAsRead(notification['id']),
            onTakeAction: () => _handleTakeAction(notification),
            onDismiss: () => _handleDismiss(notification['id']),
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';
import '../../services/theme_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import './widgets/settings_item_widget.dart';
import './widgets/settings_section_widget.dart';
import './widgets/user_profile_header_widget.dart';

class SettingsConfigurationScreen extends StatefulWidget {
  const SettingsConfigurationScreen({Key? key}) : super(key: key);

  @override
  State<SettingsConfigurationScreen> createState() =>
      _SettingsConfigurationScreenState();
}

class _SettingsConfigurationScreenState
    extends State<SettingsConfigurationScreen> {
  bool _notificationsEnabled = true;
  bool _biometricEnabled = false;
  bool _autoBackupEnabled = true;
  String _selectedLanguage = 'French';
  String _selectedCurrency = 'EUR (€)';

  String _userName = 'Chargement...';
  String _userEmail = '';
  String _userRole = '';

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final profile = await AuthService.instance.getUserProfile();
    final user = AuthService.instance.currentUser;
    if (mounted) {
      setState(() {
        _userName = profile?['full_name'] ?? user?.userMetadata?['full_name'] ?? 'User';
        _userEmail = user?.email ?? '';
        _userRole = profile?['role'] ?? user?.userMetadata?['role'] ?? 'User';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Settings & Configuration',
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () => _showSearchDialog(),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(3.w),
        children: [
          UserProfileHeaderWidget(
            name: _userName,
            email: _userEmail,
            role: _userRole,
            avatarUrl:
                'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e',
            onEditProfile: () => _showEditProfileDialog(),
          ),
          SizedBox(height: 3.h),
          SettingsSectionWidget(
            title: 'User Profile',
            children: [
              SettingsItemWidget(
                icon: Icons.person,
                title: 'Edit Profile',
                subtitle: 'Update your personal information',
                onTap: () => _showEditProfileDialog(),
              ),
              SettingsItemWidget(
                icon: Icons.lock,
                title: 'Change Password',
                subtitle: 'Update your account password',
                onTap: () => _showChangePasswordDialog(),
              ),
              SettingsItemWidget(
                icon: Icons.admin_panel_settings,
                title: 'Role & Permissions',
                subtitle: 'Manage access levels',
                onTap: () => _showRoleDialog(),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          SettingsSectionWidget(
            title: 'Business Configuration',
            children: [
              SettingsItemWidget(
                icon: Icons.business,
                title: 'Company Details',
                subtitle: 'Business name, address, contact',
                onTap: () => _showCompanyDialog(),
              ),
              SettingsItemWidget(
                icon: Icons.receipt,
                title: 'Tax Settings',
                subtitle: 'VAT, tax rates configuration',
                onTap: () => _showTaxDialog(),
              ),
              SettingsItemWidget(
                icon: Icons.attach_money,
                title: 'Currency Preferences',
                subtitle: _selectedCurrency,
                onTap: () => _showCurrencyDialog(),
                trailing: Icon(Icons.arrow_forward_ios, size: 16.sp),
              ),
              SettingsItemWidget(
                icon: Icons.warehouse,
                title: 'Warehouse Locations',
                subtitle: 'Manage multiple locations',
                onTap: () => _showWarehouseDialog(),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          SettingsSectionWidget(
            title: 'System Preferences',
            children: [
              SettingsItemWidget(
                icon: Icons.language,
                title: 'Language',
                subtitle: _selectedLanguage,
                onTap: () => _showLanguageDialog(),
                trailing: Icon(Icons.arrow_forward_ios, size: 16.sp),
              ),
              SettingsItemWidget(
                icon: Icons.dark_mode,
                title: 'Dark Mode',
                subtitle: 'Toggle dark theme',
                trailing: Switch(
                  value: ThemeService.instance.isDarkMode,
                  onChanged: (value) {
                    ThemeService.instance.toggleTheme();
                    setState(() {});
                  },
                ),
              ),
              SettingsItemWidget(
                icon: Icons.sync,
                title: 'Data Sync Frequency',
                subtitle: 'Every 15 minutes',
                onTap: () => _showSyncDialog(),
                trailing: Icon(Icons.arrow_forward_ios, size: 16.sp),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          SettingsSectionWidget(
            title: 'Security',
            children: [
              SettingsItemWidget(
                icon: Icons.notifications,
                title: 'Notifications',
                subtitle: 'Push notifications settings',
                trailing: Switch(
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() => _notificationsEnabled = value);
                  },
                ),
              ),
              SettingsItemWidget(
                icon: Icons.fingerprint,
                title: 'Biometric Login',
                subtitle: 'Use fingerprint or Face ID',
                trailing: Switch(
                  value: _biometricEnabled,
                  onChanged: (value) {
                    setState(() => _biometricEnabled = value);
                  },
                ),
              ),
              SettingsItemWidget(
                icon: Icons.verified_user,
                title: 'Two-Factor Authentication',
                subtitle: 'Add extra security layer',
                onTap: () => _show2FADialog(),
              ),
              SettingsItemWidget(
                icon: Icons.timer,
                title: 'Session Timeout',
                subtitle: '30 minutes of inactivity',
                onTap: () => _showSessionDialog(),
                trailing: Icon(Icons.arrow_forward_ios, size: 16.sp),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          SettingsSectionWidget(
            title: 'Integrations',
            children: [
              SettingsItemWidget(
                icon: Icons.account_balance,
                title: 'Accounting Software',
                subtitle: 'Connect QuickBooks, Sage',
                onTap: () => _showAccountingDialog(),
                trailing: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha(26),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Connected',
                    style: TextStyle(color: Colors.green, fontSize: 11.sp),
                  ),
                ),
              ),
              SettingsItemWidget(
                icon: Icons.payment,
                title: 'Payment Gateways',
                subtitle: 'Stripe, PayPal integration',
                onTap: () => _showPaymentDialog(),
              ),
              SettingsItemWidget(
                icon: Icons.local_shipping,
                title: 'Shipping Providers',
                subtitle: 'DHL, FedEx, UPS setup',
                onTap: () => _showShippingDialog(),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          SettingsSectionWidget(
            title: 'Backup & Sync',
            children: [
              SettingsItemWidget(
                icon: Icons.cloud_upload,
                title: 'Automatic Cloud Backup',
                subtitle: 'Daily backups at 2:00 AM',
                trailing: Switch(
                  value: _autoBackupEnabled,
                  onChanged: (value) {
                    setState(() => _autoBackupEnabled = value);
                  },
                ),
              ),
              SettingsItemWidget(
                icon: Icons.file_download,
                title: 'Export Data',
                subtitle: 'Download all business data',
                onTap: () => _showExportDialog(),
              ),
              SettingsItemWidget(
                icon: Icons.storage,
                title: 'Offline Storage',
                subtitle: '2.3 GB used of 10 GB',
                onTap: () => _showStorageDialog(),
                trailing: Icon(Icons.arrow_forward_ios, size: 16.sp),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          SettingsSectionWidget(
            title: 'Help & Support',
            children: [
              SettingsItemWidget(
                icon: Icons.help,
                title: 'Help Center',
                subtitle: 'FAQs and guides',
                onTap: () {},
              ),
              SettingsItemWidget(
                icon: Icons.contact_support,
                title: 'Contact Support',
                subtitle: 'Get help from our team',
                onTap: () {},
              ),
              SettingsItemWidget(
                icon: Icons.info,
                title: 'About',
                subtitle: 'Version 1.0.0',
                onTap: () => _showAboutDialog(),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          ElevatedButton.icon(
            onPressed: () => _showResetDialog(),
            icon: Icon(Icons.restore),
            label: Text('Reset to Factory Defaults'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 2.h),
            ),
          ),
          SizedBox(height: 2.h),
          ElevatedButton.icon(
            onPressed: () => _showLogoutDialog(),
            icon: Icon(Icons.logout),
            label: Text('Logout'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[800],
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 2.h),
            ),
          ),
          SizedBox(height: 2.h),
        ],
      ),
      bottomNavigationBar: CustomBottomBar(currentIndex: 0),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Search Settings'),
        content: TextField(
          decoration: InputDecoration(
            hintText: 'Type to search...',
            prefixIcon: Icon(Icons.search),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(decoration: InputDecoration(labelText: 'Full Name')),
            SizedBox(height: 1.h),
            TextField(decoration: InputDecoration(labelText: 'Email')),
            SizedBox(height: 1.h),
            TextField(decoration: InputDecoration(labelText: 'Phone')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Profile updated successfully')),
              );
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(labelText: 'Current Password'),
              obscureText: true,
            ),
            SizedBox(height: 1.h),
            TextField(
              decoration: InputDecoration(labelText: 'New Password'),
              obscureText: true,
            ),
            SizedBox(height: 1.h),
            TextField(
              decoration: InputDecoration(labelText: 'Confirm Password'),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Password changed successfully')),
              );
            },
            child: Text('Change'),
          ),
        ],
      ),
    );
  }

  void _showRoleDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Role & Permissions'),
        content: Text(
          'Current Role: Administrator\n\nPermissions:\n• Full system access\n• User management\n• Configuration control',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showCompanyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Company Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(decoration: InputDecoration(labelText: 'Company Name')),
            SizedBox(height: 1.h),
            TextField(decoration: InputDecoration(labelText: 'Address')),
            SizedBox(height: 1.h),
            TextField(decoration: InputDecoration(labelText: 'Phone')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showTaxDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Tax Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(decoration: InputDecoration(labelText: 'VAT Number')),
            SizedBox(height: 1.h),
            TextField(decoration: InputDecoration(labelText: 'Tax Rate (%)')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showCurrencyDialog() {
    final currencies = ['EUR (€)', 'USD (\$)', 'GBP (£)', 'XOF (CFA)'];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Currency'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: currencies
              .map(
                (currency) => ListTile(
                  title: Text(currency),
                  onTap: () {
                    setState(() => _selectedCurrency = currency);
                    Navigator.pop(context);
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  void _showWarehouseDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Warehouse Locations'),
        content: Text(
          'Main Warehouse: Paris\nWarehouse 2: Lyon\nWarehouse 3: Marseille',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Add Location'),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog() {
    final languages = ['French', 'English'];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: languages
              .map(
                (lang) => ListTile(
                  title: Text(lang),
                  onTap: () {
                    setState(() => _selectedLanguage = lang);
                    Navigator.pop(context);
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  void _showSyncDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Data Sync Frequency'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children:
              [
                    'Every 5 minutes',
                    'Every 15 minutes',
                    'Every 30 minutes',
                    'Every hour',
                  ]
                  .map(
                    (freq) => ListTile(
                      title: Text(freq),
                      onTap: () => Navigator.pop(context),
                    ),
                  )
                  .toList(),
        ),
      ),
    );
  }

  void _show2FADialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Two-Factor Authentication'),
        content: Text(
          'Set up 2FA for enhanced security using SMS or authenticator app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Later'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Setup'),
          ),
        ],
      ),
    );
  }

  void _showSessionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Session Timeout'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['15 minutes', '30 minutes', '1 hour', 'Never']
              .map(
                (time) => ListTile(
                  title: Text(time),
                  onTap: () => Navigator.pop(context),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  void _showAccountingDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Accounting Software'),
        content: Text(
          'Currently connected to: QuickBooks\n\nLast sync: 2 hours ago',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Disconnect'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Sync Now'),
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Payment Gateways'),
        content: Text('Configure Stripe, PayPal, or other payment providers.'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Add Gateway'),
          ),
        ],
      ),
    );
  }

  void _showShippingDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Shipping Providers'),
        content: Text('Manage shipping integrations with DHL, FedEx, UPS.'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Add Provider'),
          ),
        ],
      ),
    );
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Export Data'),
        content: Text('Export all business data in CSV or JSON format.'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Exporting data...')));
            },
            child: Text('Export'),
          ),
        ],
      ),
    );
  }

  void _showStorageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Offline Storage'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Used: 2.3 GB'),
            Text('Available: 7.7 GB'),
            SizedBox(height: 1.h),
            LinearProgressIndicator(value: 0.23),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Clearing cache...')));
            },
            child: Text('Clear Cache'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'Loliexpress ERP',
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2025 Loliexpress. All rights reserved.',
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reset to Factory Defaults'),
        content: Text(
          'This will reset all settings to default values. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Settings reset to defaults')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Logout'),
        content: Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await AuthService.instance.signOut();
              } catch (_) {}
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.login,
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Logout'),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';
import '../../services/company_settings_service.dart';
import '../../services/theme_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import './widgets/settings_item_widget.dart';
import './widgets/settings_section_widget.dart';
import './widgets/user_profile_header_widget.dart';

class SettingsConfigurationScreen extends StatefulWidget {
  const SettingsConfigurationScreen({super.key});

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
  final _settingsService = const CompanySettingsService();
  Map<String, dynamic>? _companySettings;
  String _selectedCurrency = 'CDF';
  String _userPhone = '';

  String _userName = 'Chargement...';
  String _userEmail = '';
  String _userRole = '';

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadCompanySettings();
  }

  Future<void> _loadUserProfile() async {
    final profile = await AuthService.instance.getUserProfile();
    final user = AuthService.instance.currentUser;
    if (mounted) {
      setState(() {
        _userName =
            profile?['full_name'] ?? user?.userMetadata?['full_name'] ?? 'User';
        _userEmail = user?.email ?? '';
        _userRole = profile?['role'] ?? 'User';
        _userPhone = profile?['phone'] as String? ?? '';
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
                onTap: () => _editCompanySettings('Profil société', const {
                  'company_name': 'Raison sociale', 'company_address': 'Adresse', 'company_phone': 'Téléphone',
                }),
              ),
              SettingsItemWidget(
                icon: Icons.receipt,
                title: 'Tax Settings',
                subtitle: 'VAT, tax rates configuration',
                onTap: () => _editCompanySettings('TVA à 0 % · Prix TTC', const {
                  'tax_identifier': 'Identifiant fiscal',
                }),
              ),
              SettingsItemWidget(
                icon: Icons.attach_money,
                title: 'Currency Preferences',
                subtitle: _selectedCurrency,
                onTap: () => _showCurrencyDialog(),
                trailing: Icon(Icons.arrow_forward_ios, size: 16.sp),
              ),
              SettingsItemWidget(
                icon: Icons.picture_as_pdf,
                title: 'Modèle PDF',
                subtitle: _companySettings?['pdf_title']?.toString() ?? 'Factures',
                onTap: () => _editCompanySettings('Modèle PDF', const {
                  'pdf_title': 'Titre du document', 'pdf_footer': 'Pied de page',
                }),
              ),
              SettingsItemWidget(
                icon: Icons.mail_outline,
                title: 'Expéditeur e-mail',
                subtitle: _companySettings?['sender_email']?.toString() ?? 'Adresse d’expédition',
                onTap: () => _editCompanySettings('Expéditeur e-mail', const {
                  'sender_name': 'Nom affiché', 'sender_email': 'Adresse e-mail',
                }),
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

  Future<void> _loadCompanySettings() async {
    try {
      final settings = await _settingsService.load();
      if (!mounted) return;
      setState(() {
        _companySettings = settings;
        _selectedCurrency = settings['default_currency'] as String;
      });
    } catch (_) {
      if (mounted) _showSettingsMessage('Réglages société indisponibles.');
    }
  }

  void _showSettingsMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<Map<String, String>?> _requestFields(
    String title,
    Map<String, String> labels,
    Map<String, dynamic> values, {
    bool secret = false,
  }) async {
    final edits = <String, String>{
      for (final key in labels.keys) key: values[key]?.toString() ?? '',
    };
    return showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final field in labels.entries)
                TextFormField(
                  initialValue: edits[field.key],
                  obscureText: secret,
                  onChanged: (value) => edits[field.key] = value,
                  decoration: InputDecoration(labelText: field.value),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, edits),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditProfileDialog() async {
    final input = await _requestFields('Profil utilisateur',
      const {'full_name': 'Nom complet', 'phone': 'Téléphone'},
      {'full_name': _userName, 'phone': _userPhone});
    if (!mounted || input == null) return;
    final id = Supabase.instance.client.auth.currentUser?.id;
    if (id == null || input['full_name']!.trim().isEmpty) {
      _showSettingsMessage('Le nom complet est obligatoire.');
      return;
    }
    try {
      await Supabase.instance.client.from('user_profiles').update({
        'full_name': input['full_name']!.trim(),
        'phone': input['phone']!.trim(),
      }).eq('id', id).select('id').single();
      if (!mounted) return;
      await _loadUserProfile();
      if (mounted) _showSettingsMessage('Profil enregistré.');
    } catch (_) {
      if (mounted) _showSettingsMessage('Le profil n’a pas pu être enregistré.');
    }
  }

  Future<void> _showChangePasswordDialog() async {
    final input = await _requestFields('Modifier le mot de passe', const {
      'current': 'Mot de passe actuel',
      'next': 'Nouveau mot de passe',
      'confirm': 'Confirmer le nouveau mot de passe',
    }, const {}, secret: true);
    if (!mounted || input == null) return;
    final next = input['next']!;
    if (input['current']!.isEmpty || next.length < 8 || next != input['confirm']) {
      _showSettingsMessage('Vérifiez les mots de passe. Minimum : 8 caractères.');
      return;
    }
    try {
      final auth = AuthService.instance;
      await auth.signIn(email: _userEmail, password: input['current']!);
      await auth.changePassword(next);
      if (mounted) _showSettingsMessage('Mot de passe modifié.');
    } catch (_) {
      if (mounted) _showSettingsMessage('Le mot de passe n’a pas pu être modifié.');
    }
  }

  void _showRoleDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Role & Permissions'),
        content: Text(
          'Rôle actuel : $_userRole',
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

  Future<void> _editCompanySettings(String title, Map<String, String> fields) async {
    final settings = _companySettings;
    if (settings == null || _userRole != 'admin') return;
    final input = await _requestFields(title, fields, settings);
    if (!mounted || input == null) return;
    final patch = <String, dynamic>{...input};
    if (patch.containsKey('tax_identifier')) patch['tax_rate'] = 0;
    await _saveCompanySettings(patch);
  }

  Future<void> _saveCompanySettings(Map<String, dynamic> patch) async {
    try {
      final result = await _settingsService.save(patch);
      if (!mounted) return;
      setState(() {
        _companySettings = result;
        _selectedCurrency = result['default_currency'] as String;
      });
      _showSettingsMessage('Réglages enregistrés.');
    } catch (_) {
      if (mounted) _showSettingsMessage('Réglages refusés. Vérifiez les valeurs saisies.');
    }
  }

  Future<void> _showCurrencyDialog() async {
    if (_companySettings == null || _userRole != 'admin') return;
    final currency = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Devise par défaut'),
        children: [
          for (final currency in const ['CDF', 'USD'])
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, currency),
              child: Text(currency),
            ),
        ],
      ),
    );
    if (currency != null && mounted) {
      await _saveCompanySettings({'default_currency': currency});
    }
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
          children: [
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
              final navigator = Navigator.of(context);
              Navigator.pop(context);
              try {
                await AuthService.instance.signOut();
              } catch (_) {}
              if (mounted) {
                navigator.pushNamedAndRemoveUntil(
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

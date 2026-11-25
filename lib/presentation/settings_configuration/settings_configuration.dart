import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';
import '../../services/company_settings_service.dart';
import '../../services/inventory_service.dart';
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
      appBar: const CustomAppBar(title: 'Paramètres'),
      body: ListView(
        padding: EdgeInsets.fromLTRB(3.w, 3.w, 3.w, 24 + MediaQuery.paddingOf(context).bottom),
        children: [
          UserProfileHeaderWidget(
            name: _userName,
            email: _userEmail,
            role: _userRole,
            onEditProfile: () => _showEditProfileDialog(),
          ),
          SizedBox(height: 3.h),
          SettingsSectionWidget(
            title: 'Profil utilisateur',
            children: [
              SettingsItemWidget(
                icon: Icons.person,
                title: 'Modifier le profil',
                subtitle: 'Modifier vos informations personnelles',
                onTap: () => _showEditProfileDialog(),
              ),
              SettingsItemWidget(
                icon: Icons.lock,
                title: 'Changer le mot de passe',
                subtitle: 'Modifier le mot de passe du compte',
                onTap: () => _showChangePasswordDialog(),
              ),
              SettingsItemWidget(
                icon: Icons.admin_panel_settings,
                title: 'Rôles et autorisations',
                subtitle: 'Consulter le rôle ou gérer les utilisateurs',
                onTap: () => _userRole == 'admin'
                    ? Navigator.pushNamed(context, AppRoutes.userRoleManagement)
                    : _showRoleDialog(),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          SettingsSectionWidget(
            title: 'Configuration de l’entreprise',
            children: [
              SettingsItemWidget(
                icon: Icons.business,
                title: 'Profil société',
                subtitle: 'Raison sociale, adresse et téléphone',
                onTap: () => _editCompanySettings('Profil société', const {
                  'company_name': 'Raison sociale', 'company_address': 'Adresse', 'company_phone': 'Téléphone',
                }),
              ),
              SettingsItemWidget(
                icon: Icons.receipt,
                title: 'Fiscalité',
                subtitle: 'TVA à 0 % et prix TTC',
                onTap: () => _editCompanySettings('TVA à 0 % · Prix TTC', const {
                  'tax_identifier': 'Identifiant fiscal',
                }),
              ),
              SettingsItemWidget(
                icon: Icons.currency_exchange,
                title: 'Devise par défaut',
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
                title: 'Entrepôts',
                subtitle: 'Consulter les entrepôts enregistrés',
                onTap: () => _showWarehouseDialog(),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          SettingsSectionWidget(
            title: 'Préférences de l’application',
            children: [
              SettingsItemWidget(
                icon: Icons.dark_mode,
                title: 'Mode sombre',
                subtitle: 'Basculer entre le thème clair et le thème sombre',
                trailing: Switch(
                  value: ThemeService.instance.isDarkMode,
                  onChanged: (value) {
                    ThemeService.instance.toggleTheme();
                    setState(() {});
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          SettingsSectionWidget(
            title: 'Application',
            children: [
              SettingsItemWidget(
                icon: Icons.info_outline,
                title: 'À propos',
                subtitle: 'LoliExpress ERP',
                onTap: _showAboutDialog,
              ),
            ],
          ),
          SizedBox(height: 2.h),
          ElevatedButton.icon(
            onPressed: () => _showLogoutDialog(),
            icon: Icon(Icons.logout),
            label: Text('Se déconnecter'),
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
        title: Text('Rôles et autorisations'),
        content: Text(
          'Rôle actuel : $_userRole',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fermer'),
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
    final warehouses = InventoryService.instance.getWarehouses();
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Entrepôts'),
        content: FutureBuilder<List<Map<String, dynamic>>>(
          future: warehouses,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Text('Impossible de charger les entrepôts.');
            }
            if (!snapshot.hasData) {
              return const Center(
                heightFactor: 1,
                child: CircularProgressIndicator(),
              );
            }
            final rows = snapshot.data!;
            return rows.isEmpty
                ? const Text('Aucun entrepôt enregistré.')
                : SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final row in rows)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Text(row['name'] as String),
                          ),
                      ],
                    ),
                  );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
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

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Se déconnecter'),
        content: Text('Voulez-vous vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
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
            child: Text('Se déconnecter'),
          ),
        ],
      ),
    );
  }
}

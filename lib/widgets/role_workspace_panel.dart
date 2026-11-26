import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/role_service.dart';

typedef _WorkspaceAction = ({String title, String route, IconData icon});
typedef _SetupTask = ({String key, String title, String route});

class RoleWorkspacePanel extends StatefulWidget {
  const RoleWorkspacePanel({super.key, this.onNewPurchase});

  final Future<void> Function()? onNewPurchase;

  @override
  State<RoleWorkspacePanel> createState() => _RoleWorkspacePanelState();
}

class _RoleWorkspacePanelState extends State<RoleWorkspacePanel> {
  UserRole get _role => RoleService.instance.currentRole;
  Future<Map<String, dynamic>>? _progress;

  List<_WorkspaceAction> get _actions => switch (_role) {
    UserRole.salesRep => const [
      (title: 'Nouvelle commande', route: '/sales-order-processing', icon: Icons.shopping_cart_outlined),
      (title: 'Clients', route: '/customer-management', icon: Icons.people_outline),
      (title: 'Catalogue', route: '/product-catalog', icon: Icons.inventory_2_outlined),
      (title: 'Scanner', route: '/barcode-scanner', icon: Icons.qr_code_scanner),
    ],
    UserRole.comptable => const [
      (title: 'Factures et encaissements', route: '/invoice-generation', icon: Icons.receipt_long_outlined),
      (title: 'Dépenses', route: '/expenses', icon: Icons.payments_outlined),
      (title: 'Rapports', route: '/reports-analytics', icon: Icons.bar_chart_outlined),
      (title: 'Achats', route: '/purchases', icon: Icons.shopping_bag_outlined),
    ],
    UserRole.acheteur => const [
      (title: 'Nouvel achat', route: '/purchases', icon: Icons.add_shopping_cart),
      (title: 'Catalogue', route: '/product-catalog', icon: Icons.inventory_2_outlined),
      (title: 'Stock', route: '/inventory-management', icon: Icons.warehouse_outlined),
    ],
    UserRole.admin => const [
      (title: 'Ventes', route: '/sales-order-processing', icon: Icons.shopping_cart_outlined),
      (title: 'Factures et encaissements', route: '/invoice-generation', icon: Icons.receipt_long_outlined),
      (title: 'Achats', route: '/purchases', icon: Icons.shopping_bag_outlined),
      (title: 'Stock', route: '/inventory-management', icon: Icons.inventory_2_outlined),
    ],
    _ => const [],
  };

  List<_SetupTask> get _tasks => switch (_role) {
    UserRole.salesRep => const [
      (key: 'assigned_customer', title: 'Avoir un client attribué', route: '/customer-management'),
      (key: 'first_order', title: 'Créer une première commande', route: '/sales-order-processing'),
    ],
    UserRole.comptable => const [
      (key: 'company_profile', title: 'Vérifier le profil de la société', route: '/settings-configuration'),
      (key: 'first_invoice', title: 'Émettre une première facture', route: '/invoice-generation'),
      (key: 'first_payment', title: 'Enregistrer un premier encaissement', route: '/invoice-generation'),
    ],
    UserRole.acheteur => const [
      (key: 'first_supplier', title: 'Avoir un fournisseur actif', route: ''),
      (key: 'first_purchase', title: 'Créer un premier achat', route: '/purchases'),
    ],
    UserRole.admin => const [
      (key: 'company_profile', title: 'Renseigner le profil de la société', route: '/settings-configuration'),
      (key: 'first_product', title: 'Ajouter un premier article', route: '/product-catalog'),
      (key: 'first_invoice', title: 'Émettre une première facture', route: '/invoice-generation'),
    ],
    _ => const [],
  };

  @override
  void initState() {
    super.initState();
    if (_tasks.isNotEmpty) _progress = _load();
  }

  Future<Map<String, dynamic>> _load() async {
    final data = await Supabase.instance.client.rpc('get_workspace_setup_progress');
    return Map<String, dynamic>.from(data as Map);
  }

  Future<void> _open(String route) async {
    if (!RoleService.instance.canAccess(route)) return;
    if (route == '/purchases' && widget.onNewPurchase != null) {
      await widget.onNewPurchase!();
    } else {
      await Navigator.pushNamed(context, route);
    }
    if (mounted) setState(() => _progress = _load());
  }

  @override
  Widget build(BuildContext context) {
    final actions = _actions.where((item) => RoleService.instance.canAccess(item.route));
    if (actions.isEmpty) return const SizedBox.shrink();
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('Espace de travail', style: Theme.of(context).textTheme.titleMedium)),
                PopupMenuButton<String>(
                  tooltip: 'Navigation par métier',
                  icon: const Icon(Icons.menu),
                  onSelected: _open,
                  itemBuilder: (_) => [
                    for (final action in actions)
                      PopupMenuItem(value: action.route, child: Text(action.title)),
                    if (RoleService.instance.canAccess('/settings-configuration'))
                      const PopupMenuItem(value: '/settings-configuration', child: Text('Paramètres')),
                  ],
                ),
              ],
            ),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final action in actions)
                  ActionChip(
                    avatar: Icon(action.icon, size: 18),
                    label: Text(action.title),
                    onPressed: () => _open(action.route),
                  ),
              ],
            ),
            FutureBuilder<Map<String, dynamic>>(
              future: _progress,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return TextButton.icon(
                    onPressed: () => setState(() => _progress = _load()),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Réessayer de charger la mise en route'),
                  );
                }
                if (!snapshot.hasData) return const LinearProgressIndicator();
                final progress = snapshot.data!;
                final tasks = _tasks;
                final done = tasks.where((task) => progress[task.key] == true).length;
                return ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text('Mise en route · $done/${tasks.length}'),
                  initiallyExpanded: done < tasks.length,
                  children: [
                    for (final task in tasks)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(progress[task.key] == true
                            ? Icons.check_circle_outline : Icons.radio_button_unchecked),
                        title: Text(task.title),
                        onTap: task.route.isNotEmpty && RoleService.instance.canAccess(task.route)
                            ? () => _open(task.route) : null,
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

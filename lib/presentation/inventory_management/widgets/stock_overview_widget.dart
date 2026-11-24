import 'package:flutter/material.dart';

import '../../../services/inventory_service.dart';
import '../../../services/role_service.dart';

class StockOverviewWidget extends StatefulWidget {
  const StockOverviewWidget({
    super.key,
    required this.warehouseId,
    this.alertsOnly = false,
  });

  final String? warehouseId;
  final bool alertsOnly;

  @override
  State<StockOverviewWidget> createState() => _StockOverviewWidgetState();
}

class _StockOverviewWidgetState extends State<StockOverviewWidget> {
  late Future<List<Map<String, dynamic>>> _stock = _fetch();
  String _query = '';

  Future<List<Map<String, dynamic>>> _fetch() =>
      InventoryService.instance.getStock(warehouseId: widget.warehouseId);

  Future<void> _refresh() async {
    final stock = _fetch();
    setState(() => _stock = stock);
    try {
      await stock;
    } catch (_) {
      // FutureBuilder displays the failure.
    }
  }

  bool _adjusting = false;

  Future<void> _adjust(Map<String, dynamic> row) async {
    if (_adjusting) return;
    var delta = '';
    var reason = '';
    final adjustment = await showDialog<(int, String)>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Ajuster le stock'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              keyboardType: const TextInputType.numberWithOptions(signed: true),
              decoration: const InputDecoration(labelText: 'Variation (+ ou −)'),
              onChanged: (value) => delta = value,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Motif'),
              onChanged: (value) => reason = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              final quantity = int.tryParse(delta.trim());
              final description = reason.trim();
              if (quantity == null || quantity == 0 || description.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Saisissez une variation non nulle et un motif.')),
                );
                return;
              }
              Navigator.pop(dialogContext, (quantity, description));
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    if (!mounted || adjustment == null || _adjusting) return;

    setState(() => _adjusting = true);
    try {
      await InventoryService.instance.createStockMovement(
        productId: row['product_id'] as String,
        warehouseId: row['warehouse_id'] as String,
        quantity: adjustment.$1,
        movementType: 'adjustment',
        notes: adjustment.$2,
      );
      if (mounted) await _refresh();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ajustement refusé. Vérifiez le stock, le motif et vos droits.')),
        );
      }
    } finally {
      if (mounted) setState(() => _adjusting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      if (!widget.alertsOnly)
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            onChanged: (value) => setState(() => _query = value.trim().toLowerCase()),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Rechercher par nom ou référence',
            ),
          ),
        ),
      Expanded(
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _stock,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: TextButton(
                  onPressed: _refresh,
                  child: const Text('Stock indisponible. Réessayer'),
                ),
              );
            }
            final rows = (snapshot.data ?? []).where((row) {
              final product = row['products'] as Map?;
              final threshold = row['reorder_level'] as num?;
              if (widget.alertsOnly) {
                return threshold != null && (row['quantity'] as num) <= threshold;
              }
              return [product?['name'], product?['sku'], product?['barcode']]
                  .any((value) => (value?.toString().toLowerCase() ?? '').contains(_query));
            }).toList();
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  if (rows.isEmpty)
                    ListTile(title: Text(widget.alertsOnly
                        ? 'Aucune alerte de stock'
                        : 'Aucun produit trouvé')),
                  for (final row in rows)
                    ListTile(
                      leading: Icon(widget.alertsOnly ? Icons.warning_amber : Icons.inventory_2_outlined),
                      title: Text((row['products'] as Map?)?['name'] as String? ?? 'Produit'),
                      subtitle: Text([
                        (row['products'] as Map?)?['sku'],
                        (row['warehouse_locations'] as Map?)?['name'],
                        if (widget.alertsOnly) 'Seuil : ${row['reorder_level']}',
                      ].whereType<String>().join(' · ')),
                      trailing: Text('${row['quantity']}'),
                      onTap: !widget.alertsOnly &&
                              !_adjusting &&
                              RoleService.instance.canViewStockReports &&
                              row['product_id'] is String &&
                              row['warehouse_id'] is String
                          ? () => _adjust(row)
                          : null,
                    ),
                ],
              ),
            );
          },
        ),
      ),
    ],
  );
}

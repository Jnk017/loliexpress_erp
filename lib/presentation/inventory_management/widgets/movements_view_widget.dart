import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../services/inventory_service.dart';

class MovementsViewWidget extends StatefulWidget {
  const MovementsViewWidget({super.key, required this.warehouseId});

  final String? warehouseId;

  @override
  State<MovementsViewWidget> createState() => _MovementsViewWidgetState();
}

class _MovementsViewWidgetState extends State<MovementsViewWidget> {
  late Future<List<Map<String, dynamic>>> _movements = _fetch();

  Future<List<Map<String, dynamic>>> _fetch() => InventoryService.instance
      .getStockMovements(warehouseId: widget.warehouseId);

  Future<void> _refresh() async {
    final movements = _fetch();
    setState(() => _movements = movements);
    try {
      await movements;
    } catch (_) {
      // FutureBuilder displays the failure.
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<Map<String, dynamic>>>(
    future: _movements,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return Center(
          child: TextButton(
            onPressed: _refresh,
            child: const Text('Mouvements indisponibles. Réessayer'),
          ),
        );
      }
      final rows = snapshot.data ?? [];
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            if (rows.isEmpty) const ListTile(title: Text('Aucun mouvement enregistré')),
            for (final row in rows) _movementTile(row),
          ],
        ),
      );
    },
  );

  Widget _movementTile(Map<String, dynamic> row) {
    final date = DateTime.tryParse(row['created_at'] as String? ?? '')?.toLocal();
    final type = switch (row['movement_type']) {
      'in' => 'Entrée',
      'out' => 'Sortie',
      'adjustment' => 'Ajustement',
      'transfer' => 'Transfert',
      'return' => 'Retour',
      _ => row['movement_type'] as String,
    };
    return ListTile(
      title: Text((row['products'] as Map?)?['name'] as String? ?? 'Produit'),
      subtitle: Text([
        type,
        (row['warehouse_locations'] as Map?)?['name'],
        if (date != null) DateFormat('dd/MM/yyyy HH:mm').format(date),
        row['notes'],
      ].whereType<String>().join(' · ')),
      trailing: Text('${row['quantity']}'),
    );
  }
}

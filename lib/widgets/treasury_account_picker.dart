import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

typedef TreasuryAccount = ({String id, String kind});

Future<TreasuryAccount?> pickTreasuryAccount(
  BuildContext context,
  String currency, {
  required bool incoming,
}) async {
  final client = Supabase.instance.client;
  final accounts = Future.wait([
    client.from('cash_registers').select('id,name,current_balance')
        .eq('currency', currency).eq('is_active', true).order('name'),
    client.from('bank_accounts').select('id,account_name,current_balance')
        .eq('currency', currency).eq('is_active', true).order('account_name'),
  ]);
  return showDialog<TreasuryAccount>(
    context: context,
    builder: (dialogContext) => SimpleDialog(
      title: Text('${incoming ? 'Encaisser sur' : 'Payer depuis'} · $currency'),
      children: [
        FutureBuilder<List<List<Map<String, dynamic>>>>(
          future: accounts,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const ListTile(title: Text('Impossible de charger les comptes.'));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final groups = snapshot.data!;
            if (groups.every((group) => group.isEmpty)) {
              return const ListTile(title: Text('Aucune caisse ou banque active dans cette devise.'));
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final group in groups.indexed)
                  for (final row in group.$2)
                    SimpleDialogOption(
                      onPressed: () => Navigator.pop(dialogContext, (
                        id: row['id'] as String,
                        kind: group.$1 == 0 ? 'cash' : 'bank',
                      )),
                      child: Text(
                        "${group.$1 == 0 ? 'Caisse : ${row['name']}' : 'Banque : ${row['account_name']}'} "
                        '· ${row['current_balance']} $currency',
                      ),
                    ),
              ],
            );
          },
        ),
        SimpleDialogOption(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Annuler'),
        ),
      ],
    ),
  );
}

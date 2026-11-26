import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

typedef TreasuryAccount = ({String id, String kind, String method});

Future<TreasuryAccount?> pickTreasuryAccount(
  BuildContext context,
  String currency, {
  required bool incoming,
  bool includeMobileMoney = false,
}) async {
  final client = Supabase.instance.client;
  final accounts = Future.wait([
    client.from('cash_registers').select('id,name,current_balance')
        .eq('currency', currency).eq('is_active', true).order('name'),
    client.from('bank_accounts').select('id,account_name,current_balance,account_channel')
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
            final methods = {
              'cash': 'Cash (espèces)',
              if (includeMobileMoney) 'mobile_money': 'Mobile Money',
              'bank_transfer': 'Virement bancaire',
            };
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final method in methods.entries)
                  _accountGroup(
                    dialogContext,
                    title: method.value,
                    currency: currency,
                    method: method.key,
                    rows: method.key == 'cash'
                        ? groups[0]
                        : groups[1].where((row) => row['account_channel'] == method.key).toList(),
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

Widget _accountGroup(
  BuildContext context, {
  required String title,
  required String currency,
  required String method,
  required List<Map<String, dynamic>> rows,
}) {
  final cash = method == 'cash';
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
        child: Text(title, style: Theme.of(context).textTheme.titleSmall),
      ),
      if (rows.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 4),
          child: Text('Aucun compte actif dans cette devise.'),
        ),
      for (final row in rows)
        SimpleDialogOption(
          onPressed: () => Navigator.pop(context, (
            id: row['id'] as String,
            kind: cash ? 'cash' : 'bank',
            method: method,
          )),
          child: Text("${row[cash ? 'name' : 'account_name']} · ${row['current_balance']} $currency"),
        ),
    ],
  );
}

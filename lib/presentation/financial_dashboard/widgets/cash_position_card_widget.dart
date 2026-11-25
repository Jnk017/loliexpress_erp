import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CashPositionCardWidget extends StatelessWidget {
  const CashPositionCardWidget({super.key, required this.data, this.onTap});

  final Map<String, dynamic> data;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final format = NumberFormat('#,##0.00', 'fr');
    final cash = data['cash'] as Map<String, num>?;
    final bank = data['bank'] as Map<String, num>?;
    final mobile = data['mobileMoney'] as Map<String, num>?;
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Caisse et banque', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              if (cash == null || bank == null || mobile == null)
                Text(data['unavailable'] == true
                    ? 'Soldes indisponibles'
                    : 'Chargement des soldes…')
              else
                for (final currency in ['CDF', 'USD'])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '$currency\nCaisse ${format.format(cash[currency] ?? 0)}\n'
                      'Banque ${format.format(bank[currency] ?? 0)}\n'
                      'Mobile Money ${format.format(mobile[currency] ?? 0)}',
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

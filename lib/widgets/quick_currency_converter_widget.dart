import 'package:flutter/material.dart';

import '../services/currency_service.dart';

class QuickCurrencyConverterWidget extends StatefulWidget {
  const QuickCurrencyConverterWidget({super.key});

  @override
  State<QuickCurrencyConverterWidget> createState() =>
      _QuickCurrencyConverterWidgetState();
}

class _QuickCurrencyConverterWidgetState
    extends State<QuickCurrencyConverterWidget> {
  final _controller = TextEditingController();
  String _from = 'CDF';
  String _to = 'USD';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final amount = double.tryParse(_controller.text.replaceAll(',', '.')) ?? 0;
    final converted = CurrencyService.instance.convert(amount, _from, _to);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Convertisseur rapide'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Montant'),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                _currencyDropdown(_from, (value) {
                  if (value != null) setState(() => _from = value);
                }),
                const SizedBox(width: 8),
                _currencyDropdown(_to, (value) {
                  if (value != null) setState(() => _to = value);
                }),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${converted.toStringAsFixed(_to == 'USD' ? 2 : 0)} $_to',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _currencyDropdown(String value, ValueChanged<String?> onChanged) {
    return DropdownButton<String>(
      value: value,
      items: CurrencyService.supportedCurrencies
          .map((currency) => DropdownMenuItem(
                value: currency,
                child: Text(currency),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/request_id.dart';

Future<bool> showTreasuryAccountForm(BuildContext context) async =>
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _TreasuryAccountForm(),
    ) ??
    false;

class _TreasuryAccountForm extends StatefulWidget {
  const _TreasuryAccountForm();

  @override
  State<_TreasuryAccountForm> createState() => _TreasuryAccountFormState();
}

class _TreasuryAccountFormState extends State<_TreasuryAccountForm> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _provider = TextEditingController();
  final _opening = TextEditingController();
  final _requestId = newRequestId();
  String _method = 'cash';
  String _currency = 'CDF';
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _provider.dispose();
    _opening.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await Supabase.instance.client.rpc('open_treasury_account', params: {
        'p_request_id': _requestId,
        'p_method': _method,
        'p_name': _name.text.trim(),
        'p_provider': _method == 'cash' ? null : _provider.text.trim(),
        'p_currency': _currency,
        'p_opening': _opening.text.trim().replaceAll(',', '.'),
      });
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Création non confirmée. Réessayez avec les mêmes valeurs.';
      });
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    scrollable: true,
    title: const Text('Ouvrir un compte de trésorerie'),
    content: Form(
      key: _form,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _method,
            decoration: const InputDecoration(labelText: 'Type de compte'),
            items: const [
              DropdownMenuItem(value: 'cash', child: Text('Caisse')),
              DropdownMenuItem(value: 'bank_transfer', child: Text('Banque')),
              DropdownMenuItem(value: 'mobile_money', child: Text('Mobile Money')),
            ],
            onChanged: _saving ? null : (value) => setState(() => _method = value!),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _name,
            enabled: !_saving,
            maxLength: 100,
            decoration: const InputDecoration(labelText: 'Nom du compte'),
            validator: (value) => value!.trim().isEmpty ? 'Saisissez un nom.' : null,
          ),
          if (_method != 'cash')
            TextFormField(
              controller: _provider,
              enabled: !_saving,
              maxLength: 100,
              decoration: InputDecoration(
                labelText: _method == 'mobile_money' ? 'Opérateur' : 'Banque',
              ),
              validator: (value) => value!.trim().isEmpty ? 'Saisissez le nom.' : null,
            ),
          DropdownButtonFormField<String>(
            initialValue: _currency,
            decoration: const InputDecoration(labelText: 'Devise'),
            items: const [
              DropdownMenuItem(value: 'CDF', child: Text('CDF')),
              DropdownMenuItem(value: 'USD', child: Text('USD')),
            ],
            onChanged: _saving ? null : (value) => setState(() => _currency = value!),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _opening,
            enabled: !_saving,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Solde d’ouverture',
              helperText: 'Saisissez le solde réel, y compris 0 si le compte est vide.',
              helperMaxLines: 2,
            ),
            validator: (value) =>
                RegExp(r'^\d{1,16}([.,]\d{1,2})?$').hasMatch(value!.trim())
                    ? null
                    : 'Saisissez un montant positif ou nul.',
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: _saving ? null : () => Navigator.pop(context, false),
        child: const Text('Annuler'),
      ),
      FilledButton(
        onPressed: _saving ? null : _save,
        child: Text(_saving ? 'Enregistrement…' : 'Créer le compte'),
      ),
    ],
  );
}

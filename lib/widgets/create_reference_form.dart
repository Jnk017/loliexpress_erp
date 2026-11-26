import 'package:flutter/material.dart';

Future<bool> showCreateReferenceForm(
  BuildContext context, {
  required String title,
  required Future<void> Function(String name, String? address) save,
}) async {
  var name = '';
  var address = '';
  String? error;
  var saving = false;
  return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => StatefulBuilder(
          builder: (context, update) => AlertDialog(
            scrollable: true,
            title: Text(title),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  enabled: !saving,
                  maxLength: 100,
                  decoration: const InputDecoration(labelText: 'Nom'),
                  onChanged: (value) => name = value.trim(),
                ),
                TextField(
                  enabled: !saving,
                  maxLength: 250,
                  decoration: const InputDecoration(labelText: 'Adresse (facultative)'),
                  onChanged: (value) => address = value.trim(),
                ),
                if (error != null) Text(error!),
              ],
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: saving ? null : () async {
                  if (name.isEmpty) {
                    update(() => error = 'Saisissez le nom.');
                    return;
                  }
                  update(() { saving = true; error = null; });
                  try {
                    await save(name, address.isEmpty ? null : address);
                    if (context.mounted) Navigator.pop(context, true);
                  } catch (_) {
                    if (context.mounted) {
                      update(() {
                        saving = false;
                        error = 'Enregistrement non confirmé. Réessayez.';
                      });
                    }
                  }
                },
                child: Text(saving ? 'Enregistrement…' : 'Créer'),
              ),
            ],
          ),
        ),
      ) ??
      false;
}

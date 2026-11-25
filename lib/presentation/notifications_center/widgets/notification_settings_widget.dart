import 'package:flutter/material.dart';

import '../../../services/notification_service.dart';

class NotificationSettingsWidget extends StatefulWidget {
  const NotificationSettingsWidget({super.key, required this.service});

  final NotificationService service;

  @override
  State<NotificationSettingsWidget> createState() =>
      _NotificationSettingsWidgetState();
}

class _NotificationSettingsWidgetState extends State<NotificationSettingsWidget> {
  Set<String>? _hiddenTypes;
  bool _busy = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final types = await widget.service.loadCenterPreferences();
      if (mounted) setState(() => _hiddenTypes = types);
    } catch (_) {
      if (mounted) setState(() => _error = 'Réglages indisponibles.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    final types = _hiddenTypes;
    if (_busy || types == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.service.saveCenterPreferences(types);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Impossible d’enregistrer les réglages. Réessayez.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hiddenTypes = _hiddenTypes;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Notifications dans l’application',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text('Choisissez les types à afficher dans ce centre.'),
            if (_busy) const LinearProgressIndicator(),
            if (_error case final error?) Text(error),
            if (hiddenTypes == null && !_busy)
              TextButton(onPressed: _load, child: const Text('Réessayer')),
            if (hiddenTypes != null) ...[
              for (final type in NotificationService.centerTypes.entries)
                CheckboxListTile(
                  title: Text(type.value),
                  value: !hiddenTypes.contains(type.key),
                  onChanged: _busy
                      ? null
                      : (visible) => setState(() {
                            if (visible == true) {
                              hiddenTypes.remove(type.key);
                            } else {
                              hiddenTypes.add(type.key);
                            }
                          }),
                ),
              FilledButton(
                onPressed: _busy ? null : _save,
                child: const Text('Enregistrer'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

/// Bottom sheet for notification settings and preferences
class NotificationSettingsWidget extends StatefulWidget {
  const NotificationSettingsWidget({Key? key}) : super(key: key);

  @override
  State<NotificationSettingsWidget> createState() =>
      _NotificationSettingsWidgetState();
}

class _NotificationSettingsWidgetState
    extends State<NotificationSettingsWidget> {
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _smsNotifications = false;
  bool _quietHoursEnabled = false;
  TimeOfDay _quietHoursStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _quietHoursEnd = const TimeOfDay(hour: 7, minute: 0);

  final Map<String, bool> _notificationTypes = {
    'Nouvelles commandes': true,
    'Stock faible': true,
    'Paiements reçus': true,
    'Factures échues': true,
    'Livraisons': true,
    'Alertes système': true,
  };

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _quietHoursStart : _quietHoursEnd,
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _quietHoursStart = picked;
        } else {
          _quietHoursEnd = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Paramètres de Notifications',
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          SizedBox(height: 2.h),

          // Delivery methods
          Text(
            'Méthodes de livraison',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SwitchListTile(
            title: const Text('Notifications Email'),
            subtitle: const Text('Recevoir les alertes par email'),
            value: _emailNotifications,
            onChanged: (value) => setState(() => _emailNotifications = value),
          ),
          SwitchListTile(
            title: const Text('Notifications Push'),
            subtitle: const Text('Recevoir les alertes dans l\'application'),
            value: _pushNotifications,
            onChanged: (value) => setState(() => _pushNotifications = value),
          ),
          SwitchListTile(
            title: const Text('Notifications SMS'),
            subtitle: const Text('Recevoir les alertes critiques par SMS'),
            value: _smsNotifications,
            onChanged: (value) => setState(() => _smsNotifications = value),
          ),

          Divider(height: 3.h),

          // Quiet hours
          Text(
            'Heures silencieuses',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SwitchListTile(
            title: const Text('Activer les heures silencieuses'),
            subtitle: const Text(
              'Désactiver les notifications pendant ces heures',
            ),
            value: _quietHoursEnabled,
            onChanged: (value) => setState(() => _quietHoursEnabled = value),
          ),
          if (_quietHoursEnabled) ...[
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Début'),
              trailing: TextButton(
                onPressed: () => _selectTime(context, true),
                child: Text(
                  '${_quietHoursStart.hour.toString().padLeft(2, '0')}:${_quietHoursStart.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(fontSize: 14.sp),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Fin'),
              trailing: TextButton(
                onPressed: () => _selectTime(context, false),
                child: Text(
                  '${_quietHoursEnd.hour.toString().padLeft(2, '0')}:${_quietHoursEnd.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(fontSize: 14.sp),
                ),
              ),
            ),
          ],

          Divider(height: 3.h),

          // Notification types
          Text(
            'Types de notifications',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 1.h),
          ..._notificationTypes.entries.map((entry) {
            return CheckboxListTile(
              title: Text(entry.key),
              value: entry.value,
              onChanged: (value) {
                setState(() {
                  _notificationTypes[entry.key] = value ?? false;
                });
              },
            );
          }).toList(),

          SizedBox(height: 2.h),

          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // TODO: Save settings to backend
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Paramètres enregistrés avec succès'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 1.5.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              child: Text(
                'Enregistrer les paramètres',
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          SizedBox(height: 2.h),
        ],
      ),
    );
  }
}

import './supabase_service.dart';

/// Service for managing notifications and workflow automation
class NotificationService {
  final _client = SupabaseService.instance.client;

  // Resend API key from environment
  static const String _resendApiKey = String.fromEnvironment('RESEND_API_KEY');

  static const centerTypes = <String, String>{
    'new_order': 'Nouvelles commandes',
    'low_stock': 'Stock faible',
    'payment_received': 'Paiements reçus',
    'overdue_invoice': 'Factures échues',
    'order_delivered': 'Livraisons effectuées',
  };

  Future<Set<String>> loadCenterPreferences() async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('Session indisponible');
    final row = await _client
        .from('notification_center_preferences')
        .select('hidden_types')
        .eq('user_id', user.id)
        .maybeSingle();
    return (row?['hidden_types'] as List? ?? const []).cast<String>().toSet();
  }

  Future<void> saveCenterPreferences(Set<String> hiddenTypes) async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('Session indisponible');
    await _client.from('notification_center_preferences').upsert({
      'user_id': user.id,
      'hidden_types': hiddenTypes.toList(),
    });
  }

  /// Get notifications for current user
  Future<List<Map<String, dynamic>>> getUserNotifications({
    int limit = 50,
    String? status,
    Set<String> hiddenTypes = const {},
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return [];

      // Build query with proper chaining to avoid type conflicts
      final baseQuery = _client
          .from('notification_queue')
          .select('*')
          .eq('recipient_id', user.id);

      // Apply optional status filter
      final filteredQuery =
          status != null ? baseQuery.eq('status', status) : baseQuery;

      // Apply ordering and limit
      final excluded = centerTypes.keys.where(hiddenTypes.contains).toList();
      final visibleQuery = excluded.isEmpty
          ? filteredQuery
          : filteredQuery.not('notification_type', 'in', "(${excluded.join(',')})");

      final response = await visibleQuery
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch notifications: $e');
    }
  }

  /// Get unread notification count
  Future<int> getUnreadCount() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return 0;

      final response = await _client
          .from('notification_queue')
          .select('id')
          .eq('recipient_id', user.id)
          .eq('status', 'pending')
          .count();

      return response.count;
    } catch (e) {
      return 0;
    }
  }

  /// Subscribe to real-time notifications
  Stream<Map<String, dynamic>> subscribeToNotifications() {
    final user = _client.auth.currentUser;
    if (user == null) {
      return Stream.empty();
    }

    return _client
        .from('notification_queue')
        .stream(primaryKey: ['id'])
        .eq('recipient_id', user.id)
        .map((data) => data.isNotEmpty ? data.first : {});
  }

  /// Mark notification as read (sent)
  Future<void> markAsRead(String notificationId) async {
    try {
      await _client.from('notification_queue').update({
        'status': 'sent',
        'sent_at': DateTime.now().toIso8601String()
      }).eq('id', notificationId);
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  /// Send email notification via Resend API
  Future<void> sendEmailNotification({
    required String to,
    required String subject,
    required String htmlContent,
  }) async {
    if (_resendApiKey.isEmpty) {
      throw Exception(
          'RESEND_API_KEY is not configured in environment variables');
    }

    // Note: Actual email sending would be implemented in a backend/edge function
    // This is a placeholder for the client-side service structure
    throw UnimplementedError(
        'Email sending should be implemented in a Supabase Edge Function or backend service');
  }

  /// Create a custom notification
  Future<String> createNotification({
    required String recipientId,
    required String recipientEmail,
    required String notificationType,
    required String subject,
    required String message,
    String channel = 'both',
    String? relatedEntityType,
    String? relatedEntityId,
  }) async {
    try {
      final response = await _client
          .from('notification_queue')
          .insert({
            'notification_type': notificationType,
            'recipient_id': recipientId,
            'recipient_email': recipientEmail,
            'channel': channel,
            'subject': subject,
            'message': message,
            'related_entity_type': relatedEntityType,
            'related_entity_id': relatedEntityId,
          })
          .select()
          .single();

      return response['id'];
    } catch (e) {
      throw Exception('Failed to create notification: $e');
    }
  }

  /// Get notification templates
  Future<List<Map<String, dynamic>>> getNotificationTemplates() async {
    try {
      final response = await _client
          .from('notification_templates')
          .select('*')
          .order('notification_type');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch notification templates: $e');
    }
  }

  /// Get notification template by type
  Future<Map<String, dynamic>?> getTemplateByType(
      String notificationType) async {
    try {
      final response = await _client
          .from('notification_templates')
          .select('*')
          .eq('notification_type', notificationType)
          .maybeSingle();

      return response;
    } catch (e) {
      return null;
    }
  }

  /// Format notification message with variables
  String formatMessage(String template, Map<String, dynamic> variables) {
    String formatted = template;
    variables.forEach((key, value) {
      formatted = formatted.replaceAll('{$key}', value.toString());
    });
    return formatted;
  }
}

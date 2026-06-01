import 'package:supabase_flutter/supabase_flutter.dart';

class SupportService {
  static SupportService? _instance;
  static SupportService get instance => _instance ??= SupportService._();
  SupportService._();

  SupabaseClient get _client => Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getMyTickets() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return [];
      final response = await _client
          .from('support_tickets')
          .select('*')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Erreur lors du chargement des tickets: $e');
    }
  }

  Future<Map<String, dynamic>> createTicket({
    required String subject,
    required String message,
    String priority = 'normal',
    String? customerId,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('Utilisateur non authentifié');
      final response = await _client
          .from('support_tickets')
          .insert({
            'user_id': user.id,
            if (customerId != null) 'customer_id': customerId,
            'subject': subject,
            'message': message,
            'priority': priority,
          })
          .select()
          .single();
      return response;
    } catch (e) {
      throw Exception('Erreur lors de la création du ticket: $e');
    }
  }
}

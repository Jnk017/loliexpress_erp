import 'package:supabase_flutter/supabase_flutter.dart';

class AiAssistantService {
  static AiAssistantService? _instance;
  static AiAssistantService get instance =>
      _instance ??= AiAssistantService._();
  AiAssistantService._();

  SupabaseClient get _client => Supabase.instance.client;

  Future<String> ask(String question) async {
    final response = await _client.functions.invoke(
      'ai-assistant',
      body: {'question': question},
    );
    final data = response.data;
    if (data is Map && data['answer'] != null) {
      return data['answer'] as String;
    }
    throw Exception('Réponse IA invalide');
  }
}

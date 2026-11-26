import 'package:supabase_flutter/supabase_flutter.dart';

class CompanySettingsService {
  const CompanySettingsService();

  SupabaseClient get _client => Supabase.instance.client;

  Future<Map<String, dynamic>> load() async {
    final result = await _client.rpc('get_company_settings');
    return Map<String, dynamic>.from(result as Map);
  }

  Future<Map<String, dynamic>> save(Map<String, dynamic> patch) async {
    final result = await _client.rpc('update_company_settings', params: {
      'p_patch': patch,
    });
    return Map<String, dynamic>.from(result as Map);
  }
}

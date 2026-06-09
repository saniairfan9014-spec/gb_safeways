import '../../core/services/supabase_client.dart';

class RoleService {
  static Future<String> getRole(String userId) async {
    final client = SupabaseService.instance.client;
    
    // Fallback if Supabase is offline/not initialized
    if (client == null) {
      return 'user';
    }

    try {
      final res = await client
          .from('users')
          .select('role')
          .eq('id', userId)
          .single();

      return res['role'] as String? ?? 'user';
    } catch (e) {
      return 'user';
    }
  }
}

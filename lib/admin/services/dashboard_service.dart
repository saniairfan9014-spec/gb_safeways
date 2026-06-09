import '../../core/services/supabase_client.dart';

class DashboardService {
  final supabase = SupabaseService.instance.client;

  // 👥 Users Count
  Future<int> getUsersCount() async {
    if (supabase == null) return 0;
    try {
      final data = await supabase!.from('users').select('id');
      return data.length;
    } catch (e) {
      return 0;
    }
  }

  // 🚨 SOS Count
  Future<int> getSosCount() async {
    if (supabase == null) return 0;
    try {
      final data = await supabase!.from('emergency_requests').select('id');
      return data.length;
    } catch (e) {
      return 0;
    }
  }

  // 🛣 Roads Count
  Future<int> getRoadsCount() async {
    if (supabase == null) return 0;
    try {
      final data = await supabase!.from('roads').select('id');
      return data.length;
    } catch (e) {
      return 0;
    }
  }

  // 📢 Reports Count
  Future<int> getReportsCount() async {
    if (supabase == null) return 0;
    try {
      final data = await supabase!.from('reports').select('id');
      return data.length;
    } catch (e) {
      return 0;
    }
  }
}

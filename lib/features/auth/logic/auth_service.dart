import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<String?> loginAndGetRole(String email, String password) async {
    try {
      final AuthResponse res = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = res.user;
      if (user == null) return null;

      // Pastikan nama tabel di sini adalah 'users'
      final data = await _supabase
          .from('users') 
          .select('role')
          .eq('id', user.id)
          .single();

      return data['role'] as String; 
    } catch (e) {
      print("DEBUG_ERROR_AUTH: $e"); // Ini akan muncul di terminal jika error
      return null;
    }
  }
}
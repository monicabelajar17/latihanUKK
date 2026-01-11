import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Tambahkan ini
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_assets.dart';

class LoginScreen extends StatefulWidget { // Ubah ke StatefulWidget agar bisa pakai Controller
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // 1. Tambahkan Controller untuk mengambil input
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  // 2. Fungsi Login & Cek Role ke Supabase
  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);
    
    try {
      final supabase = Supabase.instance.client;

      // Auth login
      final AuthResponse res = await supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (res.user != null) {
        // Ambil data role dari tabel 'profiles' (sesuaikan nama tabel Anda)
        final data = await supabase
            .from('users')
            .select('role')
            .eq('id', res.user!.id)
            .single();

        String role = data['role'];

        if (!mounted) return;

        // Navigasi berdasarkan role
        if (role.toLowerCase() == 'admin') {
          Navigator.pushReplacementNamed(context, '/admin_product');
        } else {
          Navigator.pushReplacementNamed(context, '/petugas_product');
        }
      }
    } on AuthException catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message), backgroundColor: Colors.red),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Terjadi kesalahan tak terduga"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: MediaQuery.of(context).size.height * 0.45,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.primaryPurple,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(160),
                  bottomRight: Radius.circular(160),
                ),
              ),
              child: const Center(
                child: Image(image: AssetImage(AppAssets.logo), width: 150),
              ),
            ),
            const SizedBox(height: 50),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  // Masukkan controller ke textfield
                  _buildTextField(
                    label: "Email", 
                    hint: "Masukkan Email", 
                    controller: _emailController
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    label: "Password", 
                    hint: "Masukkan Password", 
                    isPassword: true,
                    controller: _passwordController
                  ),
                  const SizedBox(height: 40),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryPurple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      // Tampilkan loading jika sedang proses
                      onPressed: _isLoading ? null : _handleLogin,
                      child: _isLoading 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "LOGIN",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label, 
    required String hint, 
    required TextEditingController controller, // Tambahkan parameter controller
    bool isPassword = false
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryPurple)),
        const SizedBox(height: 8),
        TextField(
          controller: controller, // Hubungkan di sini
          obscureText: isPassword,
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: isPassword ? const Icon(Icons.visibility_off_outlined) : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primaryPurple),
            ),
          ),
        ),
      ],
    );
  }
}
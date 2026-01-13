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
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isLoading = false;
  // 1. Tambahkan variabel state untuk mengontrol visibilitas password
  bool _obscureText = true; 

  Future<void> _handleLogin() async {
    // Validasi sederhana sebelum ke server
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email dan password tidak boleh kosong"), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final supabase = Supabase.instance.client;

      final AuthResponse res = await supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (res.user != null) {
        final data = await supabase
            .from('users')
            .select('role')
            .eq('id', res.user!.id)
            .single();

        String role = data['role'];

        if (!mounted) return;

        if (role.toLowerCase() == 'admin') {
          Navigator.pushReplacementNamed(context, '/admin_product');
        } else {
          Navigator.pushReplacementNamed(context, '/petugas_product');
        }
      }
    } on AuthException catch (error) {
      // 2. Tampilkan pesan kesalahan spesifik jika email/password salah
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Terjadi kesalahan input email/password"), 
          backgroundColor: Colors.red
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Terjadi kesalahan jaringan"), backgroundColor: Colors.red),
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
            // ... (Bagian Header Logo tetap sama)
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
                  _buildTextField(
                    label: "Email", 
                    hint: "Masukkan Email", 
                    controller: _emailController
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    label: "Password", 
                    hint: "Masukkan Password", 
                    isPassword: true, // Beritahu widget ini adalah field password
                    controller: _passwordController
                  ),
                  const SizedBox(height: 40),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryPurple,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
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

  // 3. Modifikasi fungsi helper _buildTextField
  Widget _buildTextField({
    required String label, 
    required String hint, 
    required TextEditingController controller,
    bool isPassword = false
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryPurple)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          // Gunakan state _obscureText hanya jika isPassword bernilai true
          obscureText: isPassword ? _obscureText : false,
          decoration: InputDecoration(
            hintText: hint,
            // Tambahkan tombol mata (IconButton) jika field adalah password
            suffixIcon: isPassword 
              ? IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: AppColors.primaryPurple,
                  ),
                  onPressed: () {
                    // Toggle status sembunyi/lihat password
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                ) 
              : null,
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
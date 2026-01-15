import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Import Supabase
import 'features/auth/ui/splash_screen.dart';
import 'features/auth/ui/login_screen.dart';
import 'features/product/ui/product_list_screen.dart';
import 'features/settings/settings_screen.dart';

void main() async {
  // 1. Pastikan binding Flutter sudah siap
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Inisialisasi Supabase
  await Supabase.initialize(
    url: 'https://wnufpjdkcggjdbsvjbws.supabase.co',
    anonKey: 'sb_publishable_0qAEpWJzIXds-vl2m2QbmA_JQG_jwZi',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Branpos App',
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        // Route untuk masing-masing role
        '/admin_product': (context) => const ProductListScreen(role: 'Admin'),
        '/petugas_product': (context) => const ProductListScreen(role: 'Petugas'),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}
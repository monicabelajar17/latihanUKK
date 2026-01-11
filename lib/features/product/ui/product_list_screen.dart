import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';

class ProductListScreen extends StatefulWidget {
  final String role;

  const ProductListScreen({super.key, required this.role});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final _supabase = Supabase.instance.client;
  String _userName = "...";
  String _initial = "";
  String _selectedCategory = "All"; // Default kategori yang terpilih

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        final data = await _supabase
            .from('users')
            .select('nama')
            .eq('id', user.id)
            .single();

        String namaLengkap = data['nama'] ?? "User";

        setState(() {
          _userName = namaLengkap;
          _initial = namaLengkap.isNotEmpty ? namaLengkap[0].toUpperCase() : "?";
        });
      }
    } catch (e) {
      debugPrint("Error loading profile: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/settings'),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  color: AppColors.primaryPurple,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _initial,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _userName,
                    style: const TextStyle(
                        color: AppColors.primaryPurple,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    widget.role,
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 1. Banner Detail Produk
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primaryPurple,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                children: [
    // Menggunakan Image Asset sebagai pengganti Icon
    Image.asset(
      'assets/images/dokumen.png', // Sesuaikan dengan nama file Anda
      width: 80,
      height: 80,
      fit: BoxFit.contain,
    ),
    const SizedBox(width: 15),
    const Text(
      "Detail Produk",
      style: TextStyle(
        color: Colors.white,
        fontSize: 28,
        fontWeight: FontWeight.bold,
      ),
    ),
  ],
),
            ),
            const SizedBox(height: 25),

            // 2. Search Bar
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromARGB(255, 53, 53, 53),
                    blurRadius: 5,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: "Cari nama barang.....",
                  hintStyle: TextStyle(color: Colors.grey),
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
            const SizedBox(height: 25),

            // 3. Kategori Produk (Horizontal List)
            SizedBox(
              height: 45,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildCategoryItem("All"),
                  _buildCategoryItem("Buku"),
                  _buildCategoryItem("Pensil"),
                  _buildCategoryItem("Bolpoint"),
                  _buildCategoryItem("Crayon"),
                  _buildCategoryItem("Penghapus"),
                  _buildCategoryItem("Penggaris"),
                  _buildCategoryItem("Lainnya"), 
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            // Tempat untuk Grid Produk nantinya
            const Center(child: Text("Daftar produk akan muncul di sini")),
          ],
        ),
      ),
    );
  }

  // Widget bantuan untuk Kategori
  Widget _buildCategoryItem(String title) {
  // Cek apakah judul ini sama dengan kategori yang sedang dipilih
  bool isSelected = _selectedCategory == title;

  return GestureDetector(
    onTap: () {
      setState(() {
        _selectedCategory = title; // Ubah kategori aktif saat diklik
      });
    },
    child: Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 25),
      decoration: BoxDecoration(
        // Jika terpilih warna ungu, jika tidak warna ungu muda
        color: isSelected ? AppColors.primaryPurple : Colors.purple[50],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Text(
          title,
          style: TextStyle(
            // Jika terpilih teks putih, jika tidak teks ungu
            color: isSelected ? Colors.white : AppColors.primaryPurple,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ),
  );
}
}
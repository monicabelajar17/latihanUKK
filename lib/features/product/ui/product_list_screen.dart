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

  // Di dalam class _ProductListScreenState
Future<List<Map<String, dynamic>>> _fetchProducts() async {
  try {
    var query = _supabase.from('produk').select('*, kategori(namakategori)');
    
    // Filter berdasarkan kategori jika bukan "All"
    if (_selectedCategory != "All") {
      query = query.eq('kategori.namakategori', _selectedCategory);
    }

    final data = await query;
    return List<Map<String, dynamic>>.from(data);
  } catch (e) {
    debugPrint("Error fetching products: $e");
    return [];
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
           // GANTI GridView lama dengan FutureBuilder ini
            const SizedBox(height: 25),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchProducts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text("Tidak ada produk di kategori ini"),
                  );
                }

                final products = snapshot.data!;

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final item = products[index];
                    return _buildProductCard(
                      title: item['namaproduk'] ?? 'Tanpa Nama',
                      price: "Rp. ${item['harga'] ?? 0}",
                      stock: "${item['stok'] ?? 0}",
                      imageUrl: item['gambar'], // URL dari Storage Supabase
                    );
                  },
                );
              },
            ),
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
Widget _buildProductCard({
  required String title,
  required String price,
  required String stock,
  String? imageUrl, // Gunakan String nullable
}) {
  return Container(
    decoration: BoxDecoration(
      color: const Color(0xFFF5F5F5),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: imageUrl != null && imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                  )
                : const Icon(Icons.image, size: 50, color: Colors.grey),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(
            color: AppColors.primaryPurple,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    price,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Stok : $stock",
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ],
              ),
              if (widget.role.toLowerCase() == 'admin')
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delete, color: Colors.red, size: 16),
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}
}
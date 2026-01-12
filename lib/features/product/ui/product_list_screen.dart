import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import 'product_detail_screen.dart';
import 'add_product_screen.dart';

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
  
  List<String> _categories = ["All"];
  String _selectedCategory = "All"; 
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadCategories();
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

  Future<void> _loadCategories() async {
    try {
      final data = await _supabase.from('kategori').select('namakategori');
      
      final List<String> fetchedCategories = ["All"];
      for (var item in data) {
        fetchedCategories.add(item['namakategori']);
      }

      setState(() {
        _categories = fetchedCategories;
      });
    } catch (e) {
      debugPrint("Error loading categories: $e");
    }
  }

  Future<List<Map<String, dynamic>>> _fetchProducts() async {
    try {
      var query = _supabase.from('produk').select('*, kategori(*)');

      if (_selectedCategory != "All") {
        query = query.eq('kategori.namakategori', _selectedCategory);
      }

      final data = await query;
      
      List<Map<String, dynamic>> products = List<Map<String, dynamic>>.from(data);

      // Filter kategori di sisi client (karena join query Supabase)
      if (_selectedCategory != "All") {
        products = products.where((item) => 
          item['kategori'] != null && 
          item['kategori']['namakategori'] == _selectedCategory
        ).toList();
      }

      // Filter Search Bar
      if (_searchController.text.isNotEmpty) {
        products = products.where((item) => 
          item['namaproduk'].toString().toLowerCase().contains(_searchController.text.toLowerCase())
        ).toList();
      }

      return products;
    } catch (e) {
      debugPrint("Error fetching products: $e");
      return [];
    }
  }

  Future<void> _deleteProduct(BuildContext context, int id) async {
    bool confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Konfirmasi Hapus"),
          content: const Text("Apakah anda yakin ingin menghapus produk ini?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Tidak", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPurple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Ya", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    ) ?? false;

    if (confirm) {
      try {
        await _supabase.from('produk').delete().eq('produkid', id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produk berhasil dihapus')),
        );
        setState(() {}); 
      } catch (e) {
        debugPrint("Error hapus: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: widget.role.toLowerCase() == 'admin'
          ? FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddProductScreen()),
                );
                if (result == true) {
                  setState(() {}); // Refresh list setelah tambah data
                }
              },
              backgroundColor: AppColors.primaryPurple,
              shape: const CircleBorder(),
              child: const Icon(Icons.add, color: Colors.pinkAccent, size: 30),
            )
          : null,
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
                width: 50, height: 50,
                decoration: const BoxDecoration(color: AppColors.primaryPurple, shape: BoxShape.circle),
                child: Center(
                  child: Text(_initial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_userName, style: const TextStyle(color: AppColors.primaryPurple, fontSize: 20, fontWeight: FontWeight.bold)),
                  Text(widget.role, style: const TextStyle(color: Colors.grey, fontSize: 14)),
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
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppColors.primaryPurple, borderRadius: BorderRadius.circular(25)),
              child: Row(
                children: [
                  Image.asset('assets/images/dokumen.png', width: 80, height: 80, fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.description, size: 80, color: Colors.white)),
                  const SizedBox(width: 15),
                  const Text("Detail Produk", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 25),
            Container(
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(30)),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: "Cari nama barang.....",
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
            const SizedBox(height: 25),
            SizedBox(
              height: 45,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                itemBuilder: (context, index) => _buildCategoryItem(_categories[index]),
              ),
            ),
            const SizedBox(height: 25),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchProducts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("Tidak ada produk"));
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
                      context: context,
                      item: item,
                      id: item['produkid'],
                      title: item['namaproduk'] ?? 'Tanpa Nama',
                      price: "Rp. ${item['harga'] ?? 0}",
                      stock: "${item['stok'] ?? 0}",
                      imageUrl: item['gambar'],
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

  Widget _buildCategoryItem(String title) {
    bool isSelected = _selectedCategory == title;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = title),
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 25),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryPurple : Colors.purple[50],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(title, style: TextStyle(color: isSelected ? Colors.white : AppColors.primaryPurple, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildProductCard({
    required BuildContext context,
    required Map<String, dynamic> item,
    required int id,
    required String title,
    required String price,
    required String stock,
    String? imageUrl,
  }) {
    return GestureDetector(
      onTap: () async {
        // PERUBAHAN DISINI: Tambahkan await dan setState
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(product: item),
          ),
        );

        // Jika kembali dari detail dan membawa hasil (misal: true), refresh UI
        if (result == true) {
          setState(() {}); 
        }
      },
      child: Container(
        decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? Image.network(imageUrl, fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 50, color: Colors.grey))
                    : const Icon(Icons.image, size: 50, color: Colors.grey),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: AppColors.primaryPurple,
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
              ),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(price, style: const TextStyle(color: Colors.white, fontSize: 12)),
                      const SizedBox(height: 2),
                      Text("Stok : $stock", style: const TextStyle(color: Colors.white, fontSize: 11)),
                    ],
                  ),
                  if (widget.role.toLowerCase() == 'admin')
                    Positioned(
                      right: 0, bottom: 0,
                      child: InkWell(
                        onTap: () => _deleteProduct(context, id),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(blurRadius: 2, color: Colors.black26)]),
                          child: const Icon(Icons.delete, color: Colors.red, size: 16),
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
}
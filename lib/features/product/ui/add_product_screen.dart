import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../../../core/constants/app_colors.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _supabase = Supabase.instance.client;
  final _picker = ImagePicker();

  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _hargaController = TextEditingController();
  final TextEditingController _stokController = TextEditingController();
  
  int? _selectedKategoriId;
  File? _selectedImageFile;
  Uint8List? _selectedImageBytes;
  
  bool _isLoading = false;
  List<Map<String, dynamic>> _kategoriList = [];

  @override
  void initState() {
    super.initState();
    _loadKategori();
  }

  Future<void> _loadKategori() async {
    try {
      final response = await _supabase.from('kategori').select().order('namakategori');
      setState(() {
        _kategoriList = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      debugPrint("Error load kategori: $e");
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        setState(() => _selectedImageBytes = bytes);
      } else {
        setState(() => _selectedImageFile = File(image.path));
      }
    }
  }

  Future<void> _saveProduct() async {
  // 1. Validasi Input
  if (_namaController.text.isEmpty || _hargaController.text.isEmpty || _selectedKategoriId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Mohon lengkapi data (Nama, Harga, dan Kategori)")),
    );
    return;
  }

  setState(() => _isLoading = true);

  try {
    String namaBaru = _namaController.text.trim();
    int inputStok = int.tryParse(_stokController.text) ?? 0;
    double inputHarga = double.tryParse(_hargaController.text) ?? 0;

    // 2. CEK APAKAH PRODUK SUDAH ADA (Berdasarkan Nama)
    final existingProduct = await _supabase
        .from('produk')
        .select()
        .eq('namaproduk', namaBaru)
        .maybeSingle(); // Mengambil satu data jika ada

    if (existingProduct != null) {
      // --- LOGIKA UPDATE STOK ---
      int stokLama = existingProduct['stok'] ?? 0;
      int idProduk = existingProduct['produkid'];

      await _supabase.from('produk').update({
        'stok': stokLama + inputStok, // Tambahkan stok lama dengan input baru
        'harga': inputHarga,         // Opsional: Update harga ke yang terbaru
      }).eq('produkid', idProduk);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Produk '$namaBaru' sudah ada. Stok berhasil ditambahkan!"),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } else {
      // --- LOGIKA TAMBAH DATA BARU (INSERT) ---
      String? imageUrl;

      // Proses Upload Foto (hanya jika tambah produk baru)
      if (_selectedImageFile != null || _selectedImageBytes != null) {
        final String fileName = 'prod_${DateTime.now().millisecondsSinceEpoch}.jpg';
        if (kIsWeb && _selectedImageBytes != null) {
          await _supabase.storage.from('Produk Image').uploadBinary(
            fileName,
            _selectedImageBytes!,
            fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
          );
        } else if (_selectedImageFile != null) {
          await _supabase.storage.from('Produk Image').upload(
            fileName,
            _selectedImageFile!,
            fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
          );
        }
        imageUrl = _supabase.storage.from('Produk Image').getPublicUrl(fileName);
      }

      await _supabase.from('produk').insert({
        'namaproduk': namaBaru,
        'harga': inputHarga,
        'stok': inputStok,
        'kategoriid': _selectedKategoriId,
        'gambar': imageUrl,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Produk baru berhasil ditambahkan!"), backgroundColor: Colors.green),
        );
      }
    }

    if (mounted) Navigator.pop(context, true);

  } catch (e) {
    debugPrint("Error: $e");
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Terjadi kesalahan: $e"), backgroundColor: Colors.red),
      );
    }
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}
  @override
  Widget build(BuildContext context) {
    const double imageSize = 180.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // BAGIAN HEADER DAN FOTO
            SizedBox(
              height: 310, // Memberikan ruang yang cukup untuk foto yang menonjol
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // Background Ungu Melengkung
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 220,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryPurple,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(100),
                          bottomRight: Radius.circular(100),
                        ),
                      ),
                    ),
                  ),
                  
                  // Tombol Back & Judul
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 10,
                    left: 10,
                    right: 10,
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Text(
                          "Tambah Produk Baru",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // WIDGET FOTO & TOMBOL KAMERA (Dipindahkan ke posisi yang aman untuk klik)
                  Positioned(
                    top: 110,
                    child: SizedBox(
                      width: imageSize,
                      height: imageSize,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Box Foto
                          Container(
                            width: imageSize,
                            height: imageSize,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                )
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(30),
                              child: _selectedImageBytes != null
                                  ? Image.memory(_selectedImageBytes!, fit: BoxFit.cover)
                                  : (_selectedImageFile != null
                                      ? Image.file(_selectedImageFile!, fit: BoxFit.cover)
                                      : const Icon(Icons.image, size: 80, color: Colors.grey)),
                            ),
                          ),
                          // Tombol Kamera
                          Positioned(
                            bottom: -5,
                            right: -5,
                            child: GestureDetector(
                              onTap: () {
                                debugPrint("Membuka Galeri...");
                                _pickImage();
                              },
                              child: Material(
                                elevation: 5,
                                shape: const CircleBorder(),
                                color: AppColors.primaryPurple,
                                child: const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // FORM INPUT
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildField("Nama Produk", _namaController, Icons.shopping_bag_outlined),
                  const SizedBox(height: 15),
                  _buildField("Harga", _hargaController, Icons.attach_money, isNumber: true),
                  const SizedBox(height: 15),
                  _buildField("Stok", _stokController, Icons.inventory_2_outlined, isNumber: true),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<int>(
                    value: _selectedKategoriId,
                    items: _kategoriList.map((k) => DropdownMenuItem(
                      value: k['kategoriid'] as int,
                      child: Text(k['namakategori'].toString()),
                    )).toList(),
                    onChanged: (val) => setState(() => _selectedKategoriId = val),
                    decoration: _inputDecoration("Kategori", Icons.category_outlined),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity, height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryPurple,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      onPressed: _isLoading ? null : _saveProduct,
                      child: _isLoading 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("SIMPAN PRODUK", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon, {bool isNumber = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: _inputDecoration(label, icon),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppColors.primaryPurple),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
    );
  }
}
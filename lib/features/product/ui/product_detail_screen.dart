import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
import '../../../core/constants/app_colors.dart';
import 'package:flutter/foundation.dart';

class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> product;
  final String userRole; // Tambahkan parameter userRole

  const ProductDetailScreen({
    super.key, 
    required this.product,
    required this.userRole, // Tambahkan parameter ini
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _namaController;
  late TextEditingController _hargaController;
  late TextEditingController _stokController;
  int? _selectedKategoriId;
  
  // Variabel untuk gambar
  String? _currentImageUrl;
  File? _selectedImageFile;
  Uint8List? _selectedImageBytes;
  bool _isUploadingImage = false;
  bool _isSaving = false;
  
  late bool _isReadOnly;
  List<Map<String, dynamic>> _kategoriList = [];

  @override
  void initState() {
    super.initState();
    // PERUBAHAN DISINI: Hanya admin yang bisa edit
    _isReadOnly = widget.userRole.toLowerCase() != 'admin';
    _initializeData();
    _loadKategori();
  }

  Future<void> _loadKategori() async {
    try {
      final response = await supabase
          .from('kategori')
          .select('kategoriid, namakategori')
          .order('namakategori');
      
      if (mounted) {
        setState(() {
          _kategoriList = List<Map<String, dynamic>>.from(response);
          // Sync id kategori dari data produk jika ada
          if (_selectedKategoriId == null && widget.product['kategoriid'] != null) {
            _selectedKategoriId = widget.product['kategoriid'];
          }
        });
      }
    } catch (e) {
      debugPrint("Error loading kategori: $e");
    }
  }

  void _initializeData() {
    setState(() {
      _namaController = TextEditingController(text: widget.product['namaproduk']?.toString() ?? "");
      _hargaController = TextEditingController(text: widget.product['harga']?.toString() ?? "0");
      _stokController = TextEditingController(text: widget.product['stok']?.toString() ?? "0");
      _selectedKategoriId = widget.product['kategoriid'];
      _currentImageUrl = widget.product['gambar'];
      _selectedImageFile = null;
      _selectedImageBytes = null;
    });
  }

  @override
  void dispose() {
    _namaController.dispose();
    _hargaController.dispose();
    _stokController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_isReadOnly) return; // Petugas tidak bisa pick image
    
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
          _selectedImageFile = File(image.name); 
        });
      } else {
        setState(() {
          _selectedImageFile = File(image.path);
        });
      }
    }
  }

  Future<String?> _uploadImage() async {
    if (_selectedImageFile == null && _selectedImageBytes == null) return _currentImageUrl;

    try {
      setState(() => _isUploadingImage = true);
      final fileName = 'prod_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      if (kIsWeb && _selectedImageBytes != null) {
        await supabase.storage.from('Produk Image').uploadBinary(fileName, _selectedImageBytes!);
      } else {
        await supabase.storage.from('Produk Image').upload(fileName, _selectedImageFile!);
      }

      return supabase.storage.from('Produk Image').getPublicUrl(fileName);
    } catch (e) {
      debugPrint("Upload error: $e");
      return _currentImageUrl;
    } finally {
      setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _updateProduct() async {
    if (_isSaving || _isReadOnly) return; // Tambahkan _isReadOnly check

    try {
      setState(() => _isSaving = true);

      // Validasi sederhana
      if (_namaController.text.isEmpty || _selectedKategoriId == null) {
        throw "Nama dan Kategori harus diisi";
      }

      // 1. Upload gambar jika ada yang baru
      String? finalImageUrl = _currentImageUrl;
      if (_selectedImageFile != null || _selectedImageBytes != null) {
        finalImageUrl = await _uploadImage();
      }

      // 2. Update ke Supabase
      await supabase.from('produk').update({
        'namaproduk': _namaController.text.trim(),
        'harga': double.tryParse(_hargaController.text) ?? 0,
        'stok': int.tryParse(_stokController.text) ?? 0,
        'kategoriid': _selectedKategoriId,
        'gambar': finalImageUrl,
      }).eq('produkid', widget.product['produkid']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Produk berhasil diperbarui"), backgroundColor: AppColors.primaryPurple)
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal: $e"), backgroundColor: Colors.red)
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    const double imageSize = 180.0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primaryPurple,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Detail Produk (${widget.userRole})", // Tampilkan role di title
          style: const TextStyle(color: Colors.white)
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Area Gambar
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 30),
              decoration: const BoxDecoration(
                color: AppColors.primaryPurple,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(50),
                  bottomRight: Radius.circular(50),
                ),
              ),
              child: Center(
                child: Stack(
                  children: [
                    Container(
                      width: imageSize,
                      height: imageSize,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: _isUploadingImage 
                          ? const Center(child: CircularProgressIndicator())
                          : _buildImageWidget(),
                      ),
                    ),
                    if (!_isReadOnly)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: FloatingActionButton.small(
                          backgroundColor: Colors.white,
                          onPressed: _pickImage,
                          child: const Icon(Icons.camera_alt, color: AppColors.primaryPurple),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(25),
              child: Column(
                children: [
                  _buildField("Nama Produk", _namaController, Icons.shopping_bag_outlined),
                  const SizedBox(height: 15),
                  _buildField("Harga", _hargaController, Icons.attach_money, isNumber: true),
                  const SizedBox(height: 15),
                  _buildField("Stok", _stokController, Icons.inventory_2_outlined, isNumber: true),
                  const SizedBox(height: 15),
                  
                  // Dropdown Kategori
                  DropdownButtonFormField<int>(
                    value: _selectedKategoriId,
                    items: _kategoriList.map((k) => DropdownMenuItem(
                      value: k['kategoriid'] as int,
                      child: Text(k['namakategori'].toString()),
                    )).toList(),
                    onChanged: _isReadOnly ? null : (val) => setState(() => _selectedKategoriId = val),
                    decoration: _inputDecoration("Kategori", Icons.category_outlined),
                  ),

                  const SizedBox(height: 35),

                  if (!_isReadOnly)
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryPurple,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        onPressed: _isSaving ? null : _updateProduct,
                        child: _isSaving 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("SIMPAN PERUBAHAN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

  Widget _buildImageWidget() {
    if (_selectedImageBytes != null) return Image.memory(_selectedImageBytes!, fit: BoxFit.cover);
    if (_selectedImageFile != null && !kIsWeb) return Image.file(_selectedImageFile!, fit: BoxFit.cover);
    if (_currentImageUrl != null && _currentImageUrl!.isNotEmpty) {
      return Image.network(_currentImageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 50));
    }
    return const Icon(Icons.image_not_supported, size: 50, color: Colors.grey);
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon, {bool isNumber = false}) {
    return TextFormField(
      controller: controller,
      enabled: !_isReadOnly,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: _inputDecoration(label, icon),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppColors.primaryPurple),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: AppColors.primaryPurple, width: 2),
      ),
    );
  }
}
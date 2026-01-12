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
    if (_namaController.text.isEmpty || _hargaController.text.isEmpty || _selectedKategoriId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mohon lengkapi data")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? imageUrl;

      // 1. Upload Gambar jika ada
      if (_selectedImageFile != null || _selectedImageBytes != null) {
        final fileName = 'prod_${DateTime.now().millisecondsSinceEpoch}.jpg';
        if (kIsWeb) {
          await _supabase.storage.from('Produk Image').uploadBinary(fileName, _selectedImageBytes!);
        } else {
          await _supabase.storage.from('Produk Image').upload(fileName, _selectedImageFile!);
        }
        imageUrl = _supabase.storage.from('Produk Image').getPublicUrl(fileName);
      }

      // 2. Insert ke Database
      await _supabase.from('produk').insert({
        'namaproduk': _namaController.text.trim(),
        'harga': double.parse(_hargaController.text),
        'stok': int.parse(_stokController.text),
        'kategoriid': _selectedKategoriId,
        'gambar': imageUrl,
      });

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Produk berhasil ditambahkan")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Terjadi kesalahan: $e")));
    } finally {
      setState(() => _isLoading = false);
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
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 220, width: double.infinity,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryPurple,
                    borderRadius: BorderRadius.only(bottomLeft: Radius.circular(100), bottomRight: Radius.circular(100)),
                  ),
                ),
                SafeArea(
                  child: Row(
                    children: [
                      IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
                      const Text("Tambah Produk Baru", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Positioned(
                  top: 110,
                  left: (MediaQuery.of(context).size.width - imageSize) / 2,
                  child: Stack(
                    children: [
                      Container(
                        width: imageSize, height: imageSize,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
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
                      Positioned(
                        bottom: 5, right: 5,
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: const CircleAvatar(
                            backgroundColor: AppColors.primaryPurple,
                            radius: 20,
                            child: Icon(Icons.camera_alt, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 100),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Column(
                children: [
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
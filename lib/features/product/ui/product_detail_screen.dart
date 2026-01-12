import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
import '../../../core/constants/app_colors.dart';
import 'package:flutter/foundation.dart';

class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _namaController;
  late TextEditingController _hargaController;
  late TextEditingController _stokController;
  String? _selectedKategori;
  
  // Variabel untuk gambar
  String? _currentImageUrl;
  File? _selectedImageFile;
  Uint8List? _selectedImageBytes;
  bool _isUploadingImage = false;
  
  // Flag untuk menentukan apakah user bisa edit (berdasarkan role)
  late bool _isReadOnly;
  
  // Daftar kategori (sebaiknya diambil dari database)
  final List<String> _kategoriList = ["Buku", "Pensil", "Pulpen", "Crayon"];

  @override
  void initState() {
    super.initState();
    // Jika role adalah 'petugas', maka field tidak bisa diedit
    _isReadOnly = widget.product['role'] == 'petugas';
    _currentImageUrl = widget.product['gambar'];
    _initializeData();
  }

  // Fungsi untuk mengisi atau mereset data ke kondisi awal
  void _initializeData() {
    setState(() {
      _namaController = TextEditingController(text: widget.product['namaproduk']);
      _hargaController = TextEditingController(text: widget.product['harga'].toString());
      _stokController = TextEditingController(text: widget.product['stok'].toString());
      _selectedKategori = widget.product['kategori']?['namakategori'] ?? "Buku";
      _currentImageUrl = widget.product['gambar'];
      _selectedImageFile = null;
    });
  }

  @override
  void dispose() {
    _namaController.dispose();
    _hargaController.dispose();
    _stokController.dispose();
    super.dispose();
  }

  // Fungsi untuk memilih gambar dari galeri
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80, // Kompresi kualitas gambar
        maxWidth: 1024, // Batasi lebar maksimal
      );
      if (image != null) {
      if (kIsWeb) {
        // Untuk web, ambil bytes langsung dari XFile
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImageFile = File(image.path);
          _selectedImageBytes = bytes;
        });
      } else {
        setState(() {
          _selectedImageFile = File(image.path);
          _selectedImageBytes = null;
        });
      }
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal memilih gambar: $e")),
      );
    }
  }
}

  // Fungsi untuk upload gambar ke Supabase Storage
  Future<String?> _uploadImage() async {
    if (_selectedImageFile == null) return null;

    try {
      setState(() {
        _isUploadingImage = true;
      });

      // Validasi ukuran file (maks 5MB)
      final fileSize = await _selectedImageFile!.length();
      if (fileSize > 5 * 1024 * 1024) {
        throw Exception("Ukuran gambar terlalu besar. Maksimal 5MB");
      }

      // Dapatkan ekstensi file
      final fileExtension = path.extension(_selectedImageFile!.path).toLowerCase();
      final validExtensions = ['.jpg', '.jpeg', '.png', '.webp'];
      final contentTypeExtension = fileExtension.replaceFirst('.', '');
      
      if (!validExtensions.contains(fileExtension)) {
        throw Exception("Format file tidak didukung. Gunakan JPG, PNG, atau WebP");
      }

      final fileName = 'product_${widget.product['produkid']}_${DateTime.now().millisecondsSinceEpoch}$fileExtension';
      
      // Upload ke Supabase Storage dengan cara yang lebih aman
      await supabase.storage
          .from('Produk Image') // Pastikan nama bucket sesuai
          .upload(
            fileName, 
            _selectedImageFile!,
            fileOptions: FileOptions(
              cacheControl: '3600',
              upsert: true,
              contentType: 'image/$contentTypeExtension'
            ),
          );

      // Dapatkan URL publik dengan cara yang benar
      final response = supabase.storage
          .from('Produk Image')
          .getPublicUrl(fileName);

      print("Image uploaded successfully. URL: $response");
      return response;
      
    } catch (e) {
      print("Error uploading image: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal mengupload gambar: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  // Fungsi Simpan Perubahan ke Supabase
  Future<void> _updateProduct() async {
    try {
      // Validasi input
      if (_namaController.text.isEmpty) {
        throw Exception("Nama produk tidak boleh kosong");
      }
      
      if (_hargaController.text.isEmpty || int.tryParse(_hargaController.text) == null) {
        throw Exception("Harga harus berupa angka");
      }
      
      if (_stokController.text.isEmpty || int.tryParse(_stokController.text) == null) {
        throw Exception("Stok harus berupa angka");
      }

      String? imageUrl = _currentImageUrl;
      
      // Upload gambar baru jika ada
      if (_selectedImageFile != null) {
        final newImageUrl = await _uploadImage();
        if (newImageUrl != null) {
          imageUrl = newImageUrl;
        }
      }

      // Update data produk di Supabase
      final updateData = {
        'namaproduk': _namaController.text,
        'harga': int.parse(_hargaController.text),
        'stok': int.parse(_stokController.text),
        'kategori': _selectedKategori,
      };
      
      // Hanya tambahkan gambar jika ada perubahan
      if (imageUrl != null && imageUrl != _currentImageUrl) {
        updateData['gambar'] = imageUrl;
      }

      final response = await supabase
          .from('produk')
          .update(updateData)
          .eq('produkid', widget.product['produkid']);

      print("Update response: $response");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Data produk berhasil disimpan!"),
            backgroundColor: AppColors.primaryPurple,
          ),
        );
        Navigator.pop(context, true); 
      }
    } catch (e) {
      print("Error updating product: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Terjadi kesalahan: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    const double imageSize = 200.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Ungu dengan Lengkungan
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 250,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryPurple,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(150),
                      bottomRight: Radius.circular(150),
                    ),
                  ),
                ),
                SafeArea(
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                // Foto Produk
                Positioned(
                  top: 80,
                  left: (screenWidth - imageSize) / 2,
                  child: Stack(
                    children: [
                      Container(
                        width: imageSize,
                        height: imageSize,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            )
                          ],
                        ),
                        child: ClipRRect(
  borderRadius: BorderRadius.circular(25),
  child: _isUploadingImage
      ? const Center(
          child: CircularProgressIndicator(
            color: AppColors.primaryPurple,
          ),
        )
      : _selectedImageFile != null
          ? _selectedImageBytes != null
              ? Image.memory( // Untuk web
                  _selectedImageBytes!,
                  fit: BoxFit.cover,
                )
              : Image.file( // Untuk mobile
                  _selectedImageFile!,
                  fit: BoxFit.cover,
                )
          : _currentImageUrl != null && _currentImageUrl!.isNotEmpty
              ? Image.network(
                  _currentImageUrl!,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => 
                    const Icon(Icons.image, size: 80, color: Colors.grey),
                )
              : const Icon(Icons.image, size: 100, color: Colors.grey),
),
                      ),
                      // Tombol Edit Foto (Hanya untuk Admin)
                      if (!_isReadOnly)
                        Positioned(
                          bottom: -5,
                          right: -5,
                          child: InkWell(
                            onTap: _pickImage,
                            child: CircleAvatar(
                              radius: 22,
                              backgroundColor: Colors.white,
                              child: CircleAvatar(
                                radius: 19,
                                backgroundColor: Colors.purple[50],
                                child: const Icon(Icons.edit, size: 20, color: AppColors.primaryPurple),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 60),

            // Form Input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  _buildDetailField("Nama Produk", _namaController, enabled: !_isReadOnly),
                  const SizedBox(height: 20),
                  _buildDetailField("Harga", _hargaController, isNumber: true, prefix: "Rp ", enabled: !_isReadOnly),
                  const SizedBox(height: 20),
                  _buildDetailField("Stok", _stokController, isNumber: true, enabled: !_isReadOnly),
                  const SizedBox(height: 20),
                  
                  // Dropdown Kategori
                  DropdownButtonFormField<String>(
                    value: _selectedKategori,
                    onChanged: _isReadOnly ? null : (val) => setState(() => _selectedKategori = val),
                    decoration: InputDecoration(
                      labelText: "Kategori",
                      labelStyle: const TextStyle(color: AppColors.primaryPurple, fontWeight: FontWeight.bold),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(color: AppColors.primaryPurple, width: 2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(color: Colors.purpleAccent),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    items: _kategoriList
                        .map((e) => DropdownMenuItem(
                              value: e,
                              child: Text(e),
                            ))
                        .toList(),
                  ),

                  const SizedBox(height: 40),

                  // Tombol Aksi (Hanya muncul untuk Admin)
                  if (!_isReadOnly)
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                backgroundColor: Colors.grey[200],
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              ),
                              onPressed: _initializeData, // Reset data ke awal
                              child: const Text("Batal", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryPurple,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              ),
                              onPressed: _updateProduct, // Simpan ke database
                              child: const Text("Simpan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailField(String label, TextEditingController controller, {bool isNumber = false, String? prefix, bool enabled = true}) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      readOnly: !enabled,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixText: prefix,
        labelStyle: const TextStyle(color: AppColors.primaryPurple, fontWeight: FontWeight.bold),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.purpleAccent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: AppColors.primaryPurple, width: 2),
        ),
      ),
    );
  }
}
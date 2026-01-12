import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';

// Pastikan import ini sesuai dengan lokasi file kamu
import '../../../core/constants/app_colors.dart'; 

class ReceiptScreen extends StatelessWidget {
  const ReceiptScreen({super.key});

  Future<void> _downloadPdf(BuildContext context) async {
    try {
      final pdf = pw.Document();

      // Menggunakan font standar agar tidak error di beberapa perangkat
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) => pw.Padding(
            padding: const pw.EdgeInsets.all(20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text(
                    'BRANPOS',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text('Tanggal : 07/11/25'),
                pw.Text('Pukul   : 08.05 WIB'),
                pw.Text('Kasir   : Adella'),
                pw.Text('Pelanggan : Putri'),
                pw.Divider(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Pensil 2B'),
                    pw.Text('Rp. 3.000'),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Pensil Warna Joyko'),
                    pw.Text('Rp. 7.500'),
                  ],
                ),
                pw.Divider(),
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(
                    'Total : Rp. 10.500',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      final bytes = await pdf.save();

      // Menggunakan Printing.sharePdf sudah cukup untuk memicu 
      // dialog "Save to Files" di iOS atau "Download" di Android.
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'struk_branpos.pdf',
      );

    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal download PDF: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF7E57C2), // Purple background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Container(
                width: 300,
                // Hilangkan 'const' di sini karena Column berisi widget yang mungkin dinamis
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                    )
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min, // Agar tinggi container menyesuaikan isi
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Text(
                        "BRANPOS",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Divider(),
                    const Text("Tanggal : 07/11/25"),
                    const Text("Pukul   : 08.05 WIB"),
                    const Text("Kasir   : Adella"),
                    const Text("Pelanggan : Putri"),
                    const Divider(),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Pensil 2B"),
                        Text("Rp. 3.000"),
                      ],
                    ),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Pensil Warna Joyko"),
                        Text("Rp. 7.500"),
                      ],
                    ),
                    const Divider(),
                    const Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        "Total : Rp. 10.500",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () => _downloadPdf(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF7E57C2), // Warna teks tombol
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "DOWNLOAD PDF / SHARE",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
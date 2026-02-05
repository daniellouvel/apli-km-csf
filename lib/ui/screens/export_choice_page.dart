import 'package:flutter/material.dart';
import '../../models.dart'; // <--- CORRECTION DU CHEMIN
import '../../services/export_service.dart';

class ExportChoicePage extends StatelessWidget {
  final UserConfig config;
  final int year;
  final List<Deplacement> items;
  final double totalKm;
  final double indemniteKm;
  final double totalFrais;

  const ExportChoicePage({
    super.key,
    required this.config,
    required this.year,
    required this.items,
    required this.totalKm,
    required this.indemniteKm,
    required this.totalFrais,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Exportation $year"), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.file_download_outlined,
                size: 70, color: Colors.blueGrey),
            const SizedBox(height: 40),
            _buildBtn(
                "Attestation PDF",
                Icons.picture_as_pdf,
                Colors.redAccent,
                () => ExportService.sharePdf(
                    config, year, totalKm, indemniteKm, totalFrais)),
            const SizedBox(height: 20),
            _buildBtn(
                "Tableau Excel",
                Icons.table_chart,
                Colors.green,
                () => ExportService.shareExcel(
                    config, year, items, totalKm, indemniteKm, totalFrais)),
          ],
        ),
      ),
    );
  }

  Widget _buildBtn(String txt, IconData icon, Color col, VoidCallback action) {
    return SizedBox(
      width: double.infinity,
      height: 65,
      child: ElevatedButton.icon(
        onPressed: action,
        icon: Icon(icon, color: Colors.white),
        label: Text(txt,
            style: const TextStyle(fontSize: 18, color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: col,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
      ),
    );
  }
}

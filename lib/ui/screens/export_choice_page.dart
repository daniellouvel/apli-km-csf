import 'package:flutter/material.dart';
import '../../models.dart';
// On importe les deux nouveaux services ici
import '../../services/pdf_service.dart';
import '../../services/excel_service.dart';

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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(title: Text("Exportation $year"), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.drive_folder_upload_rounded,
                size: 70, color: Colors.blueGrey),
            const SizedBox(height: 20),
            const Text(
              "Choisir le format",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),

            // --- APPEL AU PDF SERVICE ---
            _buildExportCard(
              title: "Attestation PDF",
              description: "Générer l'attestation avec 'euros'",
              icon: Icons.picture_as_pdf,
              color: Colors.redAccent,
              onTap: () => PdfService.sharePdf(
                // Changé ici
                config, year, totalKm, indemniteKm, totalFrais,
              ),
            ),

            const SizedBox(height: 20),

            // --- APPEL AU EXCEL SERVICE ---
            _buildExportCard(
              title: "Tableau Excel",
              description: "Détail complet des trajets",
              icon: Icons.table_chart_rounded,
              color: Colors.green.shade600,
              onTap: () => ExcelService.shareExcel(
                // Changé ici
                config, year, items, totalKm, indemniteKm, totalFrais,
              ),
            ),

            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildExportCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, color: color, size: 30),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Text(description),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
        onTap: onTap,
      ),
    );
  }
}

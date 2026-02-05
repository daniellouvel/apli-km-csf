import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models.dart';

class ExcelService {
  static Future<void> shareExcel(
      UserConfig config,
      int year,
      List<Deplacement> items,
      double totalKm,
      double indemniteKm,
      double totalFrais) async {
    final excel = Excel.createExcel();
    final sheet = excel[excel.getDefaultSheet()!]!;

    // --- EN-TÊTE DÉTAILLÉ ---
    sheet.appendRow(
        [TextCellValue('RELEVÉ DÉTAILLÉ DES FRAIS - ASSOCIATION CSF')]);
    sheet.appendRow([TextCellValue('Bénévole : ${config.nom}')]);
    sheet.appendRow([TextCellValue('Année civile : $year')]);
    sheet.appendRow([TextCellValue('')]); // Ligne vide pour respirer

    // --- RÉCAPITULATIF DES CALCULS ---
    sheet.appendRow([TextCellValue('RÉCAPITULATIF DES FRAIS :')]);
    sheet.appendRow([
      TextCellValue('Total Distance parcourue :'),
      TextCellValue('${totalKm.toStringAsFixed(1)} KM')
    ]);
    sheet.appendRow([
      TextCellValue('Montant Indemnités Kilométriques :'),
      TextCellValue('${indemniteKm.toStringAsFixed(2)} euros')
    ]);
    sheet.appendRow([
      TextCellValue('Total Autres Frais (péages, repas...) :'),
      TextCellValue('${totalFrais.toStringAsFixed(2)} euros')
    ]);
    sheet.appendRow([
      TextCellValue('MONTANT TOTAL À DÉDUIRE :'),
      TextCellValue('${(indemniteKm + totalFrais).toStringAsFixed(2)} euros')
    ]);

    sheet.appendRow([TextCellValue('')]); // Ligne vide
    sheet.appendRow([TextCellValue('')]); // Ligne vide

    // --- TABLEAU DES DÉTAILS ---
    sheet.appendRow([
      TextCellValue('DATE'),
      TextCellValue('MOTIF / RAISON'),
      TextCellValue('TYPE'),
      TextCellValue('DISTANCE (KM)'),
      TextCellValue('MONTANT (EUROS)')
    ]);

    // Filtrage et ajout des lignes
    for (var d in items.where((i) => i.date.year == year)) {
      sheet.appendRow([
        TextCellValue(DateFormat('dd/MM/yyyy').format(d.date)),
        TextCellValue(d.raison),
        TextCellValue(d.type == 'trajet' ? 'Trajet' : 'Frais Divers'),
        // Si c'est un trajet on affiche les KM, sinon rien
        TextCellValue(d.type == 'trajet' ? '${d.km}' : '-'),
        // Si c'est un trajet on n'affiche pas le montant ici (car calculé globalement),
        // si c'est un frais on affiche le montant
        TextCellValue(
            d.type == 'frais' ? '${d.montant.toStringAsFixed(2)}' : '-'),
      ]);
    }

    // Sauvegarde et partage
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/Frais_CSF_$year.xlsx');
    final bytes = excel.encode();
    if (bytes != null) {
      await file.writeAsBytes(bytes, flush: true);
      await Share.shareXFiles([XFile(file.path)],
          text: 'Export Excel CSF $year');
    }
  }
}

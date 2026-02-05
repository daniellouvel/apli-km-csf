import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models.dart'; // <--- Vérifie que models.dart est bien à la racine de /lib

class ExportService {
  static String _montantEnLettres(double montant) {
    final int entiere = montant.floor();
    final int centimes = ((montant - entiere) * 100).round();
    String resultat = "$entiere euros";
    if (centimes > 0) {
      resultat = "$entiere euros et $centimes centimes";
    }
    return resultat;
  }

  static Future<void> sharePdf(UserConfig config, int year, double totalKm,
      double indemniteKm, double totalFrais) async {
    final pdf = pw.Document();
    final double montantTotal = indemniteKm + totalFrais;

    pdf.addPage(pw.Page(
      theme: pw.ThemeData.withFont(
          base: pw.Font.helvetica(), bold: pw.Font.helveticaBold()),
      build: (pw.Context context) => pw.Padding(
        padding: const pw.EdgeInsets.all(40),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text("ATTESTATION SUR L'HONNEUR",
                style:
                    pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 30),
            pw.Text("Je soussigné(e), ${config.nom}"),
            pw.Text("Demeurant, ${config.adresse}"),
            pw.SizedBox(height: 30),
            pw.Text(
                "Atteste sur l'honneur que ma déclaration de frais engagés pour la déduction d'impôt en tant que bénévole pour l'association CSF est exacte et véridique. Je confirme avoir engagé des frais pour des activités bénévoles au nom de l'association susmentionnée, détaillés comme suit :",
                textAlign: pw.TextAlign.justify),
            pw.SizedBox(height: 30),
            pw.Text(
                "Frais de déplacement : ${indemniteKm.toStringAsFixed(2)} euros pour ${totalKm.toStringAsFixed(1)} KM"),
            pw.Text(
                "Autres frais engagés : ${totalFrais.toStringAsFixed(2)} euros"),
            pw.SizedBox(height: 30),
            pw.RichText(
              text: pw.TextSpan(children: [
                pw.TextSpan(text: "Le montant total s'élève à "),
                pw.TextSpan(
                    text: "${montantTotal.toStringAsFixed(2)} euros.",
                    style:
                        pw.TextStyle(decoration: pw.TextDecoration.underline)),
              ]),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
                "Soit en toutes lettres : ${_montantEnLettres(montantTotal)}.",
                style:
                    pw.TextStyle(fontStyle: pw.FontStyle.italic, fontSize: 10)),
            pw.SizedBox(height: 40),
            pw.Text(
                "Fait à : ____________________ , le : ${DateFormat('dd/MM/yyyy').format(DateTime.now())}"),
            pw.SizedBox(height: 30),
            pw.Text("Signature :"),
          ],
        ),
      ),
    ));

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/Attestation_$year.pdf');
    await file.writeAsBytes(await pdf.save());
    await Share.shareXFiles([XFile(file.path)]);
  }

  static Future<void> shareExcel(
      UserConfig config,
      int year,
      List<Deplacement> items,
      double totalKm,
      double indemniteKm,
      double totalFrais) async {
    final excel = Excel.createExcel();
    final sheet = excel[excel.getDefaultSheet()!]!;

    sheet.appendRow([TextCellValue('RELEVÉ DES FRAIS - CSF')]);
    sheet.appendRow([TextCellValue('Nom : ${config.nom}')]);
    sheet.appendRow([
      TextCellValue(
          'TOTAL : ${(indemniteKm + totalFrais).toStringAsFixed(2)} euros')
    ]);
    sheet.appendRow([TextCellValue('')]);

    sheet.appendRow([
      TextCellValue('Date'),
      TextCellValue('Raison'),
      TextCellValue('Type'),
      TextCellValue('Valeur')
    ]);

    for (var d in items.where((i) => i.date.year == year)) {
      sheet.appendRow([
        TextCellValue(DateFormat('dd/MM').format(d.date)),
        TextCellValue(d.raison),
        TextCellValue(d.type),
        DoubleCellValue(d.type == 'trajet' ? d.km : d.montant),
      ]);
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/Frais_$year.xlsx');
    await file.writeAsBytes(excel.encode()!);
    await Share.shareXFiles([XFile(file.path)]);
  }
}

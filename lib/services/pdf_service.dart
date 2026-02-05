import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models.dart';

class PdfService {
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
            // Titre avec l'année
            pw.Text("ATTESTATION SUR L'HONNEUR - ANNÉE $year",
                style:
                    pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 30),
            pw.Text("Je soussigné(e), ${config.nom}"),
            pw.Text("Demeurant, ${config.adresse}"),
            pw.SizedBox(height: 30),
            pw.Text(
                "Atteste sur l'honneur que ma déclaration de frais engagés pour la déduction d'impôt en tant que bénévole pour l'association CSF au titre de l'année civile $year est exacte et véridique. Je confirme avoir engagé des frais pour des activités bénévoles au nom de l'association susmentionnée, détaillés comme suit :",
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
}

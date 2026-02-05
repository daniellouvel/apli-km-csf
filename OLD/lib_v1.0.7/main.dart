import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'deplacement_form_page.dart';
import 'settings_page.dart';
import 'storage.dart';
import 'grille_fiscale.dart';

const String appVersion = 'V1_0_7';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final initialConfig = await AppStorage.loadConfig();
  final initialDeplacements = await AppStorage.loadDeplacements();
  runApp(MyApp(
    initialConfig: initialConfig,
    initialDeplacements: initialDeplacements,
  ));
}

class TrajetType {
  String raison;
  double kmDefaut;
  TrajetType({required this.raison, required this.kmDefaut});
}

double calculIndemnite(
    {required UserConfig config, required double kmAnnuels}) {
  if (config.baremeCustom != null) {
    final b = config.baremeCustom!;
    if (kmAnnuels <= 5000) return kmAnnuels * b.coef1;
    if (kmAnnuels <= 20000) return (kmAnnuels * b.coef2) + b.fixe2;
    return kmAnnuels * b.coef3;
  }
  String catPuissance = config.puissance <= 3
      ? '3cv'
      : config.puissance >= 7
          ? '7cv+'
          : '${config.puissance.toInt()}cv';
  final table = config.typeVehicule == 'electrique'
      ? GrilleFiscale.electrique
      : GrilleFiscale.thermique;
  final tranches = table[catPuissance]!;
  Map<String, double> coef;
  if (kmAnnuels <= 5000) {
    coef = tranches['0-5000']!;
  } else if (kmAnnuels <= 20000) {
    coef = tranches['5001-20000']!;
  } else {
    coef = tranches['20000+']!;
  }
  return (coef['a']! * kmAnnuels) + coef['b']!;
}

class MyApp extends StatefulWidget {
  final UserConfig? initialConfig;
  final List<Deplacement> initialDeplacements;
  const MyApp(
      {super.key,
      required this.initialConfig,
      required this.initialDeplacements});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late UserConfig _config;
  @override
  void initState() {
    super.initState();
    _config = widget.initialConfig ??
        UserConfig(
            nom: '', adresse: '', typeVehicule: 'thermique', puissance: 0);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(seedColor: Colors.teal);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          colorScheme: colorScheme,
          useMaterial3: true,
          appBarTheme: AppBarTheme(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary)),
      home: HomePage(
          initialDeplacements: widget.initialDeplacements,
          config: _config,
          onEditConfig: (c) {
            setState(() => _config = c);
            AppStorage.saveConfig(c);
          }),
    );
  }
}

class HomePage extends StatefulWidget {
  final UserConfig config;
  final void Function(UserConfig) onEditConfig;
  final List<Deplacement> initialDeplacements;
  const HomePage(
      {super.key,
      required this.config,
      required this.onEditConfig,
      required this.initialDeplacements});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late List<Deplacement> _items;
  final List<TrajetType> _trajets = [];
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _items = List<Deplacement>.from(widget.initialDeplacements);
    _refresh();
  }

  void _refresh() {
    _trajets.clear();
    for (final d in _items.where((e) => e.type == 'trajet')) {
      if (!_trajets.any((t) => t.raison == d.raison && t.kmDefaut == d.km))
        _trajets.add(TrajetType(raison: d.raison, kmDefaut: d.km));
    }
  }

  double _totalKm(int y) => _items
      .where((d) => d.date.year == y && d.type == 'trajet')
      .fold(0.0, (s, d) => s + d.km);
  double _totalIndem(int y) =>
      calculIndemnite(config: widget.config, kmAnnuels: _totalKm(y));
  double _totalFrais(int y) => _items
      .where((d) => d.date.year == y && d.type == 'frais')
      .fold(0.0, (s, d) => s + d.montant);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final filtered = _items.where((d) => d.date.year == _selectedYear).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes déplacements'),
        actions: [
          IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => SettingsPage(
                          configInitiale: widget.config,
                          deplacementsActuels: _items,
                          onConfigChange: widget.onEditConfig,
                          onDataRestored: () async {
                            _items = await AppStorage.loadDeplacements();
                            setState(() => _refresh());
                          })))),
          IconButton(
              icon: const Icon(Icons.ios_share),
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => ExportChoicePage(
                          year: _selectedYear,
                          config: widget.config,
                          items: filtered,
                          indemniteKm: _totalIndem(_selectedYear),
                          totalKm: _totalKm(_selectedYear),
                          totalFrais: _totalFrais(_selectedYear))))),
        ],
      ),
      body: Column(
        children: [
          if (widget.config.nom.isNotEmpty)
            Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12)),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Utilisateur : ${widget.config.nom}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            Text(appVersion,
                                style: TextStyle(
                                    fontSize: 10,
                                    color: scheme.primary.withOpacity(0.5)))
                          ]),
                      if (widget.config.adresse.isNotEmpty)
                        Text('Adresse : ${widget.config.adresse}',
                            style: const TextStyle(fontSize: 12))
                    ])),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(children: [
                const Text('Année : '),
                DropdownButton<int>(
                    value: _selectedYear,
                    items: List.generate(5, (i) => DateTime.now().year - i)
                        .map((y) => DropdownMenuItem(
                            value: y, child: Text(y.toString())))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedYear = v!)),
                const Spacer(),
                Text(
                    '${(_totalIndem(_selectedYear) + _totalFrais(_selectedYear)).toStringAsFixed(2)} €',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: scheme.primary,
                        fontSize: 16))
              ])),
          Expanded(
              child: ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) {
                    final d = filtered[i];
                    return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        child: ListTile(
                            leading: CircleAvatar(
                                backgroundColor: d.type == 'trajet'
                                    ? scheme.primary
                                    : scheme.secondary,
                                child: Icon(
                                    d.type == 'trajet'
                                        ? Icons.directions_car
                                        : Icons.receipt_long,
                                    color: Colors.white,
                                    size: 20)),
                            title: Text(d.raison,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            subtitle:
                                Text(DateFormat('yyyy-MM-dd').format(d.date)),
                            trailing: Text(d.type == 'trajet'
                                ? '${d.km} km'
                                : '${d.montant} €')));
                  })),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            final res = await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        DeplacementFormPage(trajetsConnus: _trajets)));
            if (res != null) {
              setState(() {
                _items.add(res);
                _items.sort((a, b) => b.date.compareTo(a.date));
                _refresh();
              });
              AppStorage.saveDeplacements(_items);
            }
          },
          icon: const Icon(Icons.add),
          label: const Text('Ajouter')),
    );
  }
}

// --- PAGE DE CHOIX ET GÉNÉRATION PDF EXACTE ---
class ExportChoicePage extends StatelessWidget {
  final int year;
  final UserConfig config;
  final List<Deplacement> items;
  final double indemniteKm;
  final double totalKm;
  final double totalFrais;

  const ExportChoicePage(
      {super.key,
      required this.year,
      required this.config,
      required this.items,
      required this.indemniteKm,
      required this.totalKm,
      required this.totalFrais});

  Future<void> _exportPdf() async {
    final pdf = pw.Document();
    final euro = "€"; // Utilisation du string simple pour l'Euro

    pdf.addPage(pw.Page(
      build: (pw.Context context) => pw.Padding(
        padding: const pw.EdgeInsets.all(30),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(
                child: pw.Text("ATTESTATION SUR L'HONNEUR",
                    style: pw.TextStyle(
                        fontSize: 20, fontWeight: pw.FontWeight.bold))),
            pw.SizedBox(height: 30),
            pw.Text("Je soussigné(e), ${config.nom}"),
            pw.Text("Demeurant, ${config.adresse}"),
            pw.SizedBox(height: 30),
            pw.Text(
                "Atteste sur l'honneur que ma déclaration de frais engagés pour la déduction d'impôt en tant que bénévole pour l'association CSF est exacte et véridique. Je confirme avoir engagé des frais pour des activités bénévoles au nom de l'association susmentionnée, détaillés comme suit :",
                textAlign: pw.TextAlign.justify),
            pw.SizedBox(height: 30),
            pw.Text(
                "Frais de déplacement (kilométrage) : ${indemniteKm.toStringAsFixed(2)} $euro pour ${totalKm.toStringAsFixed(1)} KM"),
            pw.Text(
                "Autres frais engagés : ${totalFrais.toStringAsFixed(2)} $euro"),
            pw.SizedBox(height: 30),
            pw.Text(
                "Le montant total correspondant à l'ensemble de ces frais s'élève à ${(indemniteKm + totalFrais).toStringAsFixed(2)} $euro."),
            pw.SizedBox(height: 30),
            pw.Text(
                "Je tiens à préciser que je renonce à tout remboursement de la part de l'association pour les frais que j'ai engagés dans le cadre de mes activités bénévoles."),
            pw.SizedBox(height: 30),
            pw.Text(
                "Je déclare également que je suis conscient(e) que toute fausse déclaration peut entraîner des conséquences juridiques et fiscales."),
            pw.SizedBox(height: 30),
            pw.Text("Fait pour servir et valoir ce que de droit."),
            pw.SizedBox(height: 40),
            pw.Text(
                "Fait à : ______________________ , le : ${DateFormat('dd/MM/yyyy').format(DateTime.now())}"),
            pw.SizedBox(height: 40),
            pw.Text("Signature : __________________________________________"),
          ],
        ),
      ),
    ));
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/Attestation_$year.pdf');
    await file.writeAsBytes(await pdf.save());
    await Share.shareXFiles([XFile(file.path)]);
  }

  Future<void> _exportExcel() async {
    final excel = Excel.createExcel();
    final sheet = excel[excel.getDefaultSheet()!]!;
    sheet.appendRow([
      TextCellValue('Date'),
      TextCellValue('Raison'),
      TextCellValue('KM/Montant')
    ]);
    for (var d in items)
      sheet.appendRow([
        TextCellValue(DateFormat('yyyy-MM-dd').format(d.date)),
        TextCellValue(d.raison),
        TextCellValue(d.type == 'trajet' ? '${d.km} km' : '${d.montant} €')
      ]);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/Export_$year.xlsx');
    await file.writeAsBytes(excel.encode()!);
    await Share.shareXFiles([XFile(file.path)]);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text("Format d'envoi")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
                onPressed: _exportExcel,
                icon: const Icon(Icons.table_chart),
                label: const Text("ENVOYER EXCEL"),
                style: ElevatedButton.styleFrom(
                    backgroundColor: scheme.primaryContainer,
                    minimumSize: const Size(double.infinity, 60))),
            const SizedBox(height: 20),
            ElevatedButton.icon(
                onPressed: _exportPdf,
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text("ENVOYER PDF"),
                style: ElevatedButton.styleFrom(
                    backgroundColor: scheme.primaryContainer,
                    minimumSize: const Size(double.infinity, 60))),
          ],
        ),
      ),
    );
  }
}

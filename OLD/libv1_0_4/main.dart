// FICHIER : lib/main.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart';
import 'dart:io';

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

/// ----- CALCUL DES INDEMNITÉS -----
double calculIndemnite({
  required UserConfig config,
  required double kmAnnuels,
}) {
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

  const MyApp({
    super.key,
    required this.initialConfig,
    required this.initialDeplacements,
  });

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
          nom: '',
          adresse: '',
          typeVehicule: 'thermique',
          puissance: 0,
        );
  }

  void _updateConfig(UserConfig nouvelleConfig) {
    setState(() => _config = nouvelleConfig);
    AppStorage.saveConfig(_config);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(seedColor: Colors.teal);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Carnet de trajets',
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
        ),
      ),
      home: HomePage(
        initialDeplacements: widget.initialDeplacements,
        config: _config,
        onEditConfig: _updateConfig,
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final UserConfig config;
  final void Function(UserConfig) onEditConfig;
  final List<Deplacement> initialDeplacements;

  const HomePage({
    super.key,
    required this.config,
    required this.onEditConfig,
    required this.initialDeplacements,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late List<Deplacement> _items;
  final List<TrajetType> _trajets = [];
  final _dateFormat = DateFormat('yyyy-MM-dd');
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _items = List<Deplacement>.from(widget.initialDeplacements);
    _refreshTrajetsPredefinis();
  }

  void _refreshTrajetsPredefinis() {
    _trajets.clear();
    for (final d in _items.where((e) => e.type == 'trajet')) {
      final existeDeja =
          _trajets.any((t) => t.raison == d.raison && t.kmDefaut == d.km);
      if (!existeDeja) {
        _trajets.add(TrajetType(raison: d.raison, kmDefaut: d.km));
      }
    }
  }

  Future<void> _onDataRestored() async {
    final newItems = await AppStorage.loadDeplacements();
    setState(() {
      _items = newItems;
      _refreshTrajetsPredefinis();
    });
  }

  Future<void> _handleDeplacement({Deplacement? original}) async {
    final result = await Navigator.of(context).push<Deplacement?>(
      MaterialPageRoute(
        builder: (_) => DeplacementFormPage(
          trajetsConnus: _trajets,
          deplacementInitial: original,
        ),
      ),
    );
    if (result != null) {
      setState(() {
        if (original != null) {
          final idx = _items.indexOf(original);
          if (idx != -1) _items[idx] = result;
        } else {
          _items.add(result);
        }
        _items.sort((a, b) => b.date.compareTo(a.date));
        _refreshTrajetsPredefinis();
      });
      await AppStorage.saveDeplacements(_items);
    }
  }

  Future<void> _confirmDelete(Deplacement d) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Voulez-vous supprimer le mouvement :\n"${d.raison}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ANNULER'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('SUPPRIMER',
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _items.remove(d);
        _refreshTrajetsPredefinis();
      });
      await AppStorage.saveDeplacements(_items);
    }
  }

  double _totalKmForYear(int year) {
    return _items
        .where((d) => d.date.year == year && d.type == 'trajet')
        .fold(0.0, (sum, d) => sum + d.km);
  }

  double _indemniteForYear(int year) {
    final km = _totalKmForYear(year);
    if (km == 0 || widget.config.puissance <= 0) return 0;
    return calculIndemnite(config: widget.config, kmAnnuels: km);
  }

  double _totalFraisForYear(int year) {
    return _items
        .where((d) => d.date.year == year && d.type == 'frais')
        .fold(0.0, (sum, d) => sum + d.montant);
  }

  List<Deplacement> get _filteredItems =>
      _items.where((item) => item.date.year == _selectedYear).toList();

  Future<void> _exportAndShareExcel() async {
    final year = _selectedYear;
    final lignesAnnee = _filteredItems;
    if (lignesAnnee.isEmpty) return;
    final totalKmTrajets = _totalKmForYear(year);
    final indemniteKm = _indemniteForYear(year);
    final totalFrais = _totalFraisForYear(year);
    final totalGlobal = indemniteKm + totalFrais;
    final prixParKm = totalKmTrajets > 0 ? indemniteKm / totalKmTrajets : 0.0;

    final excel = Excel.createExcel();
    final sheet = excel[excel.getDefaultSheet()!]!;

    sheet.appendRow([TextCellValue('Export : ${widget.config.nom}')]);
    sheet.appendRow([TextCellValue('Adresse : ${widget.config.adresse}')]);
    sheet.appendRow([TextCellValue('Année : $year')]);
    sheet.appendRow(
        [TextCellValue('Total Global : ${totalGlobal.toStringAsFixed(2)} €')]);
    sheet.appendRow([TextCellValue('')]);

    final headers = [
      'Date',
      'Libellé',
      'Type',
      'Kilomètres',
      'Taux €/km',
      'Montant (€)'
    ];
    sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());

    for (final d in lignesAnnee) {
      final isTrajet = d.type == 'trajet';
      sheet.appendRow([
        TextCellValue(_dateFormat.format(d.date)),
        TextCellValue(d.raison),
        TextCellValue(d.type),
        TextCellValue(isTrajet ? d.km.toString() : ''),
        TextCellValue(isTrajet ? prixParKm.toStringAsFixed(4) : ''),
        DoubleCellValue(isTrajet ? d.km * prixParKm : d.montant),
      ]);
    }
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/deplacements_$year.xlsx');
    await file.writeAsBytes(excel.encode()!);
    await Share.shareXFiles([XFile(file.path)], text: 'Export $year');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes déplacements'),
        actions: [
          IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => SettingsPage(
                      configInitiale: widget.config,
                      deplacementsActuels: _items,
                      onConfigChange: widget.onEditConfig,
                      onDataRestored: _onDataRestored)))),
          IconButton(
              icon: const Icon(Icons.ios_share),
              onPressed: _exportAndShareExcel),
        ],
      ),
      body: Column(
        children: [
          if (widget.config.nom.isNotEmpty) ...[
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
                  Text('Utilisateur : ${widget.config.nom}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  if (widget.config.adresse.isNotEmpty)
                    Text('Adresse : ${widget.config.adresse}'),
                ],
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Text('Année : '),
                DropdownButton<int>(
                  value: _selectedYear,
                  items: List.generate(5, (i) => DateTime.now().year - i)
                      .map((y) =>
                          DropdownMenuItem(value: y, child: Text(y.toString())))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedYear = v!),
                ),
                const Spacer(),
                Text(
                    '${(_indemniteForYear(_selectedYear) + _totalFraisForYear(_selectedYear)).toStringAsFixed(2)} €',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: scheme.primary,
                        fontSize: 16)),
              ],
            ),
          ),
          Expanded(
            child: Scrollbar(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 80),
                itemCount: _filteredItems.length,
                itemBuilder: (ctx, i) {
                  final d = _filteredItems[i];
                  final isTrajet = d.type == 'trajet';
                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: ListTile(
                      onLongPress: () => _handleDeplacement(original: d),
                      leading: CircleAvatar(
                        backgroundColor:
                            isTrajet ? scheme.primary : scheme.secondary,
                        child: Icon(
                            isTrajet
                                ? Icons.directions_car
                                : Icons.receipt_long,
                            color: Colors.white,
                            size: 20),
                      ),
                      // --- LIGNE 302 : VERIFIE BIEN 'raison' CI-DESSOUS ---
                      title: Text(d.raison,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(_dateFormat.format(d.date)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(isTrajet ? '${d.km} km' : '${d.montant} €',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.redAccent),
                            onPressed: () => _confirmDelete(d),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _handleDeplacement(),
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
    );
  }
}

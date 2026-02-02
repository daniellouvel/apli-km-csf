import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart';
import 'dart:io';

import 'deplacement_form_page.dart';
import 'settings_page.dart';
import 'storage.dart';

const String appVersion = 'V1_0_3';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final initialConfig = await AppStorage.loadConfig();
  final initialDeplacements = await AppStorage.loadDeplacements();
  runApp(MyApp(
    initialConfig: initialConfig,
    initialDeplacements: initialDeplacements,
  ));
}

// ---------- Modèles ----------

class Deplacement {
  DateTime date;
  String raison;
  double km;
  double montant; // pour les frais
  String type; // 'trajet' ou 'frais'

  Deplacement({
    required this.date,
    required this.raison,
    this.km = 0.0,
    this.montant = 0.0,
    this.type = 'trajet',
  });

  int get date_year => date.year;

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'raison': raison,
      'km': km,
      'montant': montant,
      'type': type,
    };
  }

  factory Deplacement.fromJson(Map<String, dynamic> map) {
    return Deplacement(
      date: DateTime.parse(map['date'] as String),
      raison: map['raison'] as String? ?? '',
      km: (map['km'] as num?)?.toDouble() ?? 0.0,
      montant: (map['montant'] as num?)?.toDouble() ?? 0.0,
      type: map['type'] as String? ?? 'trajet',
    );
  }
}

class TrajetType {
  String raison;
  double kmDefaut;

  TrajetType({required this.raison, required this.kmDefaut});
}

class UserConfig {
  String nom;
  String typeVehicule; // 'thermique' ou 'electrique'
  double puissance; // CV fiscaux

  UserConfig({
    required this.nom,
    required this.typeVehicule,
    required this.puissance,
  });

  Map<String, dynamic> toJson() {
    return {
      'nom': nom,
      'typeVehicule': typeVehicule,
      'puissance': puissance,
    };
  }

  factory UserConfig.fromJson(Map<String, dynamic> map) {
    return UserConfig(
      nom: map['nom'] as String? ?? '',
      typeVehicule: map['typeVehicule'] as String? ?? 'thermique',
      puissance: (map['puissance'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// ----- BARÈME KILOMÉTRIQUE 2025 -----

double calculIndemnite({
  required String typeVehicule,
  required double puissance,
  required double kmAnnuels,
}) {
  String catPuissance;
  if (puissance <= 3) {
    catPuissance = '3cv';
  } else if (puissance == 4) {
    catPuissance = '4cv';
  } else if (puissance == 5) {
    catPuissance = '5cv';
  } else if (puissance == 6) {
    catPuissance = '6cv';
  } else {
    catPuissance = '7cv+';
  }

  const thermique = {
    '3cv': {
      '0-5000': {'a': 0.529, 'b': 0.0},
      '5001-20000': {'a': 0.316, 'b': 1065.0},
      '20000+': {'a': 0.370, 'b': 0.0},
    },
    '4cv': {
      '0-5000': {'a': 0.606, 'b': 0.0},
      '5001-20000': {'a': 0.340, 'b': 1330.0},
      '20000+': {'a': 0.407, 'b': 0.0},
    },
    '5cv': {
      '0-5000': {'a': 0.636, 'b': 0.0},
      '5001-20000': {'a': 0.357, 'b': 1395.0},
      '20000+': {'a': 0.427, 'b': 0.0},
    },
    '6cv': {
      '0-5000': {'a': 0.665, 'b': 0.0},
      '5001-20000': {'a': 0.374, 'b': 1457.0},
      '20000+': {'a': 0.447, 'b': 0.0},
    },
    '7cv+': {
      '0-5000': {'a': 0.697, 'b': 0.0},
      '5001-20000': {'a': 0.394, 'b': 1515.0},
      '20000+': {'a': 0.470, 'b': 0.0},
    },
  };

  const electrique = {
    '3cv': {
      '0-5000': {'a': 0.635, 'b': 0.0},
      '5001-20000': {'a': 0.379, 'b': 1278.0},
      '20000+': {'a': 0.444, 'b': 0.0},
    },
    '4cv': {
      '0-5000': {'a': 0.727, 'b': 0.0},
      '5001-20000': {'a': 0.408, 'b': 1596.0},
      '20000+': {'a': 0.488, 'b': 0.0},
    },
    '5cv': {
      '0-5000': {'a': 0.763, 'b': 0.0},
      '5001-20000': {'a': 0.428, 'b': 1674.0},
      '20000+': {'a': 0.512, 'b': 0.0},
    },
    '6cv': {
      '0-5000': {'a': 0.798, 'b': 0.0},
      '5001-20000': {'a': 0.449, 'b': 1748.0},
      '20000+': {'a': 0.536, 'b': 0.0},
    },
    '7cv+': {
      '0-5000': {'a': 0.836, 'b': 0.0},
      '5001-20000': {'a': 0.473, 'b': 1818.0},
      '20000+': {'a': 0.564, 'b': 0.0},
    },
  };

  final table = typeVehicule == 'electrique' ? electrique : thermique;
  final cfg = table[catPuissance]!;
  Map coef;
  if (kmAnnuels <= 5000) {
    coef = cfg['0-5000']!;
  } else if (kmAnnuels <= 20000) {
    coef = cfg['5001-20000']!;
  } else {
    coef = cfg['20000+']!;
  }

  final a = coef['a']!;
  final b = coef['b']!;
  return a * kmAnnuels + b;
}

// ---------- Application ----------

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
          typeVehicule: 'thermique',
          puissance: 0,
        );
  }

  void _updateConfig(UserConfig nouvelleConfig) {
    setState(() {
      _config = nouvelleConfig;
    });
    AppStorage.saveConfig(_config);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(seedColor: Colors.teal);

    return MaterialApp(
      title: 'Carnet de trajets',
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: colorScheme.secondary,
          foregroundColor: colorScheme.onSecondary,
        ),
        // ICI : CardThemeData, comme demandé par ton erreur
        cardTheme: const CardThemeData(
          margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
    for (final d in _items.where((e) => e.type == 'trajet')) {
      final existeDeja =
          _trajets.any((t) => t.raison == d.raison && t.kmDefaut == d.km);
      if (!existeDeja) {
        _trajets.add(TrajetType(raison: d.raison, kmDefaut: d.km));
      }
    }
  }

  Future<void> _addDeplacement() async {
    final result = await Navigator.of(context).push<Deplacement?>(
      MaterialPageRoute(
        builder: (_) => DeplacementFormPage(
          trajetsConnus: _trajets,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _items.add(result);
        if (result.type == 'trajet') {
          final existeDeja = _trajets.any(
            (t) => t.raison == result.raison && t.kmDefaut == result.km,
          );
          if (!existeDeja) {
            _trajets.add(
              TrajetType(raison: result.raison, kmDefaut: result.km),
            );
          }
        }
      });
      await AppStorage.saveDeplacements(_items);
    }
  }

  Future<void> _editDeplacement(Deplacement original) async {
    final index = _items.indexOf(original);
    if (index == -1) return;

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
        _items[index] = result;
        if (result.type == 'trajet') {
          final existeDeja = _trajets.any(
            (t) => t.raison == result.raison && t.kmDefaut == result.km,
          );
          if (!existeDeja) {
            _trajets.add(
              TrajetType(raison: result.raison, kmDefaut: result.km),
            );
          }
        }
      });
      await AppStorage.saveDeplacements(_items);
    }
  }

  Future<void> _openSettings() async {
    final result = await Navigator.of(context).push<UserConfig?>(
      MaterialPageRoute(
        builder: (_) => SettingsPage(
          configInitiale: widget.config,
          deplacementsActuels: _items,
          onConfigChange: widget.onEditConfig,
        ),
      ),
    );

    if (result != null) {
      widget.onEditConfig(result);
    }
  }

  double _totalKmForYear(int year) {
    return _items
        .where((d) => d.date.year == year && d.type == 'trajet')
        .fold(0.0, (sum, d) => sum + d.km);
  }

  double _indemniteForYear(int year) {
    final cfg = widget.config;
    if (cfg.puissance <= 0) return 0;
    final km = _totalKmForYear(year);
    if (km == 0) return 0;
    return calculIndemnite(
      typeVehicule: cfg.typeVehicule,
      puissance: cfg.puissance,
      kmAnnuels: km,
    );
  }

  double _totalFraisForYear(int year) {
    return _items
        .where((d) => d.date.year == year && d.type == 'frais')
        .fold(0.0, (sum, d) => sum + d.montant);
  }

  List<Deplacement> get _filteredItems {
    return _items.where((item) => item.date_year == _selectedYear).toList();
  }

  Future<void> _exportAndShareExcel() async {
    final year = _selectedYear;
    final lignesAnnee = _items.where((item) => item.date_year == year).toList();
    if (lignesAnnee.isEmpty) return;

    final totalKmTrajets = _totalKmForYear(year);
    final indemniteKm = _indemniteForYear(year);
    final totalFrais = _totalFraisForYear(year);
    final totalGlobal = indemniteKm + totalFrais;
    final prixParKm = totalKmTrajets > 0 ? indemniteKm / totalKmTrajets : 0.0;

    final excel = Excel.createExcel();
    final defaultSheetName = excel.getDefaultSheet()!;
    final sheet = excel[defaultSheetName]!;

    final titleStyle = CellStyle(
      bold: true,
      fontSize: 14,
    );

    final infoStyle = CellStyle(
      fontSize: 12,
    );

    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('FFD9D9D9'),
      horizontalAlign: HorizontalAlign.Center,
    );

    final numberStyle = CellStyle(
      fontSize: 12,
      horizontalAlign: HorizontalAlign.Right,
    );

    // Titre
    sheet.appendRow([
      TextCellValue('Carnet de trajets et frais'),
    ]);
    sheet.cell(CellIndex.indexByString('A1')).cellStyle = titleStyle;

    // Infos
    final infos = [
      'Nom : ${widget.config.nom}',
      'Véhicule : ${widget.config.typeVehicule}',
      'Puissance : ${widget.config.puissance}',
      'Année de calcul : $year',
      'Total km trajets : ${totalKmTrajets.toStringAsFixed(2)}',
      'Indemnité trajets : ${indemniteKm.toStringAsFixed(2)} €',
      'Total frais : ${totalFrais.toStringAsFixed(2)} €',
      'Total à défiscaliser : ${totalGlobal.toStringAsFixed(2)} €',
      'Taux moyen trajet : ${prixParKm.toStringAsFixed(4)} €/km',
    ];

    for (var i = 0; i < infos.length; i++) {
      sheet.appendRow([
        TextCellValue(infos[i]),
      ]);
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i + 1))
          .cellStyle = infoStyle;
    }

    // Ligne vide
    sheet.appendRow([
      TextCellValue(''),
    ]);

    // Entête du tableau
    final headers = [
      'Date',
      'Libellé',
      'Type',
      'Kilomètres',
      'Taux €/km',
      'Montant à défiscaliser',
    ];
    sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());

    final headerRowIndex = infos.length + 2;
    for (var col = 0; col < headers.length; col++) {
      sheet
          .cell(CellIndex.indexByColumnRow(
              columnIndex: col, rowIndex: headerRowIndex))
          .cellStyle = headerStyle;
    }

    // Données
    for (final d in lignesAnnee) {
      if (d.type == 'frais') {
        sheet.appendRow([
          TextCellValue(_dateFormat.format(d.date)),
          TextCellValue(d.raison),
          TextCellValue(d.type),
          TextCellValue(''),
          TextCellValue(''),
          DoubleCellValue(d.montant),
        ]);
      } else {
        final montantLigne = d.km * prixParKm;
        sheet.appendRow([
          TextCellValue(_dateFormat.format(d.date)),
          TextCellValue(d.raison),
          TextCellValue(d.type),
          DoubleCellValue(d.km),
          DoubleCellValue(prixParKm),
          DoubleCellValue(montantLigne),
        ]);
      }
    }

    final lastRow = sheet.maxRows;
    for (var row = headerRowIndex + 1; row < lastRow; row++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row))
          .cellStyle = numberStyle;
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row))
          .cellStyle = numberStyle;
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row))
          .cellStyle = numberStyle;
    }

    final dir = await getTemporaryDirectory();
    final filePath = '${dir.path}/deplacements.xlsx';
    final bytes = excel.encode();
    if (bytes == null) return;
    final file = File(filePath);
    await file.writeAsBytes(bytes, flush: true);

    await Share.shareXFiles(
      [XFile(filePath)],
      text: 'Liste de mes déplacements et frais',
      subject: 'Déplacements et montants',
    );
  }

  @override
  Widget build(BuildContext context) {
    final cfg = widget.config;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/icons/icon_trajets.png',
              height: 32,
              width: 32,
            ),
            const SizedBox(width: 8),
            const Text('Mes déplacements'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettings,
          ),
          IconButton(
            icon: const Icon(Icons.ios_share),
            onPressed: _exportAndShareExcel,
          ),
        ],
      ),
      body: Column(
        children: [
          if (cfg.nom.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Utilisateur : ${cfg.nom}\nVéhicule : ${cfg.typeVehicule}, ${cfg.puissance}',
                style: TextStyle(
                  color: scheme.onPrimaryContainer,
                  fontSize: 14,
                ),
              ),
            ),
          ],
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
            child: Row(
              children: [
                const Text('Année :'),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: _selectedYear,
                  items: List.generate(5, (i) {
                    final year = DateTime.now().year - i;
                    return DropdownMenuItem(
                      value: year,
                      child: Text(year.toString()),
                    );
                  }),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _selectedYear = value;
                    });
                  },
                ),
                const Spacer(),
                Text(
                  '${_totalKmForYear(_selectedYear).toStringAsFixed(0)} km - '
                  '${_indemniteForYear(_selectedYear).toStringAsFixed(0)} € trajets',
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _filteredItems.isEmpty
                ? Center(
                    child: Text(
                      "Aucun déplacement pour cette année",
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredItems.length,
                    itemBuilder: (_, index) {
                      final d = _filteredItems[index];
                      return Dismissible(
                        key: ValueKey(d),
                        direction: DismissDirection.horizontal,
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(left: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        secondaryBackground: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (direction) async {
                          return await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Supprimer'),
                                  content: const Text(
                                      'Voulez-vous vraiment supprimer cette entrée ?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(false),
                                      child: const Text('Annuler'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(true),
                                      child: const Text('Supprimer'),
                                    ),
                                  ],
                                ),
                              ) ??
                              false;
                        },
                        onDismissed: (direction) async {
                          setState(() {
                            _items.remove(d);
                          });
                          await AppStorage.saveDeplacements(_items);
                        },
                        child: Card(
                          child: ListTile(
                            onLongPress: () => _editDeplacement(d),
                            leading: CircleAvatar(
                              backgroundColor: d.type == 'trajet'
                                  ? scheme.primary
                                  : scheme.secondary,
                              foregroundColor: scheme.onPrimary,
                              child: Text(
                                d.type == 'trajet'
                                    ? d.km.toStringAsFixed(0)
                                    : '€',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            title: Text(
                              d.raison,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              '${_dateFormat.format(d.date)} • ${d.type}',
                            ),
                            trailing: Text(
                              d.type == 'trajet'
                                  ? '${d.km.toStringAsFixed(1)} km'
                                  : '${d.montant.toStringAsFixed(2)} €',
                              style: TextStyle(
                                color: scheme.secondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              appVersion,
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addDeplacement,
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
    );
  }
}

// FICHIER : lib/main.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import 'deplacement_form_page.dart';
import 'settings_page.dart';
import 'storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final initialConfig = await AppStorage.loadConfig();
  final initialDeplacements = await AppStorage.loadDeplacements();

  runApp(MyApp(
    initialConfig: initialConfig,
    initialDeplacements: initialDeplacements,
  ));
}

class Deplacement {
  DateTime date;
  String raison;
  double km;

  Deplacement({required this.date, required this.raison, required this.km});
}

class TrajetType {
  String raison;
  double kmDefaut;

  TrajetType({required this.raison, required this.kmDefaut});
}

class UserConfig {
  String nom;
  String typeVehicule;
  double puissance;

  UserConfig({
    required this.nom,
    required this.typeVehicule,
    required this.puissance,
  });
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
        cardTheme: CardThemeData(
          color: colorScheme.surface,
          elevation: 2,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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

  @override
  void initState() {
    super.initState();
    _items = List<Deplacement>.from(widget.initialDeplacements);

    for (final d in _items) {
      final existeDeja = _trajets.any(
        (t) => t.raison == d.raison && t.kmDefaut == d.km,
      );
      if (!existeDeja) {
        _trajets.add(
          TrajetType(raison: d.raison, kmDefaut: d.km),
        );
      }
    }
  }

  Future<void> _addDeplacement() async {
    final result = await Navigator.of(context).push<Deplacement>(
      MaterialPageRoute(
        builder: (_) => DeplacementFormPage(
          trajetsConnus: _trajets,
        ),
      ),
    );
    if (result != null) {
      setState(() {
        _items.add(result);
        final existeDeja = _trajets.any(
          (t) => t.raison == result.raison && t.kmDefaut == result.km,
        );
        if (!existeDeja) {
          _trajets.add(
            TrajetType(raison: result.raison, kmDefaut: result.km),
          );
        }
      });
      AppStorage.saveDeplacements(_items);
    }
  }

  Future<void> _openSettings() async {
    final result = await Navigator.of(context).push<UserConfig>(
      MaterialPageRoute(
        builder: (_) => SettingsPage(
          configInitiale: widget.config,
        ),
      ),
    );
    if (result != null) {
      widget.onEditConfig(result);
    }
  }

  Future<void> _exportAndShareCsv() async {
    if (_items.isEmpty) return;

    List<String> header = ['date', 'raison', 'kilometres'];
    List<List<String>> rows = _items
        .map((d) => [
              _dateFormat.format(d.date),
              d.raison,
              d.km.toStringAsFixed(2),
            ])
        .toList();

    final dir = await getTemporaryDirectory();
    final filePath = '${dir.path}/deplacements.csv';
    final file = File(filePath);

    final buffer = StringBuffer();

    buffer.writeln('# Nom: ${widget.config.nom}');
    buffer.writeln('# Véhicule: ${widget.config.typeVehicule}');
    buffer.writeln('# Puissance: ${widget.config.puissance}');
    buffer.writeln(header.join(';'));

    for (var r in rows) {
      buffer.writeln(r.join(';'));
    }
    await file.writeAsString(buffer.toString());

    await Share.shareXFiles(
      [XFile(filePath)],
      text: 'Liste de mes déplacements',
      subject: 'Déplacements',
    );
  }

  @override
  Widget build(BuildContext context) {
    final cfg = widget.config;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes déplacements'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettings,
          ),
          IconButton(
            icon: const Icon(Icons.ios_share),
            onPressed: _exportAndShareCsv,
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
          Expanded(
            child: _items.isEmpty
                ? Center(
                    child: Text(
                      'Aucun déplacement pour l’instant',
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _items.length,
                    itemBuilder: (_, index) {
                      final d = _items[index];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: scheme.primary,
                            foregroundColor: scheme.onPrimary,
                            child: Text(
                              d.km.toStringAsFixed(0),
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
                            _dateFormat.format(d.date),
                          ),
                          trailing: Text(
                            '${d.km.toStringAsFixed(1)} km',
                            style: TextStyle(
                              color: scheme.secondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    },
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

import 'package:flutter/material.dart';
import 'models.dart';
import 'logic/calculator.dart';
import 'services/storage.dart';
import 'ui/widgets/user_header.dart';
import 'ui/widgets/deplacement_card.dart';
import 'ui/screens/settings_page.dart';
import 'ui/screens/deplacement_form_page.dart';
import 'ui/screens/export_choice_page.dart';
import 'ui/screens/help_page.dart'; // Import de la nouvelle page d'aide

const String appVersion = 'V1.1.5';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final UserConfig? loadedConfig = await AppStorage.loadConfig();
  final UserConfig finalConfig = loadedConfig ??
      UserConfig(
          nom: '', adresse: '', typeVehicule: 'thermique', puissance: 4.0);

  final List<Deplacement> loadedDeplacements =
      await AppStorage.loadDeplacements();

  runApp(MyApp(
    initialConfig: finalConfig,
    initialDeplacements: loadedDeplacements,
  ));
}

class MyApp extends StatefulWidget {
  final UserConfig initialConfig;
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
    _config = widget.initialConfig;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'KM CSF',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
        ),
      ),
      home: HomePage(
        config: _config,
        initialItems: widget.initialDeplacements,
        onConfigUpdate: (newConfig) {
          setState(() => _config = newConfig);
          AppStorage.saveConfig(newConfig);
        },
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final UserConfig config;
  final List<Deplacement> initialItems;
  final Function(UserConfig) onConfigUpdate;

  const HomePage({
    super.key,
    required this.config,
    required this.initialItems,
    required this.onConfigUpdate,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late List<Deplacement> _items;
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _items = List<Deplacement>.from(widget.initialItems);
    _sortItems();
  }

  void _sortItems() {
    _items.sort((a, b) => b.date.compareTo(a.date));
  }

  double get totalKm => _items
      .where((d) => d.date.year == _selectedYear && d.type == 'trajet')
      .fold(0.0, (sum, item) => sum + item.km);

  double get indemniteKm =>
      KMCalculator.calculIndemnite(config: widget.config, kmAnnuels: totalKm);

  double get totalFrais => _items
      .where((d) => d.date.year == _selectedYear && d.type == 'frais')
      .fold(0.0, (sum, item) => sum + item.montant);

  @override
  Widget build(BuildContext context) {
    final filteredItems =
        _items.where((d) => d.date.year == _selectedYear).toList();
    final double totalGlobal = indemniteKm + totalFrais;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Journal de Frais'),
        actions: [
          // --- BOUTON AIDE AJOUTÉ ICI ---
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Aide d\'utilisation',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HelpPage()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SettingsPage(
                  configInitiale: widget.config,
                  deplacementsActuels: _items,
                  onConfigChange: widget.onConfigUpdate,
                  onDataRestored: () async {
                    final restored = await AppStorage.loadDeplacements();
                    setState(() {
                      _items = restored;
                      _sortItems();
                    });
                  },
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.ios_share),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ExportChoicePage(
                  year: _selectedYear,
                  config: widget.config,
                  items: filteredItems,
                  totalKm: totalKm,
                  indemniteKm: indemniteKm,
                  totalFrais: totalFrais,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          UserHeader(config: widget.config, version: appVersion),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DropdownButton<int>(
                  value: _selectedYear,
                  items: List.generate(
                          5, (index) => DateTime.now().year - 2 + index)
                      .map((y) =>
                          DropdownMenuItem(value: y, child: Text(y.toString())))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedYear = v);
                  },
                ),
                Text(
                  '${totalGlobal.toStringAsFixed(2)} €',
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal),
                ),
              ],
            ),
          ),
          Expanded(
            child: filteredItems.isEmpty
                ? const Center(child: Text("Aucun mouvement enregistré"))
                : ListView.builder(
                    itemCount: filteredItems.length,
                    itemBuilder: (ctx, i) {
                      final item = filteredItems[i];
                      return DeplacementCard(
                        item: item,
                        onDelete: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text("Supprimer ?"),
                              content: const Text(
                                  "Voulez-vous vraiment effacer cette ligne ?"),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text("ANNULER")),
                                TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text("EFFACER",
                                        style: TextStyle(color: Colors.red))),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            setState(() => _items.remove(item));
                            AppStorage.saveDeplacements(_items);
                          }
                        },
                        onLongPress: () async {
                          final res = await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    DeplacementFormPage(itemToEdit: item)),
                          );
                          if (res != null && res is Deplacement) {
                            setState(() {
                              final index = _items.indexOf(item);
                              _items[index] = res;
                              _sortItems();
                            });
                            AppStorage.saveDeplacements(_items);
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final res = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DeplacementFormPage()),
          );
          if (res != null && res is Deplacement) {
            setState(() {
              _items.add(res);
              _sortItems();
            });
            AppStorage.saveDeplacements(_items);
          }
        },
        label: const Text('Ajouter'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
    );
  }
}

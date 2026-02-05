import 'package:flutter/material.dart';
import '../../models.dart';
import '../../logic/calculator.dart';
import '../../services/storage.dart';
import '../widgets/user_header.dart';
import '../widgets/deplacement_card.dart';
import 'settings_page.dart';
import 'deplacement_form_page.dart';
import 'export_choice_page.dart';
import 'help_page.dart';

class HomePage extends StatefulWidget {
  final UserConfig config;
  final List<Deplacement> initialItems;
  final Function(UserConfig) onConfigUpdate;
  final String appVersion;

  const HomePage({
    super.key,
    required this.config,
    required this.initialItems,
    required this.onConfigUpdate,
    required this.appVersion,
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
      // Utilisation du Stack pour superposer le logo et le contenu
      body: Stack(
        children: [
          // 1. LE LOGO EN FILIGRANE (FOND)
          Center(
            child: Opacity(
              opacity: 0.1, // Logo très léger pour ne pas gêner la lecture
              child: Image.asset(
                'assets/images/logo_csf.png',
                width: MediaQuery.of(context).size.width *
                    0.7, // 70% de la largeur
                fit: BoxFit.contain,
              ),
            ),
          ),

          // 2. LE CONTENU (PAR-DESSUS)
          Column(
            children: [
              UserHeader(config: widget.config, version: widget.appVersion),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    DropdownButton<int>(
                      value: _selectedYear,
                      items: List.generate(
                              5, (index) => DateTime.now().year - 2 + index)
                          .map((y) => DropdownMenuItem(
                              value: y, child: Text(y.toString())))
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
                        backgroundColor: Colors.transparent, // Fond invisible
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
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: const Text("ANNULER")),
                                    TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        child: const Text("EFFACER",
                                            style:
                                                TextStyle(color: Colors.red))),
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

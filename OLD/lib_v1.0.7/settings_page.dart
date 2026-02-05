// FICHIER : lib/settings_page.dart

import 'package:flutter/material.dart';
import 'storage.dart';
import 'backups_page.dart';

class SettingsPage extends StatefulWidget {
  final UserConfig configInitiale;
  final List deplacementsActuels;
  final void Function(UserConfig) onConfigChange;
  final Future<void> Function() onDataRestored;

  const SettingsPage({
    super.key,
    required this.configInitiale,
    required this.deplacementsActuels,
    required this.onConfigChange,
    required this.onDataRestored,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nomController;
  late TextEditingController _adresseController; // AJOUTÉ
  String _typeVehicule = 'thermique';
  double _puissance = 0;

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController(text: widget.configInitiale.nom);
    _adresseController =
        TextEditingController(text: widget.configInitiale.adresse); // AJOUTÉ
    _typeVehicule = widget.configInitiale.typeVehicule;
    final p = widget.configInitiale.puissance;

    if (p <= 0) {
      _puissance = 0;
    } else if (p <= 3) {
      _puissance = 3;
    } else if (p <= 4) {
      _puissance = 4;
    } else if (p <= 5) {
      _puissance = 5;
    } else if (p <= 6) {
      _puissance = 6;
    } else {
      _puissance = 7;
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _adresseController.dispose(); // AJOUTÉ
    super.dispose();
  }

  UserConfig _buildConfig() {
    return UserConfig(
      nom: _nomController.text.trim(),
      adresse: _adresseController.text.trim(), // AJOUTÉ
      typeVehicule: _typeVehicule,
      puissance: _puissance,
      baremeCustom:
          widget.configInitiale.baremeCustom, // On garde le barème actuel
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final cfg = _buildConfig();
    widget.onConfigChange(cfg);
    Navigator.of(context).pop(cfg);
  }

  Future<void> _openBackupsPage() async {
    final restored = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const BackupsPage()),
    );

    if (restored == true) {
      final newCfg = await AppStorage.loadConfig();
      if (newCfg != null) {
        widget.onConfigChange(newCfg);
        setState(() {
          _nomController.text = newCfg.nom;
          _adresseController.text = newCfg.adresse; // AJOUTÉ
          _typeVehicule = newCfg.typeVehicule;
          _puissance = newCfg.puissance;
        });
      }
      await widget.onDataRestored();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Configuration')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: scheme.primary,
                        foregroundColor: scheme.onPrimary,
                        child: const Icon(Icons.person),
                      ),
                      const SizedBox(width: 12),
                      const Text('Profil & véhicule',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // NOM
                  TextFormField(
                    controller: _nomController,
                    decoration: const InputDecoration(
                        labelText: 'Nom de la personne',
                        border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),

                  // ADRESSE (INSERTION CHIRURGICALE)
                  TextFormField(
                    controller: _adresseController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Adresse complète',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // TYPE VEHICULE
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                        labelText: 'Type de véhicule',
                        border: OutlineInputBorder()),
                    value: _typeVehicule,
                    items: const [
                      DropdownMenuItem(
                          value: 'thermique', child: Text('Thermique')),
                      DropdownMenuItem(
                          value: 'electrique', child: Text('Électrique')),
                    ],
                    onChanged: (v) => setState(() => _typeVehicule = v!),
                  ),
                  const SizedBox(height: 12),

                  // PUISSANCE
                  DropdownButtonFormField<double>(
                    decoration: const InputDecoration(
                        labelText: 'Puissance fiscale (CV)',
                        border: OutlineInputBorder()),
                    value: _puissance == 0 ? null : _puissance,
                    items: const [
                      DropdownMenuItem(value: 3, child: Text('3 CV et moins')),
                      DropdownMenuItem(value: 4, child: Text('4 CV')),
                      DropdownMenuItem(value: 5, child: Text('5 CV')),
                      DropdownMenuItem(value: 6, child: Text('6 CV')),
                      DropdownMenuItem(value: 7, child: Text('7 CV et plus')),
                    ],
                    onChanged: (v) => setState(() => _puissance = v!),
                    validator: (v) =>
                        (v == null || v == 0) ? 'Choisis une puissance' : null,
                  ),

                  const SizedBox(height: 24),

                  // BOUTON ENREGISTRER (EN PREMIER)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.check),
                      label: const Text('Enregistrer'),
                    ),
                  ),

                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),

                  // BLOC SAUVEGARDE (EN DERNIER)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Sauvegardes',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: scheme.primary)),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _openBackupsPage,
                      icon: const Icon(Icons.backup),
                      label: const Text('Gestion des sauvegardes'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

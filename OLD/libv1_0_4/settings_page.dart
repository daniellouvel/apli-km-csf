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
  String _typeVehicule = 'thermique';
  double _puissance = 0;

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController(text: widget.configInitiale.nom);
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
    super.dispose();
  }

  UserConfig _buildConfig() {
    return UserConfig(
      nom: _nomController.text.trim(),
      typeVehicule: _typeVehicule,
      puissance: _puissance,
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final cfg = _buildConfig();
    widget.onConfigChange(cfg);
    Navigator.of(context).pop(cfg);
  }

  Future<void> _openBackupsPage() async {
    // on ouvre la page de gestion des sauvegardes
    final restored = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const BackupsPage(),
      ),
    );

    // si l'utilisateur a restauré une sauvegarde (BackupsPage fait pop(true))
    if (restored == true) {
      // recharger la config depuis le stockage
      final newCfg = await AppStorage.loadConfig();
      if (newCfg != null) {
        widget.onConfigChange(newCfg);
        setState(() {
          _nomController.text = newCfg.nom;
          _typeVehicule = newCfg.typeVehicule;
          final p = newCfg.puissance;
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
        });
      }
      // recharger la liste des déplacements dans HomePage
      await widget.onDataRestored();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuration'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
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
                      const Text(
                        'Profil & véhicule',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nomController,
                    decoration: const InputDecoration(
                      labelText: 'Nom de la personne',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Type de véhicule',
                      border: OutlineInputBorder(),
                    ),
                    value: _typeVehicule,
                    items: const [
                      DropdownMenuItem(
                        value: 'thermique',
                        child: Text('Thermique'),
                      ),
                      DropdownMenuItem(
                        value: 'electrique',
                        child: Text('Électrique'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _typeVehicule = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<double>(
                    decoration: const InputDecoration(
                      labelText: 'Puissance fiscale (CV)',
                      border: OutlineInputBorder(),
                    ),
                    value: _puissance == 0 ? null : _puissance,
                    items: const [
                      DropdownMenuItem(
                        value: 3,
                        child: Text('3 CV et moins'),
                      ),
                      DropdownMenuItem(
                        value: 4,
                        child: Text('4 CV'),
                      ),
                      DropdownMenuItem(
                        value: 5,
                        child: Text('5 CV'),
                      ),
                      DropdownMenuItem(
                        value: 6,
                        child: Text('6 CV'),
                      ),
                      DropdownMenuItem(
                        value: 7,
                        child: Text('7 CV et plus'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _puissance = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value == 0) {
                        return 'Choisis une puissance';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Sauvegardes',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: scheme.primary,
                      ),
                    ),
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
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.check),
                      label: const Text('Enregistrer'),
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

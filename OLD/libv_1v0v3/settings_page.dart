// FICHIER : lib/settings_page.dart

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import 'main.dart';
import 'storage.dart';

class SettingsPage extends StatefulWidget {
  final UserConfig configInitiale;
  final List<Deplacement> deplacementsActuels;
  final void Function(UserConfig) onConfigChange;

  const SettingsPage({
    super.key,
    required this.configInitiale,
    required this.deplacementsActuels,
    required this.onConfigChange,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nomController;
  String _typeVehicule = 'thermique';
  double _puissance = 0; // valeur stockée (3,4,5,6,7)

  bool _isExporting = false;
  bool _isImporting = false;

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController(text: widget.configInitiale.nom);
    _typeVehicule = widget.configInitiale.typeVehicule;

    // normalise la puissance existante vers une des valeurs de la liste
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
      _puissance = 7; // 7 CV et plus
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

  Future<void> _exportBackup() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);

    try {
      final cfg = _buildConfig();
      // Sauvegarde d’abord la config dans le stockage normal
      await AppStorage.saveConfig(cfg);

      // Fichier de backup complet
      final file = await AppStorage.exportBackup(
        config: cfg,
        deplacements: widget.deplacementsActuels,
      );

      // Partage du fichier (pour l’envoyer sur Drive, mail, etc.)
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Sauvegarde km_csf',
        text: 'Fichier de sauvegarde km_csf_backup.json',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Backup créé : ${file.path}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la sauvegarde : $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _importBackup() async {
    if (_isImporting) return;
    setState(() => _isImporting = true);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      ); // le picker se rouvre souvent sur le dernier dossier utilisé [web:29][web:32]

      if (result == null || result.files.isEmpty) {
        return; // annulé
      }

      final path = result.files.single.path;
      if (path == null) {
        throw Exception('Chemin de fichier invalide');
      }

      final file = File(path);
      final content = await file.readAsString();

      await AppStorage.importBackupFromJsonString(content);

      // On recharge la config depuis le stockage
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Données restaurées')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la restauration : $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
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

                  // Boutons sauvegarde / restauration
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Sauvegarde',
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
                    child: ElevatedButton.icon(
                      onPressed: _isExporting ? null : _exportBackup,
                      icon: const Icon(Icons.save_alt),
                      label: Text(
                        _isExporting
                            ? 'Sauvegarde en cours...'
                            : 'Sauvegarder mes données',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isImporting ? null : _importBackup,
                      icon: const Icon(Icons.restore),
                      label: Text(
                        _isImporting
                            ? 'Restauration en cours...'
                            : 'Restaurer mes données',
                      ),
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

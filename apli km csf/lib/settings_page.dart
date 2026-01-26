// FICHIER : lib/settings_page.dart

import 'package:flutter/material.dart';

import 'main.dart';

class SettingsPage extends StatefulWidget {
  final UserConfig configInitiale;

  const SettingsPage({
    super.key,
    required this.configInitiale,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomController;
  late TextEditingController _puissanceController;
  String _typeVehicule = 'thermique';

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController(text: widget.configInitiale.nom);
    _puissanceController = TextEditingController(
      text: widget.configInitiale.puissance == 0
          ? ''
          : widget.configInitiale.puissance.toString(),
    );
    _typeVehicule = widget.configInitiale.typeVehicule;
  }

  @override
  void dispose() {
    _nomController.dispose();
    _puissanceController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final puissance =
        double.tryParse(_puissanceController.text.replaceAll(',', '.')) ?? 0;

    final cfg = UserConfig(
      nom: _nomController.text.trim(),
      typeVehicule: _typeVehicule,
      puissance: puissance,
    );

    Navigator.of(context).pop(cfg);
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
                  TextFormField(
                    controller: _puissanceController,
                    decoration: const InputDecoration(
                      labelText: 'Puissance (kW ou CV)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return null;
                      }
                      if (double.tryParse(value.replaceAll(',', '.')) == null) {
                        return 'Nombre invalide';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.save),
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

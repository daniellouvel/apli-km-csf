import 'package:flutter/material.dart';
import '../../models.dart';
import '../../services/storage.dart';
import 'backups_page.dart';

class SettingsPage extends StatefulWidget {
  final UserConfig configInitiale;
  final List<Deplacement> deplacementsActuels;
  final Function(UserConfig) onConfigChange;
  final VoidCallback onDataRestored;

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
  late TextEditingController _nomController;
  late TextEditingController _adresseController;
  late String _typeVehicule;
  late double _puissance;

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController(text: widget.configInitiale.nom);
    _adresseController =
        TextEditingController(text: widget.configInitiale.adresse);
    _typeVehicule = widget.configInitiale.typeVehicule;
    _puissance = widget.configInitiale.puissance;
  }

  void _save() {
    final newConfig = UserConfig(
      nom: _nomController.text,
      adresse: _adresseController.text,
      typeVehicule: _typeVehicule,
      puissance: _puissance,
      baremeCustom: widget.configInitiale.baremeCustom,
    );
    widget.onConfigChange(newConfig);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Profil enregistré")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Paramètres")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text("Profil",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal)),
          const SizedBox(height: 10),
          TextField(
              controller: _nomController,
              decoration: const InputDecoration(
                  labelText: "Nom / Prénom", border: OutlineInputBorder())),
          const SizedBox(height: 10),
          TextField(
              controller: _adresseController,
              decoration: const InputDecoration(
                  labelText: "Adresse", border: OutlineInputBorder())),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            value: _typeVehicule,
            items: const [
              DropdownMenuItem(value: "thermique", child: Text("Thermique")),
              DropdownMenuItem(value: "electrique", child: Text("Électrique")),
            ],
            onChanged: (v) => setState(() => _typeVehicule = v!),
            decoration: const InputDecoration(labelText: "Type de moteur"),
          ),
          DropdownButtonFormField<double>(
            value: _puissance,
            items: [3.0, 4.0, 5.0, 6.0, 7.0]
                .map((p) =>
                    DropdownMenuItem(value: p, child: Text("${p.toInt()} CV")))
                .toList(),
            onChanged: (v) => setState(() => _puissance = v!),
            decoration: const InputDecoration(labelText: "Puissance fiscale"),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal, foregroundColor: Colors.white),
              child: const Text("ENREGISTRER LE PROFIL")),
          const Divider(height: 40),
          ListTile(
            leading: const Icon(Icons.history, color: Colors.orange),
            title: const Text("Gestion des sauvegardes"),
            subtitle: const Text("Envoyer, Restaurer ou Supprimer"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () async {
              final bool? restored = await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const BackupsPage()));
              if (restored == true) {
                // MISE A JOUR IMMEDIATE DES CHAMPS APRES RESTAURATION
                final newCfg = await AppStorage.loadConfig();
                if (newCfg != null) {
                  setState(() {
                    _nomController.text = newCfg.nom;
                    _adresseController.text = newCfg.adresse;
                    _typeVehicule = newCfg.typeVehicule;
                    _puissance = newCfg.puissance;
                  });
                  widget.onConfigChange(newCfg);
                }
                widget.onDataRestored();
              }
            },
          ),
        ],
      ),
    );
  }
}

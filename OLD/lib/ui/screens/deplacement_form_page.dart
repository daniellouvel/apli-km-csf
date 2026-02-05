import 'package:flutter/material.dart';
import '../../models.dart';
import '../../services/storage.dart';

class DeplacementFormPage extends StatefulWidget {
  final Deplacement? itemToEdit;
  const DeplacementFormPage({super.key, this.itemToEdit});

  @override
  State<DeplacementFormPage> createState() => _DeplacementFormPageState();
}

class _DeplacementFormPageState extends State<DeplacementFormPage> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _selectedDate;
  late TextEditingController _raisonController;
  late TextEditingController _kmController;
  late TextEditingController _montantController;
  String _type = 'trajet';

  // Liste des trajets pour la liste déroulante
  List<Deplacement> _historiqueTrajets = [];

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.itemToEdit?.date ?? DateTime.now();
    _raisonController =
        TextEditingController(text: widget.itemToEdit?.raison ?? '');
    _kmController = TextEditingController(
        text:
            widget.itemToEdit?.km != 0 ? widget.itemToEdit?.km.toString() : '');
    _montantController = TextEditingController(
        text: widget.itemToEdit?.montant != 0
            ? widget.itemToEdit?.montant.toString()
            : '');
    _type = widget.itemToEdit?.type ?? 'trajet';
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final all = await AppStorage.loadDeplacements();
    final Map<String, Deplacement> mapUnique = {};

    // On récupère les trajets uniques (Raison + KM)
    for (var d in all.where((e) => e.type == 'trajet')) {
      if (!mapUnique.containsKey(d.raison)) {
        mapUnique[d.raison] = d;
      }
    }
    setState(() {
      _historiqueTrajets = mapUnique.values.toList();
    });
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(
          context,
          Deplacement(
            date: _selectedDate,
            raison: _raisonController.text,
            km: double.tryParse(_kmController.text) ?? 0.0,
            montant: double.tryParse(_montantController.text) ?? 0.0,
            type: _type,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.itemToEdit == null ? "Ajouter" : "Modifier")),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Sélecteur Trajet / Frais
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                    value: 'trajet',
                    label: Text('Trajet'),
                    icon: Icon(Icons.directions_car)),
                ButtonSegment(
                    value: 'frais',
                    label: Text('Frais'),
                    icon: Icon(Icons.euro)),
              ],
              selected: {_type},
              onSelectionChanged: (val) => setState(() => _type = val.first),
            ),
            const SizedBox(height: 20),

            // Champ Motif
            TextFormField(
              controller: _raisonController,
              decoration: const InputDecoration(
                labelText: "Motif / Destination",
                border: OutlineInputBorder(),
              ),
              validator: (v) => v!.isEmpty ? "Obligatoire" : null,
            ),

            const SizedBox(height: 15),

            // Sélecteur de Date
            ListTile(
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: Colors.grey, width: 0.5),
                borderRadius: BorderRadius.circular(4),
              ),
              title: Text(
                  "Date : ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}"),
              trailing: const Icon(Icons.calendar_month),
              onTap: () async {
                final d = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2022),
                    lastDate: DateTime(2030));
                if (d != null) setState(() => _selectedDate = d);
              },
            ),

            const SizedBox(height: 15),

            if (_type == 'trajet') ...[
              // Champ Kilomètres
              TextFormField(
                controller: _kmController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: "Kilomètres",
                    suffixText: "km",
                    border: OutlineInputBorder()),
                validator: (v) =>
                    double.tryParse(v!) == null ? "Invalide" : null,
              ),

              const SizedBox(height: 15),

              // --- LISTE DÉROULANTE (DROPDOWN) POUR ENTRÉE RAPIDE ---
              if (_historiqueTrajets.isNotEmpty)
                DropdownButtonFormField<Deplacement>(
                  decoration: const InputDecoration(
                    labelText: "Entrée rapide (Trajets fréquents)",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.bolt, color: Colors.orange),
                  ),
                  items: _historiqueTrajets.map((d) {
                    return DropdownMenuItem<Deplacement>(
                      value: d,
                      child: Text("${d.raison} (${d.km} km)"),
                    );
                  }).toList(),
                  onChanged: (Deplacement? selection) {
                    if (selection != null) {
                      setState(() {
                        _raisonController.text = selection.raison;
                        _kmController.text = selection.km.toString();
                      });
                    }
                  },
                ),
            ] else ...[
              // Champ Montant pour les Frais
              TextFormField(
                controller: _montantController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: "Montant",
                    suffixText: "€",
                    border: OutlineInputBorder()),
                validator: (v) =>
                    double.tryParse(v!) == null ? "Invalide" : null,
              ),
            ],

            const SizedBox(height: 30),

            // Bouton de validation
            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 55),
              ),
              child: const Text("ENREGISTRER",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

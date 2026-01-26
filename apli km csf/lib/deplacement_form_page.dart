// FICHIER : lib/deplacement_form_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'main.dart';

class DeplacementFormPage extends StatefulWidget {
  final List<TrajetType> trajetsConnus;

  const DeplacementFormPage({
    super.key,
    required this.trajetsConnus,
  });

  @override
  State<DeplacementFormPage> createState() => _DeplacementFormPageState();
}

class _DeplacementFormPageState extends State<DeplacementFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _raisonController = TextEditingController();
  final _kmController = TextEditingController();
  DateTime _date = DateTime.now();
  final _dateFormat = DateFormat('yyyy-MM-dd');

  TrajetType? _trajetChoisi;

  @override
  void dispose() {
    _raisonController.dispose();
    _kmController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _date = picked;
      });
    }
  }

  void _onTrajetSelected(TrajetType? value) {
    setState(() {
      _trajetChoisi = value;
      if (value != null) {
        _raisonController.text = value.raison;
        _kmController.text = value.kmDefaut.toStringAsFixed(2);
      }
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final km = double.tryParse(_kmController.text.replaceAll(',', '.'));
    if (km == null) return;

    final dep = Deplacement(
      date: _date,
      raison: _raisonController.text.trim(),
      km: km,
    );

    Navigator.of(context).pop(dep);
  }

  @override
  Widget build(BuildContext context) {
    final hasTrajets = widget.trajetsConnus.isNotEmpty;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouveau déplacement'),
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
                      Icon(Icons.calendar_today, color: scheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Date : ${_dateFormat.format(_date)}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      TextButton(
                        onPressed: _pickDate,
                        child: const Text('Changer'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (hasTrajets) ...[
                    DropdownButtonFormField<TrajetType>(
                      decoration: const InputDecoration(
                        labelText: 'Trajet (pré-rempli)',
                        border: OutlineInputBorder(),
                      ),
                      value: _trajetChoisi,
                      items: widget.trajetsConnus
                          .map(
                            (t) => DropdownMenuItem<TrajetType>(
                              value: t,
                              child: Text('${t.raison} (${t.kmDefaut} km)'),
                            ),
                          )
                          .toList(),
                      onChanged: _onTrajetSelected,
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextFormField(
                    controller: _raisonController,
                    decoration: const InputDecoration(
                      labelText: 'Raison',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.route),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Indique une raison';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _kmController,
                    decoration: const InputDecoration(
                      labelText: 'Kilomètres',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.speed),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Indique le nombre de km';
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

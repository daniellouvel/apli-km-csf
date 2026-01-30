// FICHIER : lib/deplacement_form_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'main.dart'; // pour Deplacement et TrajetType

const String appVersion = 'V1_0_1';

class DeplacementFormPage extends StatefulWidget {
  final List<TrajetType> trajetsConnus;
  final Deplacement? deplacementInitial; // null = création, non null = édition

  const DeplacementFormPage({
    super.key,
    required this.trajetsConnus,
    this.deplacementInitial,
  });

  @override
  State<DeplacementFormPage> createState() => _DeplacementFormPageState();
}

class _DeplacementFormPageState extends State<DeplacementFormPage> {
  // Trajet
  final _formKeyTrajet = GlobalKey<FormState>();
  final _dateControllerTrajet = TextEditingController();
  final _raisonControllerTrajet = TextEditingController();
  final _kmControllerTrajet = TextEditingController();
  DateTime _selectedDateTrajet = DateTime.now();

  // Frais
  final _formKeyFrais = GlobalKey<FormState>();
  final _dateControllerFrais = TextEditingController();
  final _raisonControllerFrais = TextEditingController();
  final _montantControllerFrais = TextEditingController();
  DateTime _selectedDateFrais = DateTime.now();

  final _dateFormat = DateFormat('yyyy-MM-dd');

  int _selectedTabIndex = 0; // 0 = Trajet, 1 = Frais

  bool get _isEdition => widget.deplacementInitial != null;

  @override
  void initState() {
    super.initState();

    // Valeurs par défaut
    _selectedDateTrajet = DateTime.now();
    _selectedDateFrais = DateTime.now();

    // Si on est en édition, pré-remplir les champs
    final dep = widget.deplacementInitial;
    if (dep != null) {
      if (dep.type == 'trajet') {
        _selectedTabIndex = 0;
        _selectedDateTrajet = dep.date;
        _dateControllerTrajet.text = _dateFormat.format(dep.date);
        _raisonControllerTrajet.text = dep.raison;
        _kmControllerTrajet.text = dep.km.toStringAsFixed(2);
      } else {
        _selectedTabIndex = 1;
        _selectedDateFrais = dep.date;
        _dateControllerFrais.text = _dateFormat.format(dep.date);
        _raisonControllerFrais.text = dep.raison;
        _montantControllerFrais.text = dep.montant.toStringAsFixed(2);
      }
    } else {
      // Création
      _dateControllerTrajet.text = _dateFormat.format(_selectedDateTrajet);
      _dateControllerFrais.text = _dateFormat.format(_selectedDateFrais);
    }
  }

  @override
  void dispose() {
    _dateControllerTrajet.dispose();
    _raisonControllerTrajet.dispose();
    _kmControllerTrajet.dispose();

    _dateControllerFrais.dispose();
    _raisonControllerFrais.dispose();
    _montantControllerFrais.dispose();
    super.dispose();
  }

  Future<void> _pickDateTrajet() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateTrajet,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDateTrajet = picked;
        _dateControllerTrajet.text = _dateFormat.format(picked);
      });
    }
  }

  Future<void> _pickDateFrais() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateFrais,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDateFrais = picked;
        _dateControllerFrais.text = _dateFormat.format(picked);
      });
    }
  }

  void _submitTrajet() {
    if (!_formKeyTrajet.currentState!.validate()) return;

    final km =
        double.tryParse(_kmControllerTrajet.text.replaceAll(',', '.')) ?? 0.0;
    final dep = Deplacement(
      date: _selectedDateTrajet,
      raison: _raisonControllerTrajet.text.trim(),
      km: km,
      type: 'trajet',
      montant: 0.0,
    );
    Navigator.of(context).pop(dep);
  }

  void _submitFrais() {
    if (!_formKeyFrais.currentState!.validate()) return;

    final montant =
        double.tryParse(_montantControllerFrais.text.replaceAll(',', '.')) ??
            0.0;
    final dep = Deplacement(
      date: _selectedDateFrais,
      raison: _raisonControllerFrais.text.trim(),
      km: 0.0,
      type: 'frais',
      montant: montant,
    );
    Navigator.of(context).pop(dep);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdition ? 'Modifier le mouvement' : 'Nouveau mouvement'),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          ToggleButtons(
            isSelected: [
              _selectedTabIndex == 0,
              _selectedTabIndex == 1,
            ],
            onPressed: (index) {
              setState(() {
                _selectedTabIndex = index;
              });
            },
            borderRadius: BorderRadius.circular(8),
            selectedColor: scheme.onPrimary,
            fillColor: scheme.primary,
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text('Trajet'),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text('Frais'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _selectedTabIndex == 0
                  ? _buildTrajetForm(context)
                  : _buildFraisForm(context),
            ),
          ),
        ],
      ),
    );
  }

  // -------- Formulaire Trajet --------

  Widget _buildTrajetForm(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasTrajets = widget.trajetsConnus.isNotEmpty;

    return SingleChildScrollView(
      key: const ValueKey('trajet'),
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKeyTrajet,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trajet au kilomètre',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _dateControllerTrajet,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Date',
                prefixIcon: Icon(Icons.calendar_today),
              ),
              onTap: _pickDateTrajet,
            ),
            const SizedBox(height: 16),
            if (hasTrajets && !_isEdition) ...[
              DropdownButtonFormField<TrajetType>(
                decoration: const InputDecoration(
                  labelText: 'Trajet (pré-rempli)',
                  border: OutlineInputBorder(),
                ),
                items: widget.trajetsConnus
                    .map(
                      (t) => DropdownMenuItem<TrajetType>(
                        value: t,
                        child: Text('${t.raison} (${t.kmDefaut} km)'),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  _raisonControllerTrajet.text = value.raison;
                  _kmControllerTrajet.text = value.kmDefaut.toStringAsFixed(2);
                },
              ),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: _raisonControllerTrajet,
              decoration: const InputDecoration(
                labelText: 'Raison / libellé',
                prefixIcon: Icon(Icons.directions_car),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Veuillez saisir une raison';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _kmControllerTrajet,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Kilomètres',
                prefixIcon: Icon(Icons.straighten),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Veuillez saisir le nombre de kilomètres';
                }
                final km = double.tryParse(value.replaceAll(',', '.'));
                if (km == null || km <= 0) {
                  return 'Kilomètres invalides';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.check),
                label: Text(_isEdition
                    ? 'Mettre à jour le trajet'
                    : 'Enregistrer le trajet'),
                onPressed: _submitTrajet,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------- Formulaire Frais --------

  Widget _buildFraisForm(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      key: const ValueKey('frais'),
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKeyFrais,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Frais (montant direct)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _dateControllerFrais,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Date',
                prefixIcon: Icon(Icons.calendar_today),
              ),
              onTap: _pickDateFrais,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _raisonControllerFrais,
              decoration: const InputDecoration(
                labelText: 'Libellé du frais',
                prefixIcon: Icon(Icons.receipt_long),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Veuillez saisir un libellé';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _montantControllerFrais,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Montant à défiscaliser (€)',
                prefixIcon: Icon(Icons.euro),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Veuillez saisir un montant';
                }
                final m = double.tryParse(value.replaceAll(',', '.'));
                if (m == null || m <= 0) {
                  return 'Montant invalide';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.check),
                label: Text(_isEdition
                    ? 'Mettre à jour le frais'
                    : 'Enregistrer le frais'),
                onPressed: _submitFrais,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

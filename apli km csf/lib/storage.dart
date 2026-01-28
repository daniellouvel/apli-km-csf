// FICHIER : lib/storage.dart

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'main.dart'; // pour accéder à UserConfig et Deplacement

class AppStorage {
  static const _keyConfig = 'user_config';
  static const _keyDeplacements = 'deplacements';

  /// Sauvegarde la configuration utilisateur (nom, type de véhicule, puissance)
  static Future<void> saveConfig(UserConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    final map = {
      'nom': config.nom,
      'typeVehicule': config.typeVehicule,
      'puissance': config.puissance,
    };
    await prefs.setString(_keyConfig, jsonEncode(map));
  }

  /// Charge la configuration utilisateur
  static Future<UserConfig?> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyConfig);
    if (jsonStr == null) return null;

    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return UserConfig(
        nom: map['nom'] as String? ?? '',
        typeVehicule: map['typeVehicule'] as String? ?? 'thermique',
        puissance: (map['puissance'] as num?)?.toDouble() ?? 0.0,
      );
    } catch (_) {
      return null;
    }
  }

  /// Sauvegarde la liste des déplacements (trajets + frais)
  static Future<void> saveDeplacements(List<Deplacement> items) async {
    final prefs = await SharedPreferences.getInstance();

    final list = items.map((d) {
      return {
        'date': d.date.toIso8601String(),
        'raison': d.raison,
        'km': d.km,
        'type': d.type, // 'trajet' ou 'frais'
        'montant': d.montant, // montant à défiscaliser pour les frais
      };
    }).toList();

    await prefs.setString(_keyDeplacements, jsonEncode(list));
  }

  /// Charge la liste des déplacements
  ///
  /// Compatibilité ascendante :
  /// - si 'type' n'existe pas, on considère que c'est un 'trajet'
  /// - si 'montant' n'existe pas, il vaut 0.0 (on recalculera à l'export si besoin)
  static Future<List<Deplacement>> loadDeplacements() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyDeplacements);
    if (jsonStr == null) return [];

    try {
      final list = jsonDecode(jsonStr) as List<dynamic>;
      return list.map((e) {
        final map = e as Map<String, dynamic>;

        final dateStr = map['date'] as String? ?? '';
        final raison = map['raison'] as String? ?? '';
        final km = (map['km'] as num?)?.toDouble() ?? 0.0;
        final type = map['type'] as String? ?? 'trajet';
        final montant = (map['montant'] as num?)?.toDouble() ?? 0.0;

        DateTime date;
        try {
          date = DateTime.parse(dateStr);
        } catch (_) {
          date = DateTime.now();
        }

        return Deplacement(
          date: date,
          raison: raison,
          km: km,
          type: type,
          montant: montant,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  /// Réinitialiser toutes les données (optionnel)
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyConfig);
    await prefs.remove(_keyDeplacements);
  }
}

// FICHIER : lib/storage.dart

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'main.dart';

class AppStorage {
  static const _keyConfig = 'user_config';
  static const _keyDeplacements = 'deplacements';

  // ---- CONFIG ----

  static Future<void> saveConfig(UserConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    final map = {
      'nom': config.nom,
      'typeVehicule': config.typeVehicule,
      'puissance': config.puissance,
    };
    await prefs.setString(_keyConfig, jsonEncode(map));
  }

  static Future<UserConfig?> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_keyConfig);
    if (str == null) return null;
    try {
      final map = jsonDecode(str) as Map<String, dynamic>;
      return UserConfig(
        nom: map['nom'] as String? ?? '',
        typeVehicule: map['typeVehicule'] as String? ?? 'thermique',
        puissance: (map['puissance'] as num?)?.toDouble() ?? 0,
      );
    } catch (_) {
      return null;
    }
  }

  // ---- DEPLACEMENTS ----

  static Future<void> saveDeplacements(List<Deplacement> items) async {
    final prefs = await SharedPreferences.getInstance();
    final list = items
        .map(
          (d) => {
            'date': d.date.toIso8601String(),
            'raison': d.raison,
            'km': d.km,
          },
        )
        .toList();
    await prefs.setString(_keyDeplacements, jsonEncode(list));
  }

  static Future<List<Deplacement>> loadDeplacements() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_keyDeplacements);
    if (str == null) return [];
    try {
      final list = jsonDecode(str) as List<dynamic>;
      return list
          .map((e) => e as Map<String, dynamic>)
          .map(
            (map) => Deplacement(
              date: DateTime.parse(map['date'] as String),
              raison: map['raison'] as String? ?? '',
              km: (map['km'] as num?)?.toDouble() ?? 0,
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }
}

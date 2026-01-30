// FICHIER : lib/storage.dart

import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'main.dart'; // pour utiliser Deplacement et UserConfig

class AppStorage {
  static const _configKey = 'user_config';
  static const _fileName = 'deplacements.json';

  /// Charge la configuration utilisateur depuis SharedPreferences
  static Future<UserConfig?> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_configKey);
    if (jsonString == null) return null;

    try {
      final map = json.decode(jsonString) as Map<String, dynamic>;
      return UserConfig(
        nom: map['nom'] as String? ?? '',
        typeVehicule: map['typeVehicule'] as String? ?? 'thermique',
        puissance: (map['puissance'] as num?)?.toDouble() ?? 0,
      );
    } catch (_) {
      return null;
    }
  }

  /// Sauvegarde la configuration utilisateur
  static Future<void> saveConfig(UserConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    final map = {
      'nom': config.nom,
      'typeVehicule': config.typeVehicule,
      'puissance': config.puissance,
    };
    await prefs.setString(_configKey, json.encode(map));
  }

  /// Retourne le fichier JSON interne qui contient les déplacements
  static Future<File> _getDeplacementsFile() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/$_fileName';
    return File(path);
  }

  /// Charge la liste des déplacements depuis le JSON interne
  static Future<List<Deplacement>> loadDeplacements() async {
    try {
      final file = await _getDeplacementsFile();
      if (!await file.exists()) {
        return [];
      }
      final content = await file.readAsString();
      if (content.trim().isEmpty) return [];

      final data = json.decode(content);
      if (data is! List) return [];

      return data.map<Deplacement>((e) {
        final map = e as Map<String, dynamic>;
        return Deplacement(
          date: DateTime.parse(map['date'] as String),
          raison: map['raison'] as String? ?? '',
          km: (map['km'] as num?)?.toDouble() ?? 0.0,
          montant: (map['montant'] as num?)?.toDouble() ?? 0.0,
          type: map['type'] as String? ?? 'trajet',
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  /// Sauvegarde la liste des déplacements dans le JSON interne
  static Future<void> saveDeplacements(List<Deplacement> items) async {
    final file = await _getDeplacementsFile();
    final data = items.map((d) {
      return {
        'date': d.date.toIso8601String(),
        'raison': d.raison,
        'km': d.km,
        'montant': d.montant,
        'type': d.type,
      };
    }).toList();

    await file.writeAsString(
      json.encode(data),
      flush: true,
    );
  }
}

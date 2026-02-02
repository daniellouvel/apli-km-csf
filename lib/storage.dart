// FICHIER : lib/storage.dart

import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Modèles partagés ------------------------------------------------------

class Deplacement {
  DateTime date;
  String raison;
  double km;
  double montant; // pour les frais
  String type; // 'trajet' ou 'frais'

  Deplacement({
    required this.date,
    required this.raison,
    this.km = 0.0,
    this.montant = 0.0,
    this.type = 'trajet',
  });

  int get date_year => date.year;

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'raison': raison,
      'km': km,
      'montant': montant,
      'type': type,
    };
  }

  factory Deplacement.fromJson(Map<String, dynamic> map) {
    return Deplacement(
      date: DateTime.parse(map['date'] as String),
      raison: map['raison'] as String? ?? '',
      km: (map['km'] as num?)?.toDouble() ?? 0.0,
      montant: (map['montant'] as num?)?.toDouble() ?? 0.0,
      type: map['type'] as String? ?? 'trajet',
    );
  }
}

class UserConfig {
  String nom;
  String typeVehicule; // 'thermique' ou 'electrique'
  double puissance; // CV fiscaux

  UserConfig({
    required this.nom,
    required this.typeVehicule,
    required this.puissance,
  });

  Map<String, dynamic> toJson() {
    return {
      'nom': nom,
      'typeVehicule': typeVehicule,
      'puissance': puissance,
    };
  }

  factory UserConfig.fromJson(Map<String, dynamic> map) {
    return UserConfig(
      nom: map['nom'] as String? ?? '',
      typeVehicule: map['typeVehicule'] as String? ?? 'thermique',
      puissance: (map['puissance'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Stockage --------------------------------------------------------------

class AppStorage {
  static const _configKey = 'user_config';
  static const _fileName = 'deplacements.json';

  static Future<UserConfig?> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_configKey);
    if (jsonString == null) return null;
    try {
      final map = json.decode(jsonString) as Map<String, dynamic>;
      return UserConfig.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveConfig(UserConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_configKey, json.encode(config.toJson()));
  }

  static Future<File> _getDeplacementsFile() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/$_fileName';
    return File(path);
  }

  static Future<List<Deplacement>> loadDeplacements() async {
    try {
      final file = await _getDeplacementsFile();
      if (!await file.exists()) return [];
      final content = await file.readAsString();
      if (content.trim().isEmpty) return [];
      final data = json.decode(content);
      if (data is! List) return [];
      return data
          .map<Deplacement>((e) => Deplacement.fromJson(
                (e as Map).cast<String, dynamic>(),
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveDeplacements(List<Deplacement> items) async {
    final file = await _getDeplacementsFile();
    final data = items.map((d) => d.toJson()).toList();
    await file.writeAsString(json.encode(data), flush: true);
  }

  static Future<Map<String, dynamic>> _buildBackupData({
    required UserConfig config,
    required List<Deplacement> deplacements,
  }) async {
    return {
      'version': '1.0',
      'date_export': DateTime.now().toIso8601String(),
      'config': config.toJson(),
      'deplacements': deplacements.map((d) => d.toJson()).toList(),
    };
  }

  static Future<File?> exportBackupToPublicDocuments({
    required UserConfig config,
    required List<Deplacement> deplacements,
  }) async {
    try {
      final downloadsDir = await getDownloadsDirectory();
      if (downloadsDir == null) return null;
      final backupDir = Directory('${downloadsDir.path}/km_csf_backups');
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }
      final timestamp =
          DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final fileName = 'km_csf_backup_$timestamp.json';
      final file = File('${backupDir.path}/$fileName');
      final data = await _buildBackupData(
        config: config,
        deplacements: deplacements,
      );
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(data),
        flush: true,
      );
      return file;
    } catch (e) {
      print('Erreur exportBackupToPublicDocuments: $e');
      return null;
    }
  }

  static Future<String?> getBackupDirectoryPath() async {
    final downloadsDir = await getDownloadsDirectory();
    if (downloadsDir == null) return null;
    final backupDir = Directory('${downloadsDir.path}/km_csf_backups');
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    return backupDir.path;
  }

  static Future<List<File>> listBackups() async {
    final dirPath = await getBackupDirectoryPath();
    if (dirPath == null) return [];
    final dir = Directory(dirPath);
    if (!await dir.exists()) return [];
    final all = await dir.list().toList();
    all.sort((a, b) {
      final statA = (a is File) ? a.statSync().modified : DateTime(1970);
      final statB = (b is File) ? b.statSync().modified : DateTime(1970);
      return statB.compareTo(statA);
    });
    return all
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'))
        .toList();
  }

  static Future<void> importBackupFromJsonString(String jsonString) async {
    final data = jsonDecode(jsonString) as Map<String, dynamic>;
    final cfgMap = (data['config'] as Map).cast<String, dynamic>();
    final list = (data['deplacements'] as List)
        .map((e) => (e as Map).cast<String, dynamic>())
        .toList();
    final userConfig = UserConfig.fromJson(cfgMap);
    final deplacements = list.map((map) => Deplacement.fromJson(map)).toList();
    await saveConfig(userConfig);
    await saveDeplacements(deplacements);
  }
}

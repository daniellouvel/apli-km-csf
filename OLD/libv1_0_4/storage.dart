import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

// --- LES CLASSES DE DONNÉES (DOIVENT ÊTRE ICI) ---
class Deplacement {
  DateTime date;
  String raison;
  double km;
  double montant;
  String type;

  Deplacement(
      {required this.date,
      required this.raison,
      this.km = 0.0,
      this.montant = 0.0,
      this.type = 'trajet'});

  int get date_year => date.year; // Indispensable pour ton main.dart

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'raison': raison,
        'km': km,
        'montant': montant,
        'type': type,
      };

  factory Deplacement.fromJson(Map<String, dynamic> map) => Deplacement(
        date: DateTime.parse(map['date'] as String),
        raison: map['raison'] as String? ?? '',
        km: (map['km'] as num?)?.toDouble() ?? 0.0,
        montant: (map['montant'] as num?)?.toDouble() ?? 0.0,
        type: map['type'] as String? ?? 'trajet',
      );
}

class UserConfig {
  String nom;
  String typeVehicule;
  double puissance;
  UserConfig(
      {required this.nom, required this.typeVehicule, required this.puissance});
  Map<String, dynamic> toJson() =>
      {'nom': nom, 'typeVehicule': typeVehicule, 'puissance': puissance};
  factory UserConfig.fromJson(Map<String, dynamic> map) => UserConfig(
        nom: map['nom'] as String? ?? '',
        typeVehicule: map['typeVehicule'] as String? ?? 'thermique',
        puissance: (map['puissance'] as num?)?.toDouble() ?? 0,
      );
}

// --- LA LOGIQUE DE STOCKAGE ---
class AppStorage {
  static const _configKey = 'user_config';
  static const _fileName = 'deplacements.json';

  static Future<Directory> get _backupDir async {
    final directory = Directory('/storage/emulated/0/KM_CSF_Backups');
    if (!await directory.exists()) await directory.create(recursive: true);
    return directory;
  }

  // Fonctions pour le fonctionnement normal de l'app
  static Future<UserConfig?> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_configKey);
    return jsonString == null
        ? null
        : UserConfig.fromJson(json.decode(jsonString));
  }

  static Future<void> saveConfig(UserConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_configKey, json.encode(config.toJson()));
  }

  static Future<List<Deplacement>> loadDeplacements() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_fileName');
      if (!await file.exists()) return [];
      final content = await file.readAsString();
      final List data = json.decode(content);
      return data.map((e) => Deplacement.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> saveDeplacements(List<Deplacement> items) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$_fileName');
    await file.writeAsString(json.encode(items.map((d) => d.toJson()).toList()),
        flush: true);
  }

  // Logique de Sauvegarde Externe (Refonte)
  static Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      var status = await Permission.manageExternalStorage.request();
      if (status.isGranted) return true;
      // Si refusé via manageExternalStorage, on tente le stockage simple (Android < 11)
      status = await Permission.storage.request();
      return status.isGranted;
    }
    return true;
  }

  static Future<void> createAutoBackup(
      UserConfig config, List<Deplacement> items) async {
    if (!await requestPermissions()) return;
    final dir = await _backupDir;
    final String ts = DateTime.now().millisecondsSinceEpoch.toString();
    final file = File('${dir.path}/backup_$ts.json');
    final data = {
      'config': config.toJson(),
      'deplacements': items.map((d) => d.toJson()).toList(),
    };
    await file.writeAsString(jsonEncode(data), flush: true);
  }

  static Future<List<File>> listAllBackups() async {
    try {
      if (!await requestPermissions()) return [];
      final dir = await _backupDir;
      final List<FileSystemEntity> entities = dir.listSync();
      final files = entities
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList();
      files
          .sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      return files;
    } catch (e) {
      return [];
    }
  }

  static Future<void> deleteBackup(File file) async {
    if (await file.exists()) await file.delete();
  }

  static Future<void> import(File file) async {
    final content = await file.readAsString();
    final data = jsonDecode(content);
    await saveConfig(UserConfig.fromJson(data['config']));
    final list = (data['deplacements'] as List)
        .map((e) => Deplacement.fromJson(e))
        .toList();
    await saveDeplacements(list);
  }
}

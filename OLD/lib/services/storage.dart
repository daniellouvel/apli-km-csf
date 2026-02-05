import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models.dart';

class AppStorage {
  static const _configKey = 'user_config';
  static const _fileName = 'deplacements.json';

  static Future<Directory> get _backupDir async {
    final directory = Directory('/storage/emulated/0/Documents/KM_CSF_Backups');
    if (!await directory.exists()) await directory.create(recursive: true);
    return directory;
  }

  static Future<UserConfig?> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_configKey);
    return jsonString == null ? null : UserConfig.fromJson(json.decode(jsonString));
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
    } catch (e) { return []; }
  }

  static Future<void> saveDeplacements(List<Deplacement> items) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$_fileName');
    await file.writeAsString(json.encode(items.map((d) => d.toJson()).toList()), flush: true);
  }

  static Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      var status = await Permission.manageExternalStorage.request();
      if (status.isGranted) return true;
      status = await Permission.storage.request();
      return status.isGranted;
    }
    return true;
  }

  static Future<void> createBackup(UserConfig config, List<Deplacement> items) async {
    if (!await requestPermissions()) return;
    final dir = await _backupDir;
    final String ts = DateTime.now().millisecondsSinceEpoch.toString();
    final file = File('${dir.path}/backup_$ts.json');
    await file.writeAsString(jsonEncode({'config': config.toJson(), 'deplacements': items.map((d) => d.toJson()).toList()}), flush: true);
  }

  static Future<List<File>> listAllBackups() async {
    try {
      if (!await requestPermissions()) return [];
      final dir = await _backupDir;
      final files = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.json')).toList();
      files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      return files;
    } catch (e) { return []; }
  }

  static Future<void> deleteBackup(File file) async { if (await file.exists()) await file.delete(); }

  static Future<void> import(File file) async {
    final content = await file.readAsString();
    final data = jsonDecode(content);
    // RESTAURATION PROFIL
    if (data['config'] != null) {
      await saveConfig(UserConfig.fromJson(data['config']));
    }
    // RESTAURATION DÉPLACEMENTS
    if (data['deplacements'] != null) {
      final list = (data['deplacements'] as List).map((e) => Deplacement.fromJson(e)).toList();
      await saveDeplacements(list);
    }
  }
}
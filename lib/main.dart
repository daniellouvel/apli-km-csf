import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';

// Imports basés sur la structure standard
import 'package:km_csf/models.dart';
import 'package:km_csf/services/storage.dart';
import 'package:km_csf/ui/screens/home_page.dart';

late String appVersion;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    appVersion = 'V${packageInfo.version}';
  } catch (e) {
    appVersion = 'V1.1.5';
  }

  final UserConfig? loadedConfig = await AppStorage.loadConfig();
  final UserConfig finalConfig = loadedConfig ??
      UserConfig(
          nom: '', adresse: '', typeVehicule: 'thermique', puissance: 4.0);

  final List<Deplacement> loadedDeplacements =
      await AppStorage.loadDeplacements();

  runApp(MyApp(
    initialConfig: finalConfig,
    initialDeplacements: loadedDeplacements,
  ));
}

class MyApp extends StatefulWidget {
  final UserConfig initialConfig;
  final List<Deplacement> initialDeplacements;

  const MyApp({
    super.key,
    required this.initialConfig,
    required this.initialDeplacements,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late UserConfig _config;

  @override
  void initState() {
    super.initState();
    _config = widget.initialConfig;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'KM CSF',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('fr', 'FR')],
      locale: const Locale('fr', 'FR'),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
        ),
      ),
      home: HomePage(
        config: _config,
        initialItems: widget.initialDeplacements,
        appVersion: appVersion,
        onConfigUpdate: (newConfig) {
          setState(() => _config = newConfig);
          AppStorage.saveConfig(newConfig);
        },
      ),
    );
  }
}

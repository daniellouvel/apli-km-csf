# Documentation - Carnet de trajets

## Table des matières

1. [Vue d'ensemble](#vue-densemble)
2. [Architecture](#architecture)
3. [Guide de démarrage](#guide-de-démarrage)
4. [Structure des fichiers](#structure-des-fichiers)
5. [Modules principaux](#modules-principaux)
6. [Persistence des données](#persistence-des-données)
7. [Personnalisation](#personnalisation)
8. [Troubleshooting](#troubleshooting)

---

## Vue d'ensemble

**Carnet de trajets** est une application mobile Flutter pour Android permettant :

- **Enregistrer les trajets** : date, raison (destination), kilométrage.
- **Mémoriser les trajets** : suggestions automatiques des trajets précédents.
- **Configurer le profil** : nom, type de véhicule (thermique/électrique), puissance.
- **Exporter en CSV** : générer un fichier CSV avec tous les trajets + infos du profil.
- **Partager facilement** : envoyer le CSV par mail, WhatsApp, etc.
- **Conserver les données** : sauvegarde locale automatique (persiste après redémarrage et mises à jour).

**Cible** : conducteurs, livreurs, commerciaux ayant besoin de suivre leurs kilomètres.

---

## Architecture

### Niveaux

1. **Présentation (UI)** : écrans Flutter (`main.dart`, `deplacement_form_page.dart`, `settings_page.dart`).
2. **Logique métier** : classes `Deplacement`, `TrajetType`, `UserConfig` (dans `main.dart`).
3. **Persistance** : `AppStorage` (fichier `storage.dart`) qui sauvegarde/charge depuis `shared_preferences`.

### Flux de données

```
Écran (Widget State) 
    ↓
Ajouter/modifier trajet
    ↓
Classe modèle (Deplacement, UserConfig)
    ↓
AppStorage.save*() 
    ↓
shared_preferences (stockage local)
```

Au redémarrage :
```
AppStorage.load*() 
    ↓
shared_preferences 
    ↓
Classe modèle (Deplacement, UserConfig)
    ↓
Widget rebuild avec les anciennes données
```

---

## Guide de démarrage

### 1. Cloner le projet

```bash
git clone https://github.com/<username>/carnet-trajets.git
cd carnet-trajets
```

### 2. Installer les dépendances

```bash
flutter pub get
```

Cela installe :
- `intl` : formatage de dates.
- `share_plus` : partage de fichiers.
- `path_provider` : accès aux chemins système.
- `shared_preferences` : sauvegarde locale.
- `icons_launcher` : génération d'icônes.

### 3. Préparer l'icône de l'app

Crée le fichier :
```
assets/icons/icon_trajets.png
```

Dimensions : **512×512 pixels**, format PNG.
Contenu : image simple (par exemple pickup + plongeur, ou logo personnalisé).

### 4. Générer les icônes Android

```bash
flutter pub get
dart run icons_launcher:create
```

Cette commande crée les variantes d'icône pour Android dans `android/app/src/main/res/mipmap-*`.

### 5. Lancer sur Android

Brancher un téléphone (avec "Débogage USB" ON) ou démarrer un émulateur.

```bash
flutter run
```

L'application s'installe et se lance en mode debug.

### 6. Build APK pour distribution

```bash
flutter clean
flutter pub get
flutter build apk --release
```

L'APK signé sera dans : `build/app/outputs/flutter-apk/app-release.apk`

---

## Structure des fichiers

```
carnet-trajets/
├── lib/
│   ├── main.dart                      # Application principale, écran d'accueil, liste
│   ├── deplacement_form_page.dart    # Formulaire d'ajout/édition de trajet
│   ├── settings_page.dart            # Configuration utilisateur
│   └── storage.dart                  # Couche de persistance (shared_preferences)
├── assets/
│   └── icons/
│       └── icon_trajets.png          # Icône 512×512 de l'application
├── android/
│   ├── app/
│   │   └── src/main/
│   │       ├── AndroidManifest.xml   # Configuration Android (nom d'app, etc.)
│   │       └── res/mipmap-*/         # Icônes générées par icons_launcher
│   └── build.gradle
├── pubspec.yaml                       # Dépendances et config Flutter
├── pubspec.lock                       # Version figée des dépendances
├── README.md                          # Guide rapide
├── DOCUMENTATION.md                   # Ce fichier
└── .gitignore                         # Fichiers ignorés par Git
```

---

## Modules principaux

### 1. **main.dart**

Contient :

- **Classe `Deplacement`** : 
  ```dart
  class Deplacement {
    DateTime date;
    String raison;
    double km;
  }
  ```

- **Classe `TrajetType`** : trajets mémorisés pour suggestions.
  ```dart
  class TrajetType {
    String raison;
    double kmDefaut;
  }
  ```

- **Classe `UserConfig`** : configuration utilisateur.
  ```dart
  class UserConfig {
    String nom;
    String typeVehicule;  // 'thermique' ou 'electrique'
    double puissance;
  }
  ```

- **Widget `MyApp`** : racine de l'application, chargement initial des données.

- **Widget `HomePage`** : 
  - Affiche la liste des trajets.
  - Bouton "Ajouter" pour saisir un nouveau trajet.
  - Bouton "Paramètres" pour configurer.
  - Bouton "Partager" pour exporter en CSV.

**Méthodes clés** :
- `_addDeplacement()` : ouvre le formulaire et sauvegarde.
- `_openSettings()` : ouvre l'écran de configuration.
- `_exportAndShareCsv()` : crée un CSV et le partage.

### 2. **deplacement_form_page.dart**

- Formulaire pour ajouter/modifier un trajet.
- Champs : date (DatePicker), raison (TextField ou dropdown), kilométrage (TextField numérique).
- Suggestions : si une raison a déjà été utilisée, le km par défaut s'affiche.
- Valide avant de retourner au `HomePage`.

**Exemple d'utilisation** :
```dart
final result = await Navigator.of(context).push<Deplacement>(
  MaterialPageRoute(
    builder: (_) => DeplacementFormPage(trajetsConnus: _trajets),
  ),
);
if (result != null) {
  setState(() => _items.add(result));
  AppStorage.saveDeplacements(_items);
}
```

### 3. **settings_page.dart**

- Formulaire pour configurer le profil.
- Champs : nom (TextField), type de véhicule (DropdownButton), puissance (TextField numérique).
- Sauvegarde automatique quand on quitte la page.

### 4. **storage.dart**

Gère la persistance avec `shared_preferences` :

**Méthodes** :
- `saveConfig(UserConfig)` : encode en JSON et stocke.
- `loadConfig()` : récupère et décode.
- `saveDeplacements(List<Deplacement>)` : liste en JSON.
- `loadDeplacements()` : récupère la liste.

**Stockage interne** :
```dart
static const _keyConfig = 'user_config';
static const _keyDeplacements = 'deplacements';
```

**Format JSON** :
```json
{
  "nom": "Jean Dupont",
  "typeVehicule": "thermique",
  "puissance": 80.0
}
```

---

## Persistence des données

### Comment ça fonctionne

1. **Au démarrage** (`main()`) :
   - `AppStorage.loadConfig()` → récupère la config sauvegardée.
   - `AppStorage.loadDeplacements()` → récupère la liste des trajets.
   - Ces données sont passées à `MyApp` et `HomePage`.

2. **Lors d'une modification** :
   - L'utilisateur ajoute un trajet ou change la config.
   - Le code appelle `AppStorage.save*()`.
   - Les données sont écrites dans `shared_preferences`.

3. **Après redémarrage / mise à jour APK** :
   - Android garde les données de `shared_preferences`.
   - L'app recharge tout automatiquement.
   - Aucune perte de données.

### Limitation

- Les données ne sont effacées que si :
  - L'utilisateur désinstalle l'app.
  - L'utilisateur efface le cache/données de l'app (Paramètres → Applications).
  - Vous appelez explicitement `prefs.clear()` (ce qu'on ne fait pas).

---

## Personnalisation

### Changer la couleur de thème

Dans `main.dart`, dans `MyApp.build()` :

```dart
final colorScheme = ColorScheme.fromSeed(seedColor: Colors.teal);
```

Remplace `Colors.teal` par une autre couleur (ex: `Colors.blue`, `Colors.green`, `Colors.purple`).

### Changer le nom de l'app

1. **Dans Flutter** : modifie `pubspec.yaml` et `name` en haut du fichier (interne).
2. **Sur Android** : ouvre `android/app/src/main/AndroidManifest.xml` et change :
   ```xml
   android:label="Carnet de trajets"
   ```

### Ajouter des champs à la config

Par exemple, ajouter "Marque du véhicule" :

1. Modifie `UserConfig` dans `main.dart` :
   ```dart
   class UserConfig {
     String nom;
     String marque;  // nouveau
     String typeVehicule;
     double puissance;
   }
   ```

2. Mets à jour `AppStorage` dans `storage.dart` :
   ```dart
   static Future<void> saveConfig(UserConfig config) async {
     final map = {
       'nom': config.nom,
       'marque': config.marque,  // nouveau
       'typeVehicule': config.typeVehicule,
       'puissance': config.puissance,
     };
     // ...
   }
   ```

3. Ajoute un champ dans `settings_page.dart`.

### Exporter en JSON au lieu de CSV

Modifie `_exportAndShareCsv()` dans `main.dart` :

```dart
Future<void> _exportAndShareJson() async {
  final list = _items.map((d) => {
    'date': _dateFormat.format(d.date),
    'raison': d.raison,
    'km': d.km,
  }).toList();
  
  final jsonString = jsonEncode(list);
  // ... créer et partager le fichier JSON
}
```

---

## Troubleshooting

### Erreur : "Undefined name 'AppStorage'"

**Cause** : Le fichier `storage.dart` n'existe pas ou n'est pas importé dans `main.dart`.

**Solution** :
1. Crée `lib/storage.dart` avec le contenu complet.
2. Ajoute l'import en haut de `main.dart` :
   ```dart
   import 'storage.dart';
   ```
3. Relance `flutter clean && flutter pub get && flutter run`.

### Les données ne se sauvegardent pas

**Cause** : Vous appelez `AppStorage.save*()` mais les données ne persistent pas après redémarrage.

**Solutions** :
1. Vérifie que vous appelez bien `AppStorage.save*()` après chaque modification.
2. Teste si `shared_preferences` a les bonnes permissions Android. Dans `android/app/src/main/AndroidManifest.xml`, ajoute si absent :
   ```xml
   <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
   ```
3. Nettoie le projet :
   ```bash
   flutter clean
   flutter pub get
   ```

### L'icône n'apparaît pas

**Cause** : Le fichier `icon_trajets.png` est manquant ou mal référencé.

**Solutions** :
1. Crée `assets/icons/icon_trajets.png` (512×512 PNG).
2. Vérifie `pubspec.yaml` :
   ```yaml
   flutter:
     uses-material-design: true
     assets:
       - assets/icons/icon_trajets.png
   ```
3. Relance `icons_launcher` :
   ```bash
   dart run icons_launcher:create
   flutter clean
   flutter pub get
   flutter run
   ```

### Erreur "Gradle task assembleDebug failed"

**Cause** : Version incompatible de Gradle ou SDK Android.

**Solution** :
```bash
flutter doctor
```

Cela te dit ce qui manque. Installe les dépendances Android manquantes via Android Studio.

### Données perdues après mise à jour APK

Si vous avez suivi ce guide, cela ne devrait **pas** arriver. Si c'est le cas :

1. Vérifie que les données sont bien chargées au démarrage dans `main()`.
2. Ajoute des logs pour debug :
   ```dart
   void main() async {
     WidgetsFlutterBinding.ensureInitialized();
     final config = await AppStorage.loadConfig();
     print('Config chargée: $config');  // debug
     // ...
   }
   ```

---

## Ressources supplémentaires

- **Documentation Flutter officielle** : https://docs.flutter.dev
- **Shared Preferences** : https://pub.dev/packages/shared_preferences
- **Share Plus** : https://pub.dev/packages/share_plus
- **Icons Launcher** : https://pub.dev/packages/icons_launcher

---

## Questions / Support

Ouvre une **Issue** sur GitHub pour poser des questions ou signaler un bug.

Bonne chance avec **Carnet de trajets** ! 🚚📱

# KM CSF - Carnet de Trajets

Application Flutter pour la gestion des trajets kilom&eacute;triques.

## Compilation de l'APK

### Pr&eacute;requis

- Flutter SDK (>=3.0.0)
- Android SDK
- Java 17

### Compiler l'APK release

```bash
flutter build apk --release
```

L'APK g&eacute;n&eacute;r&eacute; se trouve dans :

```
build/app/outputs/apk/release/KM_CSF-<version>.apk
```

Le nom du fichier inclut automatiquement la version d&eacute;finie dans `pubspec.yaml` (ex: `KM_CSF-1.1.0.apk`).

### Changer la version

Modifier la ligne `version` dans `pubspec.yaml` :

```yaml
version: 1.1.0+0
#         ^^^^^  = versionName (affich&eacute;e)
#               ^ = versionCode (num&eacute;ro interne, &agrave; incr&eacute;menter &agrave; chaque publication)
```

### Installer sur un t&eacute;l&eacute;phone

Par USB avec un appareil connect&eacute; :

```bash
flutter install
```

Ou transf&eacute;rer le fichier `KM_CSF-<version>.apk` sur le t&eacute;l&eacute;phone et l'ouvrir.

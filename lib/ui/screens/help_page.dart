import 'package:flutter/material.dart';
import 'package:km_csf/main.dart'; // Import pour accéder à la variable appVersion

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Aide & Utilisation")),
      // Utilisation du Stack pour mettre le logo en fond
      body: Stack(
        children: [
          // 1. LE LOGO EN FILIGRANE (FOND)
          Center(
            child: Opacity(
              opacity:
                  0.17, // Encore plus léger que sur l'accueil pour faciliter la lecture
              child: Image.asset(
                'assets/images/logo_csf.png',
                width: MediaQuery.of(context).size.width * 0.8,
                fit: BoxFit.contain,
                // Si l'image n'est pas trouvée, on n'affiche rien au lieu d'une erreur
                errorBuilder: (context, error, stackTrace) => const SizedBox(),
              ),
            ),
          ),

          // 2. LE CONTENU (PAR-DESSUS)
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSection(
                Icons.settings,
                "1. Configuration",
                "Avant de commencer, allez dans les Paramètres pour saisir votre Nom, Adresse et Puissance Fiscale. Ces informations sont indispensables pour les calculs et la validité du PDF.",
              ),
              _buildSection(
                Icons.calculate,
                "2. Barèmes et Calculs",
                "Les calculs de cette application appliquent les barèmes officiels de l'administration fiscale pour les années 2025/2026. Ils sont automatiquement mis à jour selon votre puissance fiscale.",
              ),
              _buildSection(
                Icons.add_circle_outline,
                "3. Ajouter & Modifier",
                "• POUR AJOUTER : Appuyez sur le bouton '+' en bas de l'écran.\n"
                    "• POUR MODIFIER : Faites un APPUI LONG sur un trajet dans la liste principale.\n"
                    "• SAISIE RAPIDE : Utilisez le menu déroulant pour remplir automatiquement vos trajets fréquents (Motif + KM).",
              ),
              _buildSection(
                Icons.picture_as_pdf,
                "4. Exportation",
                "Le bouton PDF génère votre attestation sur l'honneur avec les montants écrits en toutes lettres. Le bouton Excel fournit le détail ligne par ligne pour vos archives.",
              ),
              _buildSection(
                Icons.backup,
                "5. Sauvegardes",
                "Dans les paramètres, utilisez la 'Gestion des sauvegardes' pour créer un fichier de secours. Envoyez-le vous par e-mail pour pouvoir restaurer vos données en cas de changement de téléphone.",
              ),
              const SizedBox(height: 30),
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    const Text(
                      "Application développée pour les bénévoles de l'association CSF.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontStyle: FontStyle.italic, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Application créée par Daniel Louvel",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.teal),
                    ),
                    const SizedBox(height: 4),
                    // Affichage de la version
                    Text(
                      "Version $appVersion",
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(IconData icon, String title, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.teal, size: 28),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 5),
                Text(text,
                    style: const TextStyle(color: Colors.black87, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

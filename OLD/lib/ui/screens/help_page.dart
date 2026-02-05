import 'package:flutter/material.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Aide & Utilisation")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            Icons.settings,
            "1. Configuration",
            "Avant de commencer, allez dans les Paramètres pour saisir votre Nom, Adresse et Puissance Fiscale. Ces informations sont indispensables pour les calculs et la validité du PDF.",
          ),
          _buildSection(
            Icons.add_circle_outline,
            "2. Ajouter & Modifier",
            "• POUR AJOUTER : Appuyez sur le bouton '+' en bas de l'écran.\n"
                "• POUR MODIFIER : Faites un APPUI LONG sur un trajet dans la liste principale.\n"
                "• SAISIE RAPIDE : Utilisez le menu déroulant pour remplir automatiquement vos trajets fréquents (Motif + KM).",
          ),
          _buildSection(
            Icons.picture_as_pdf,
            "3. Exportation",
            "Le bouton PDF génère votre attestation sur l'honneur avec les montants écrits en toutes lettres. Le bouton Excel fournit le détail ligne par ligne pour vos archives.",
          ),
          _buildSection(
            Icons.backup,
            "4. Sauvegardes",
            "Dans les paramètres, utilisez la 'Gestion des sauvegardes' pour créer un fichier de secours. Envoyez-le vous par e-mail pour pouvoir restaurer vos données en cas de changement de téléphone.",
          ),
          const SizedBox(height: 30),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Column(
              children: [
                Text(
                  "Application développée pour les bénévoles de l'association CSF.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontStyle: FontStyle.italic, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  "Application créée par Daniel Louvel",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.teal),
                ),
                SizedBox(height: 4),
                Text(
                  "Version 1.1.5",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
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

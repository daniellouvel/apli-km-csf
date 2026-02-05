import 'package:flutter/material.dart';
import '../../models.dart';

class UserHeader extends StatelessWidget {
  final UserConfig config;
  final String version;

  const UserHeader({super.key, required this.config, required this.version});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Utilisateur : ${config.nom.isEmpty ? "Non configuré" : config.nom}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                version,
                style: TextStyle(
                  fontSize: 10,
                  color: scheme.primary.withOpacity(0.5),
                ),
              ),
            ],
          ),
          if (config.adresse.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Adresse : ${config.adresse}',
                style: const TextStyle(fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}

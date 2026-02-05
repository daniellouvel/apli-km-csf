import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models.dart';

class DeplacementCard extends StatelessWidget {
  final Deplacement item;
  final VoidCallback onDelete;
  final VoidCallback onLongPress;

  const DeplacementCard(
      {super.key,
      required this.item,
      required this.onDelete,
      required this.onLongPress});

  @override
  Widget build(BuildContext context) {
    final bool isTrajet = item.type == 'trajet';
    final Color themeColor = isTrajet ? Colors.teal : Colors.amber.shade800;
    final Color bgColor = isTrajet ? Colors.teal.shade50 : Colors.amber.shade50;

    return GestureDetector(
      onLongPress: onLongPress,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        elevation: 1,
        color: bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: themeColor,
            child: Icon(isTrajet ? Icons.directions_car : Icons.euro_symbol,
                color: Colors.white, size: 20),
          ),
          title: Text(item.raison,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(DateFormat('dd/MM/yyyy').format(item.date)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isTrajet
                    ? '${item.km} km'
                    : '${item.montant.toStringAsFixed(2)} €',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: themeColor,
                    fontSize: 16),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

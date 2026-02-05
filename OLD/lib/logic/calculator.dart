import '../models.dart';
import 'grille_fiscale.dart';

class KMCalculator {
  static double calculIndemnite({
    required UserConfig config,
    required double kmAnnuels,
  }) {
    // 1. Cas du barème personnalisé (si l'utilisateur a saisi ses propres taux)
    if (config.baremeCustom != null) {
      final b = config.baremeCustom!;
      if (kmAnnuels <= 5000) return kmAnnuels * b.coef1;
      if (kmAnnuels <= 20000) return (kmAnnuels * b.coef2) + b.fixe2;
      return kmAnnuels * b.coef3;
    }

    // 2. Cas du barème fiscal officiel
    // On détermine la catégorie (ex: 3cv, 4cv...)
    String catPuissance = config.puissance <= 3
        ? '3cv'
        : config.puissance >= 7
            ? '7cv+'
            : '${config.puissance.toInt()}cv';

    // On choisit la table (thermique ou électrique)
    final table = config.typeVehicule == 'electrique'
        ? GrilleFiscale.electrique
        : GrilleFiscale.thermique;

    final tranches = table[catPuissance]!;
    Map<String, double> coef;

    // Sélection de la tranche kilométrique
    if (kmAnnuels <= 5000) {
      coef = tranches['0-5000']!;
    } else if (kmAnnuels <= 20000) {
      coef = tranches['5001-20000']!;
    } else {
      coef = tranches['20000+']!;
    }

    // Formule : (Distance * Coefficient A) + Majoration B
    return (coef['a']! * kmAnnuels) + coef['b']!;
  }
}

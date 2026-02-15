class BaremeCustom {
  double coef1;
  double coef2;
  double fixe2;
  double coef3;
  BaremeCustom(
      {required this.coef1,
      required this.coef2,
      required this.fixe2,
      required this.coef3});
  Map<String, dynamic> toJson() =>
      {'coef1': coef1, 'coef2': coef2, 'fixe2': fixe2, 'coef3': coef3};
  factory BaremeCustom.fromJson(Map<String, dynamic> map) => BaremeCustom(
        coef1: (map['coef1'] as num).toDouble(),
        coef2: (map['coef2'] as num).toDouble(),
        fixe2: (map['fixe2'] as num).toDouble(),
        coef3: (map['coef3'] as num).toDouble(),
      );
}

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
  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'raison': raison,
        'km': km,
        'montant': montant,
        'type': type
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
  String adresse;
  String typeVehicule;
  double puissance;
  BaremeCustom? baremeCustom;
  UserConfig(
      {required this.nom,
      this.adresse = '',
      required this.typeVehicule,
      required this.puissance,
      this.baremeCustom});
  Map<String, dynamic> toJson() => {
        'nom': nom,
        'adresse': adresse,
        'typeVehicule': typeVehicule,
        'puissance': puissance,
        'baremeCustom': baremeCustom?.toJson()
      };
  factory UserConfig.fromJson(Map<String, dynamic> map) => UserConfig(
        nom: map['nom'] as String? ?? '',
        adresse: map['adresse'] as String? ?? '',
        typeVehicule: map['typeVehicule'] as String? ?? 'thermique',
        puissance: (map['puissance'] as num?)?.toDouble() ?? 4.0,
        baremeCustom: map['baremeCustom'] != null
            ? BaremeCustom.fromJson(map['baremeCustom'])
            : null,
      );
}

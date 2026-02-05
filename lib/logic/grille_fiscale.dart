class GrilleFiscale {
  static const Map<String, Map<String, Map<String, double>>> thermique = {
    '3cv': {
      '0-5000': {'a': 0.529, 'b': 0},
      '5001-20000': {'a': 0.316, 'b': 1065},
      '20000+': {'a': 0.370, 'b': 0},
    },
    '4cv': {
      '0-5000': {'a': 0.606, 'b': 0},
      '5001-20000': {'a': 0.340, 'b': 1330},
      '20000+': {'a': 0.407, 'b': 0},
    },
    '5cv': {
      '0-5000': {'a': 0.636, 'b': 0},
      '5001-20000': {'a': 0.357, 'b': 1395},
      '20000+': {'a': 0.427, 'b': 0},
    },
    '6cv': {
      '0-5000': {'a': 0.665, 'b': 0},
      '5001-20000': {'a': 0.374, 'b': 1457},
      '20000+': {'a': 0.447, 'b': 0},
    },
    '7cv+': {
      '0-5000': {'a': 0.697, 'b': 0},
      '5001-20000': {'a': 0.394, 'b': 1515},
      '20000+': {'a': 0.470, 'b': 0},
    },
  };

  // Les véhicules électriques bénéficient d'une majoration de 20%
  static Map<String, Map<String, Map<String, double>>> electrique =
      thermique.map((key, value) {
    return MapEntry(key, value.map((k, v) {
      return MapEntry(k, v.map((ki, vi) => MapEntry(ki, vi * 1.20)));
    }));
  });
}

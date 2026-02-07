enum ModelGender {
  woman,
  man,
  neutral,
}

extension ModelGenderLabel on ModelGender {
  String get label {
    switch (this) {
      case ModelGender.woman:
        return 'Woman';
      case ModelGender.man:
        return 'Man';
      case ModelGender.neutral:
        return 'Neutral';
    }
  }
}

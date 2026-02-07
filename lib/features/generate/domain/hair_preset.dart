enum HairPreset {
  short,
  medium,
  long,
  updo,
  ponytail,
}

extension HairPresetLabel on HairPreset {
  String get label {
    switch (this) {
      case HairPreset.short:
        return 'Short';
      case HairPreset.medium:
        return 'Medium';
      case HairPreset.long:
        return 'Long';
      case HairPreset.updo:
        return 'Updo';
      case HairPreset.ponytail:
        return 'Ponytail';
    }
  }
}

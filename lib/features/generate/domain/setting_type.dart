enum SettingType {
  studio,
  studioNatural,
  lifestyle,
}

extension SettingTypeLabel on SettingType {
  String get label {
    switch (this) {
      case SettingType.studio:
        return 'Studio';
      case SettingType.studioNatural:
        return 'Studio natural';
      case SettingType.lifestyle:
        return 'Lifestyle';
    }
  }
}

enum LifestylePreset {
  beach,
  street,
  cafe,
  evening,
}

extension LifestylePresetLabel on LifestylePreset {
  String get label {
    switch (this) {
      case LifestylePreset.beach:
        return 'Beach';
      case LifestylePreset.street:
        return 'Street';
      case LifestylePreset.cafe:
        return 'Cafe';
      case LifestylePreset.evening:
        return 'Evening';
    }
  }
}

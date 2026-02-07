enum CompositionType {
  closeUp,
  midShot,
  lifestyleWide,
}

extension CompositionTypeLabel on CompositionType {
  String get label {
    switch (this) {
      case CompositionType.closeUp:
        return 'Close-up';
      case CompositionType.midShot:
        return 'Mid shot';
      case CompositionType.lifestyleWide:
        return 'Lifestyle wide';
    }
  }
}

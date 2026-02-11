enum SkinTone {
  light,
  tanned,
  brown,
  dark,
}

extension SkinToneLabel on SkinTone {
  String get label {
    switch (this) {
      case SkinTone.light:
        return 'Light';
      case SkinTone.tanned:
        return 'Tanned';
      case SkinTone.brown:
        return 'Brown';
      case SkinTone.dark:
        return 'Dark';
    }
  }
}

enum SkinTone {
  light,
  medium,
  deep,
}

extension SkinToneLabel on SkinTone {
  String get label {
    switch (this) {
      case SkinTone.light:
        return 'Light';
      case SkinTone.medium:
        return 'Medium';
      case SkinTone.deep:
        return 'Deep';
    }
  }
}

enum JewelryType {
  necklace,
  earrings,
  ring,
  bracelet,
  anklet,
  other,
}

extension JewelryTypeLabel on JewelryType {
  String get label {
    switch (this) {
      case JewelryType.necklace:
        return 'Necklace';
      case JewelryType.earrings:
        return 'Earrings';
      case JewelryType.ring:
        return 'Ring';
      case JewelryType.bracelet:
        return 'Bracelet';
      case JewelryType.anklet:
        return 'Anklet';
      case JewelryType.other:
        return 'Other';
    }
  }
}

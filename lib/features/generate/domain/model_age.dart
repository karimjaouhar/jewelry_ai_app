enum ModelAge {
  kids,
  teen,
  twenties,
  forties,
  senior,
}

extension ModelAgeLabel on ModelAge {
  String get label {
    switch (this) {
      case ModelAge.kids:
        return 'Kids';
      case ModelAge.teen:
        return 'Teen';
      case ModelAge.twenties:
        return '20s';
      case ModelAge.forties:
        return '40s';
      case ModelAge.senior:
        return 'Senior';
    }
  }
}

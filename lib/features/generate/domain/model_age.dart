enum ModelAge {
  teen,
  twenties,
  adult,
  senior,
}

extension ModelAgeLabel on ModelAge {
  String get label {
    switch (this) {
      case ModelAge.teen:
        return 'Teen';
      case ModelAge.twenties:
        return '20s';
      case ModelAge.adult:
        return 'Adult';
      case ModelAge.senior:
        return 'Senior';
    }
  }
}

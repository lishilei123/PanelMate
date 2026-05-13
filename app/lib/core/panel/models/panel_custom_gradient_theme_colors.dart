class PanelCustomGradientThemeColors {
  const PanelCustomGradientThemeColors({
    required this.primaryValue,
    required this.secondaryValue,
    required this.tertiaryValue,
  });

  final int primaryValue;
  final int secondaryValue;
  final int tertiaryValue;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is PanelCustomGradientThemeColors &&
        primaryValue == other.primaryValue &&
        secondaryValue == other.secondaryValue &&
        tertiaryValue == other.tertiaryValue;
  }

  @override
  int get hashCode => Object.hash(primaryValue, secondaryValue, tertiaryValue);
}

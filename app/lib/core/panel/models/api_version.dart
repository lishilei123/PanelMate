enum PanelApiVersion {
  v2,
}

PanelApiVersion panelApiVersionFromValue(String? value) {
  return PanelApiVersion.v2;
}

extension PanelApiVersionX on PanelApiVersion {
  String get value => 'v2';

  String get label => 'V2 API';

  String get basePath => '/api/v2';
}

// lib/domain/poco.dart
class Poco {
  Poco([Map<String, dynamic>? d])
      : data = d ??
            {'use': 'Irrigação', 'testType': 'Rebaixamento', 'pumpTime': 24.0};

  final Map<String, dynamic> data;

  Poco copy() => Poco(Map<String, dynamic>.from(data));
  double? n(String k) => (data[k] as num?)?.toDouble();
  String s(String k) => (data[k] as String?) ?? '';

  String get name => s('name');
  String get location => s('location');
  String get use => s('use');
  String get testType => s('testType');
  double? get depth => n('depth');
  double? get pumpHeight => n('pumpHeight');
  double? get ne => n('ne');
  double? get nd => n('nd');
  double? get testFlow => n('testFlow');
  double? get reqFlow => n('reqFlow');
  double? get hoursDay => n('hoursDay');
  double? get lat => n('lat');
  double? get lon => n('lon');

  /// Campos mínimos para calcular.
  bool get hasData =>
      [depth, ne, nd, testFlow, reqFlow, hoursDay].every((v) => v != null);
}

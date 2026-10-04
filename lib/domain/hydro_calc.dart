// lib/domain/hydro_calc.dart

/// Resultado imutável da análise de um poço.
class Analysis {
  const Analysis({
    required this.s,
    required this.ve,
    required this.volDaily,
    required this.ratio,
    required this.ca,
    required this.ndPrime,
    required this.pa,
    required this.vm,
    required this.sufficient,
    required this.sustainable,
  });
  final double s, ve, volDaily, ratio, ca, ndPrime, pa, vm;
  final bool sufficient, sustainable;
  double get volMonth => volDaily * 30;
  double get volYear => volDaily * 365;
}

/// s = ND − NE · VE = VT/s · ND' = VR/VE + NE · CA = P − NE
/// PA = (P − ND')/CA·100 · VM = [P − 0,3·CA − NE]·VE
/// Retorna null se os dados forem inválidos (ex.: ND <= NE).
Analysis? analyze({
  required double depth,
  required double ne,
  required double nd,
  required double testFlow,
  required double reqFlow,
  required double hoursDay,
}) {
  final s = nd - ne;
  if (s <= 0 || reqFlow <= 0 || depth <= ne) return null;
  final ve = testFlow / s;
  final ndPrime = reqFlow / ve + ne;
  final ca = depth - ne;
  final vm = (depth - ca * 0.3 - ne) * ve;
  return Analysis(
    s: s,
    ve: ve,
    volDaily: reqFlow * hoursDay,
    ratio: testFlow / reqFlow,
    ca: ca,
    ndPrime: ndPrime,
    pa: (depth - ndPrime) / ca * 100,
    vm: vm,
    sufficient: testFlow >= reqFlow,
    sustainable: reqFlow <= vm && ndPrime < depth,
  );
}

/// Nível dinâmico para uma vazão simulada (proporcional ao teste).
double simulatedDynamicLevel({
  required double ne,
  required double s,
  required double testFlow,
  required double simFlow,
}) =>
    ne + simFlow * s / testFlow;

/// Cooper-Jacob: T = 0,183·Q/Δs (m²/h).
double? transmissivity(double q, double ds) => ds > 0 ? 0.183 * q / ds : null;

enum FlowUnit {
  ls('L/s', 3.6),
  m3h('m³/h', 1),
  m3dia('m³/dia', 1 / 24),
  m3mes('m³/mês', 1 / 720);

  const FlowUnit(this.label, this.toM3h);
  final String label;
  final double toM3h;
}

Map<FlowUnit, double> convertFlow(double value, FlowUnit from) {
  final base = value * from.toM3h;
  return {for (final u in FlowUnit.values) u: base / u.toM3h};
}

import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../core/format.dart';
import '../../domain/hydro_calc.dart';
import '../../domain/poco.dart';
import 'common.dart';
import 'well_profile.dart';

/// Card do perfil litológico + card de simulação de rebaixamento.
/// Dono do AnimationController e do valor do slider.
class ProfileAndSimulation extends StatefulWidget {
  const ProfileAndSimulation(
      {super.key, required this.poco, required this.analysis});
  final Poco poco;
  final Analysis analysis;
  @override
  State<ProfileAndSimulation> createState() => _ProfileAndSimulationState();
}

class _ProfileAndSimulationState extends State<ProfileAndSimulation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim =
      AnimationController(vsync: this, duration: const Duration(seconds: 4))
        ..repeat();
  double? _sim;

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  static const _legend = <(String, Color)>[
    ('Solo / aterro', Color(0xFFC9A97A)),
    ('Argila', Color(0xFFC47F4E)),
    ('Saprolito', Color(0xFFA9967F)),
    ('Rocha fraturada', Color(0xFF8B8F99)),
    ('Zona saturada', Color(0xFF3F83D6)),
    ('Bomba', AppColors.navy),
  ];

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final poco = widget.poco, a = widget.analysis;
    final vt = poco.testFlow!;
    final sim = _sim ?? vt;
    final maxV = max(vt * 2, 10.0);
    final simS = sim * a.s / vt;
    final simND = poco.ne! + simS;

    return Column(children: [
      CardBox(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Perfil litológico do poço',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          Text('Camadas do subsolo com NE e ND simulado.',
              style: TextStyle(color: p.muted, fontSize: 11.5)),
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: _anim,
            builder: (_, __) => SizedBox(
              height: 380,
              width: double.infinity,
              child: CustomPaint(
                  painter: WellPainter(
                      poco: poco,
                      simFlow: sim,
                      t: _anim.value,
                      label: p.text,
                      muted: p.muted)),
            ),
          ),
          Wrap(spacing: 14, runSpacing: 6, children: [
            for (final (name, color) in _legend)
              Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                        color: color, borderRadius: BorderRadius.circular(3))),
                const SizedBox(width: 6),
                Text(name, style: TextStyle(fontSize: 11, color: p.muted)),
              ]),
          ]),
          const SizedBox(height: 6),
          Text(
              'Camadas ilustrativas, geradas a partir da profundidade informada.',
              style: TextStyle(fontSize: 10.5, color: p.muted)),
        ]),
      ),
      const SizedBox(height: 16),
      CardBox(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Simulação de rebaixamento',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          Text('Altere a vazão e veja o nível dinâmico no perfil.',
              style: TextStyle(color: p.muted, fontSize: 12)),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Vazão simulada'),
            Text('${fmt(sim, 1)} m³/h',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: AppColors.cyan)),
          ]),
          Slider(
              value: sim.clamp(0.0, maxV).toDouble(),
              max: maxV,
              onChanged: (v) => setState(() => _sim = v)),
          StatGrid([
            StatCard('REBAIXAMENTO SIMULADO', '${fmt(simS)} m'),
            StatCard('NÍVEL DINÂMICO SIMULADO', '${fmt(simND)} m'),
            StatCard(
                'VOLUME CAPTADO/DIA', '${fmt(sim * poco.hoursDay!, 1)} m³'),
            StatCard(
                'VOLUME MENSAL', '${fmt(sim * poco.hoursDay! * 30, 0)} m³'),
          ]),
        ]),
      ),
    ]);
  }
}

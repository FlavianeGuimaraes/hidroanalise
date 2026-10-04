import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../core/format.dart';
import '../../domain/hydro_calc.dart';
import '../widgets/common.dart';

typedef CalcRow = (String label, String value);

class CalcSpec {
  const CalcSpec(
      this.title, this.subtitle, this.icon, this.inputs, this.compute);
  final String title, subtitle;
  final IconData icon;
  final List<String> inputs;
  final List<CalcRow> Function(List<double> v) compute;
}

final calcSpecs = <CalcSpec>[
  CalcSpec(
      'Rebaixamento',
      's = ND − NE',
      Icons.trending_down,
      ['Nível estático — NE (m)', 'Nível dinâmico — ND (m)'],
      (v) => [('Rebaixamento (s)', '${fmt(v[1] - v[0])} m')]),
  CalcSpec('Vazão específica', 'VE = VT / s', Icons.water_drop, [
    'Vazão de teste — VT (m³/h)',
    'Nível estático — NE (m)',
    'Nível dinâmico — ND (m)'
  ], (v) {
    final s = v[2] - v[1];
    return [
      ('Rebaixamento (s)', '${fmt(s)} m'),
      ('Vazão específica (VE)', s > 0 ? '${fmt(v[0] / s, 3)} m³/h/m' : '—')
    ];
  }),
  CalcSpec('Volumes de água', 'Diário, mensal e anual', Icons.opacity,
      ['Vazão (m³/h)', 'Horas de bombeamento/dia'], (v) {
    final d = v[0] * v[1];
    return [
      ('Volume diário', '${fmt(d, 1)} m³'),
      ('Volume mensal', '${fmt(d * 30, 0)} m³'),
      ('Volume anual', '${fmt(d * 365, 0)} m³')
    ];
  }),
  CalcSpec('Sustentabilidade', "CA, ND', PA, VM", Icons.balance, [
    'Profundidade — P (m)',
    'NE (m)',
    'ND (m)',
    'VT (m³/h)',
    'VR (m³/h)'
  ], (v) {
    final a = analyze(
        depth: v[0],
        ne: v[1],
        nd: v[2],
        testFlow: v[3],
        reqFlow: v[4],
        hoursDay: 0);
    if (a == null)
      return [('Resultado', 'Dados inválidos (ND deve ser maior que NE)')];
    return [
      ("Coluna d'água (CA)", '${fmt(a.ca, 1)} m'),
      ("ND'", '${fmt(a.ndPrime)} m'),
      ("Permanência d'água (PA)", '${fmt(a.pa, 1)} %'),
      ('Vazão máx. sustentável (VM)', '${fmt(a.vm, 1)} m³/h'),
      ('Situação', a.sustainable ? 'SUSTENTÁVEL' : 'NÃO SUSTENTÁVEL'),
    ];
  }),
  CalcSpec('Transmissividade', 'Cooper-Jacob: T = 0,183·Q/Δs', Icons.waves,
      ['Vazão — Q (m³/h)', 'Δs por ciclo log (m)'], (v) {
    final t = transmissivity(v[0], v[1]);
    return [('Transmissividade (T)', t == null ? '—' : '${fmt(t)} m²/h')];
  }),
];

class CalculatorHub extends StatelessWidget {
  const CalculatorHub({super.key});

  @override
  Widget build(BuildContext context) {
    Widget tile(IconData icon, String t, String s, Widget page) => Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                  gradient: AppColors.gradient,
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            title: Text(t, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(s, style: const TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => page)),
          ),
        );
    return Scaffold(
      appBar: AppBar(title: const Text('Calculadora')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        for (final s in calcSpecs)
          tile(s.icon, s.title, s.subtitle, CalculatorPage(spec: s)),
        tile(Icons.swap_horiz, 'Conversor de vazão',
            'L/s, m³/h, m³/dia, m³/mês', const ConverterPage()),
      ]),
    );
  }
}

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key, required this.spec});
  final CalcSpec spec;
  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  late final List<TextEditingController> _c = [
    for (final _ in widget.spec.inputs) TextEditingController()
  ];
  List<CalcRow>? _rows;
  String? _error;

  @override
  void dispose() {
    for (final c in _c) {
      c.dispose();
    }
    super.dispose();
  }

  void _calculate() {
    final v = [
      for (final c in _c) double.tryParse(c.text.trim().replaceAll(',', '.'))
    ];
    if (v.any((x) => x == null)) {
      setState(() {
        _rows = null;
        _error = 'Preencha todos os campos.';
      });
      return;
    }
    setState(() {
      _error = null;
      _rows = widget.spec.compute(v.cast<double>());
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(widget.spec.title)),
        bottomNavigationBar: SafeArea(
          child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: PrimaryButton('Calcular', _calculate)),
        ),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          for (var i = 0; i < _c.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: IconField(
                  controller: _c[i],
                  label: widget.spec.inputs[i],
                  number: true,
                  onChanged: (_) => setState(() => _rows = null)),
            ),
          if (_error != null)
            Text(_error!, style: const TextStyle(color: AppColors.danger)),
          if (_rows != null)
            StatGrid([
              for (final (label, value) in _rows!)
                StatCard(label.toUpperCase(), value)
            ]),
        ]),
      );
}

class ConverterPage extends StatefulWidget {
  const ConverterPage({super.key});
  @override
  State<ConverterPage> createState() => _ConverterPageState();
}

class _ConverterPageState extends State<ConverterPage> {
  final _value = TextEditingController();
  FlowUnit _unit = FlowUnit.m3h;
  Map<FlowUnit, double>? _result;

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Conversor de vazão')),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: PrimaryButton('Calcular', () {
              final v =
                  double.tryParse(_value.text.trim().replaceAll(',', '.'));
              setState(
                  () => _result = v == null ? null : convertFlow(v, _unit));
            }),
          ),
        ),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          IconField(
              controller: _value,
              label: 'Valor',
              number: true,
              onChanged: (_) => setState(() => _result = null)),
          const SizedBox(height: 12),
          DropdownButtonFormField<FlowUnit>(
            value: _unit,
            decoration: const InputDecoration(labelText: 'Unidade'),
            items: [
              for (final u in FlowUnit.values)
                DropdownMenuItem(value: u, child: Text(u.label))
            ],
            onChanged: (u) => setState(() {
              _unit = u ?? _unit;
              _result = null;
            }),
          ),
          const SizedBox(height: 18),
          if (_result != null)
            StatGrid([
              for (final e in _result!.entries)
                StatCard(
                    e.key.label.toUpperCase(),
                    fmt(e.value,
                        e.key == FlowUnit.ls || e.key == FlowUnit.m3h ? 3 : 1)),
            ]),
        ]),
      );
}

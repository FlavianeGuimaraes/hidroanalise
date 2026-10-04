import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../core/format.dart';
import '../../domain/hydro_calc.dart';
import '../../domain/poco.dart';
import '../../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/profile_and_simulation.dart';

class FormScreen extends StatefulWidget {
  const FormScreen({super.key, this.original});
  final Poco? original; // null = novo poço
  @override
  State<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  static const _numKeys = [
    'depth',
    'drillDiam',
    'casingDiam',
    'pumpHeight',
    'crivo',
    'ne',
    'nd',
    'testFlow',
    'pumpTime',
    'reqFlow',
    'hoursDay',
    'population',
    'lat',
    'lon',
    'motorHP',
    'bombaEstagios'
  ];
  static const _txtKeys = [
    'name',
    'location',
    'motorMarca',
    'motorModelo',
    'motorTensao',
    'motorTipo',
    'bombaModelo'
  ];
  static const _testTypes = ['Rebaixamento', 'Recuperação', 'Jorrante'];
  static const _uses = [
    'Irrigação',
    'Abastecimento humano',
    'Industrial',
    'Dessedentação animal',
    'Outro'
  ];

  late Poco _draft;
  final _c = <String, TextEditingController>{};

  String _trim(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  @override
  void initState() {
    super.initState();
    _draft = widget.original?.copy() ??
        Poco({
          'use': 'Irrigação',
          'testType': 'Rebaixamento',
          'pumpTime': 24.0,
          'name': 'p${context.read<AppState>().projects.length + 1}',
        });
    for (final k in _numKeys) {
      final v = _draft.n(k);
      _c[k] = TextEditingController(text: v == null ? '' : _trim(v));
    }
    for (final k in _txtKeys) {
      _c[k] = TextEditingController(text: _draft.s(k));
    }
  }

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// Copia o que está nos campos para o rascunho.
  void _sync() {
    for (final k in _numKeys) {
      _draft.data[k] = double.tryParse(_c[k]!.text.trim().replaceAll(',', '.'));
    }
    for (final k in _txtKeys) {
      _draft.data[k] = _c[k]!.text;
    }
  }

  void _save() {
    _sync();
    context
        .read<AppState>()
        .saveProject(_draft, originalName: widget.original?.name);
    Navigator.pop(context);
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir poço?'),
        content: Text(
            '"${widget.original!.name}" será removido. Essa ação não pode ser desfeita.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Excluir')),
        ],
      ),
    );
    if (ok == true && mounted) {
      context.read<AppState>().deleteProject(widget.original!);
      Navigator.pop(context);
    }
  }

  // ---- helpers de layout ----
  Widget _f(String key, String label, {bool number = true, IconData? icon}) =>
      IconField(
          controller: _c[key]!,
          label: label,
          number: number,
          icon: icon,
          onChanged: (_) => setState(() {}));

  Widget _row(Widget a, Widget b) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: a),
        const SizedBox(width: 12),
        Expanded(child: b)
      ]));

  Widget _one(Widget w) =>
      Padding(padding: const EdgeInsets.only(bottom: 12), child: w);

  Widget _drop(String label, String value, List<String> items,
          ValueChanged<String> onChanged) =>
      DropdownButtonFormField<String>(
        value: items.contains(value) ? value : items.first,
        isExpanded: true,
        decoration: InputDecoration(labelText: label),
        items: [
          for (final i in items)
            DropdownMenuItem(
                value: i, child: Text(i, overflow: TextOverflow.ellipsis))
        ],
        onChanged: (v) => setState(() => onChanged(v ?? items.first)),
      );

  @override
  Widget build(BuildContext context) {
    _sync();
    final muted = Palette.of(context).muted;
    final a = _draft.hasData
        ? analyze(
            depth: _draft.depth!,
            ne: _draft.ne!,
            nd: _draft.nd!,
            testFlow: _draft.testFlow!,
            reqFlow: _draft.reqFlow!,
            hoursDay: _draft.hoursDay!)
        : null;

    return Scaffold(
      appBar: AppBar(
          title: Text(
              widget.original == null ? 'Novo cálculo' : 'Editar cálculo')),
      bottomNavigationBar: SafeArea(
        child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: PrimaryButton('Salvar', _save)),
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        _one(_f('name', 'Nome do poço', number: false)),
        _one(_f('location', 'Localização',
            number: false, icon: Icons.place_outlined)),
        _row(_f('depth', 'Profundidade (m)'),
            _f('pumpHeight', 'Altura da bomba (m)')),
        _row(_f('drillDiam', 'Diâm. perfuração (pol)'),
            _f('casingDiam', 'Diâm. revestimento (pol)')),
        _row(_f('ne', 'Nível estático — NE (m)'),
            _f('nd', 'Nível dinâmico — ND (m)')),
        _one(_drop('Tipo de teste de bombeamento', _draft.testType, _testTypes,
            (v) => _draft.data['testType'] = v)),
        _row(_f('testFlow', 'Vazão do teste (m³/h)'),
            _f('pumpTime', 'Tempo de bombeamento (h)')),
        _row(_f('reqFlow', 'Vazão solicitada (m³/h)'),
            _f('hoursDay', 'Horas de bombeamento/dia')),
        _row(
            _f('population', 'População / unidades'),
            _drop('Finalidade do uso', _draft.use, _uses,
                (v) => _draft.data['use'] = v)),
        const SectionLabel('Coordenadas (opcional)'),
        _row(_f('lat', 'Latitude (graus decimais)'),
            _f('lon', 'Longitude (graus decimais)')),
        const SectionLabel('Equipamento e crivo'),
        _one(_f('crivo', 'Crivo — profundidade da tela (m)')),
        _row(_f('motorMarca', 'Motor — marca', number: false),
            _f('motorHP', 'Motor — HP')),
        _row(_f('motorModelo', 'Motor — modelo', number: false),
            _f('motorTensao', 'Motor — tensão', number: false)),
        _one(_f('motorTipo', 'Motor — tipo (TRI, MONO)', number: false)),
        _row(_f('bombaModelo', 'Bomba — modelo', number: false),
            _f('bombaEstagios', 'Bomba — estágios')),
        if (widget.original != null)
          OutlinedButton.icon(
            onPressed: _delete,
            icon: const Icon(Icons.delete_outline, color: AppColors.danger),
            label: const Text('Excluir este poço',
                style: TextStyle(color: AppColors.danger)),
          ),
        if (a == null)
          Padding(
            padding: const EdgeInsets.only(top: 18),
            child: Text(
                'Preencha profundidade, NE, ND (maior que NE), vazão do teste, vazão solicitada e horas/dia para ver os resultados.',
                style: TextStyle(color: muted, fontSize: 12.5)),
          )
        else ...[
          const SizedBox(height: 20),
          StatGrid([
            StatCard('REBAIXAMENTO (s)', '${fmt(a.s)} m', sub: 'ND − NE'),
            StatCard('VAZÃO ESPECÍFICA', fmt(a.ve, 3), sub: 'm³/h/m'),
            StatCard('VOLUME DIÁRIO', '${fmt(a.volDaily, 1)} m³/dia',
                sub: 'Q × horas'),
            StatCard('VOLUME MENSAL', '${fmt(a.volMonth, 0)} m³',
                sub: '× 30 dias'),
            StatCard('VOLUME ANUAL', '${fmt(a.volYear, 0)} m³',
                sub: '× 365 dias'),
            StatCard('TESTADA × SOLICITADA', '${fmt(a.ratio)}×',
                sub:
                    '${fmt(_draft.testFlow, 1)} vs ${fmt(_draft.reqFlow, 1)} m³/h'),
          ]),
          const SizedBox(height: 10),
          StatusBadge(
              ok: a.sufficient,
              yes: 'Vazão testada suficiente',
              no: 'Vazão testada insuficiente'),
          const SectionLabel('Sustentabilidade do poço'),
          StatGrid([
            StatCard("COLUNA D'ÁGUA (CA)", '${fmt(a.ca, 1)} m', sub: 'P − NE'),
            StatCard('ND COM VAZÃO REQUERIDA', '${fmt(a.ndPrime)} m',
                sub: '(VR/VE) + NE'),
            StatCard("PERMANÊNCIA D'ÁGUA (PA)", '${fmt(a.pa, 1)} %',
                sub: "(P − ND') / CA"),
            StatCard('VAZÃO MÁX. SUSTENTÁVEL (VM)', '${fmt(a.vm, 1)} m³/h',
                sub: 'margem de 30%'),
          ]),
          const SizedBox(height: 10),
          StatusBadge(
              ok: a.sustainable, yes: 'SUSTENTÁVEL', no: 'NÃO SUSTENTÁVEL'),
          const ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text('Ver memória de cálculo',
                style: TextStyle(fontSize: 12.5)),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                    "VE = VT / (ND − NE)\nND' = (VR / VE) + NE\nCA = P − NE\nPA = (P − ND') / CA × 100\nVM = [P − (CA × 0,3) − NE] × VE",
                    style: TextStyle(fontSize: 11, height: 1.7)),
              ),
              SizedBox(height: 12),
            ],
          ),
          const SizedBox(height: 10),
          // a chave reinicia o slider quando a vazão do teste muda
          ProfileAndSimulation(
              key: ValueKey(_draft.testFlow), poco: _draft, analysis: a),
          const SizedBox(height: 16),
        ],
      ]),
    );
  }
}

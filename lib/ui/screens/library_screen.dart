import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../widgets/common.dart';

class LibItem {
  const LibItem(this.title, this.summary,
      {this.steps = const [], this.formula, this.tip});
  final String title, summary;
  final List<String> steps;
  final String? formula, tip;
}

const library = <String, List<LibItem>>{
  'Conceitos básicos': [
    LibItem('Nível estático (NE)',
        'Profundidade da água com o poço em repouso, sem bombear há tempo suficiente.',
        steps: [
          'Desligue a bomba e aguarde a recuperação total (12 a 24 h).',
          'Desça a sonda de nível até o contato com a água.',
          'Anote a profundidade a partir da boca do revestimento.',
          'Repita em outro horário para confirmar a estabilização.',
        ],
        tip: 'Meça sempre a partir do mesmo ponto de referência.'),
    LibItem('Nível dinâmico (ND)',
        'Profundidade da água durante o bombeamento, depois que o rebaixamento estabiliza.',
        steps: [
          'Ligue a bomba numa vazão constante e conhecida.',
          'Meça o nível em intervalos crescentes (1, 5, 10, 20, 30, 60 min…).',
          'Continue até o nível parar de cair por 1–2 horas.',
          'Registre o ND junto com a vazão do teste (VT).',
        ]),
    LibItem('Rebaixamento (s)', 'Quanto o nível desce ao bombear.',
        formula: 's = ND − NE', tip: 'NE 13,4 m e ND 18,81 m → s = 5,41 m.'),
    LibItem('Vazão específica (VE)',
        'Vazão obtida por metro de rebaixamento: mede a produtividade do poço.',
        formula: 'VE = VT / (ND − NE)',
        tip: 'VT 2,49 m³/h e s 5,41 m → VE ≈ 0,46 m³/h/m.'),
  ],
  'Volumes de água': [
    LibItem('Volume diário, mensal e anual',
        'Projeta o consumo a partir da vazão requerida e das horas de bombeamento.',
        steps: [
          'Defina a vazão requerida (VR) em m³/h.',
          'Defina as horas de operação por dia.',
          'Diário = VR × horas; mensal = diário × 30; anual = diário × 365.',
        ],
        formula: 'Diário = VR × horas/dia',
        tip: '2 m³/h por 18 h → 36 m³/dia → 1.080 m³/mês → 13.140 m³/ano.'),
  ],
  'Tipos de teste de bombeamento': [
    LibItem('Teste de rebaixamento',
        'Bombeamento numa vazão fixa para medir quanto o nível cai até estabilizar.',
        steps: [
          'Escolha uma vazão de bombeamento fixa.',
          'Meça o nível em intervalos crescentes de tempo.',
          'Continue até estabilizar (ND), tipicamente 4 a 24 h.',
        ],
        tip: 'É o teste mais pedido para outorga de uso da água.'),
    LibItem('Teste de recuperação',
        'Depois de desligar a bomba, mede como o nível volta ao NE.',
        steps: [
          'Desligue a bomba ao final do teste de rebaixamento (t = 0).',
          'Meça o nível em intervalos regulares (1, 2, 5, 10, 20, 30, 60 min…).',
          'Continue até o nível se aproximar do NE original.',
        ],
        tip:
            'Se não recuperar perto do NE, pode haver superexplotação ou interferência.'),
    LibItem('Poço jorrante',
        'Poço em que a água sobe acima do terreno por pressão própria (artesiano).',
        steps: [
          'Meça a vazão de jorro natural na boca do poço.',
          'Meça a pressão com manômetro, se possível.',
          'Registre a vazão em intervalos para ver se cai com o tempo.',
        ],
        tip:
            'Mesmo jorrando, controle a vazão para não esgotar a pressão do aquífero.'),
  ],
  'Sustentabilidade do poço': [
    LibItem('Como calcular, passo a passo',
        'Avalia se a vazão requerida (VR) pode ser captada sem esgotar a coluna de água.',
        steps: [
          'VE = VT / (ND − NE).',
          "ND' = (VR / VE) + NE.",
          'CA = P − NE.',
          "PA = (P − ND') / CA × 100.",
          'VM = [P − (CA × 0,3) − NE] × VE, com 30% de margem de segurança.',
          'Se VR ≤ VM, o poço é SUSTENTÁVEL para essa vazão.',
        ],
        tip:
            'A margem de 30% evita expor a bomba; ajuste conforme a norma local.'),
  ],
};

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Biblioteca')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        for (final e in library.entries) ...[
          SectionLabel(e.key),
          for (final it in e.value)
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ExpansionTile(
                shape: const Border(),
                title: Text(it.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                        color: AppColors.cyan)),
                childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(it.summary,
                      style: TextStyle(
                          color: p.muted, fontSize: 12.5, height: 1.5)),
                  const SizedBox(height: 8),
                  for (var i = 0; i < it.steps.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text('${i + 1}. ${it.steps[i]}',
                          style: const TextStyle(fontSize: 12.5, height: 1.5)),
                    ),
                  if (it.formula != null)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(top: 4, bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: AppColors.cyan.withOpacity(.08),
                          borderRadius: BorderRadius.circular(8)),
                      child: Text(it.formula!,
                          style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              color: AppColors.cyan)),
                    ),
                  if (it.tip != null)
                    Text('💡 ${it.tip}',
                        style: const TextStyle(fontSize: 12, height: 1.5)),
                ],
              ),
            ),
        ],
      ]),
    );
  }
}

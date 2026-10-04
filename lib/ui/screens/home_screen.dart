import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../state/app_state.dart';
import '../widgets/common.dart';
import 'calculator_screen.dart';
import 'form_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onGo});
  final ValueChanged<int> onGo;

  void _newCalc(BuildContext c) =>
      Navigator.push(c, MaterialPageRoute(builder: (_) => const FormScreen()));

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final muted = Palette.of(context).muted;
    final name = state.firstName;
    return Scaffold(
      appBar: AppBar(
        title: const Row(children: [
          AppLogo(size: 36),
          SizedBox(width: 12),
          Text('HidroAnálise',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ]),
        actions: [
          IconButton(
              tooltip: 'Sair',
              icon: const Icon(Icons.logout),
              onPressed: state.logout)
        ],
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Text('Olá${name.isEmpty ? '' : ', $name'}! 👋',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('Calcule, simule e avalie a sustentabilidade dos seus poços.',
            style: TextStyle(color: muted, fontSize: 13)),
        const SizedBox(height: 16),
        LayoutBuilder(builder: (context, c) {
          final w = (c.maxWidth - 12) / 2;
          Widget card(
                  IconData i, Color col, String t, String s, VoidCallback f) =>
              SizedBox(
                  width: w,
                  child: _HomeCard(
                      icon: i, color: col, title: t, sub: s, onTap: f));
          return Wrap(spacing: 12, runSpacing: 12, children: [
            card(Icons.calculate, AppColors.blue, 'Novo cálculo',
                'Inicie uma análise', () => _newCalc(context)),
            card(Icons.folder, const Color(0xFF334155), 'Meus projetos',
                '${state.projects.length} poço(s) salvo(s)', () => onGo(1)),
            card(Icons.menu_book, const Color(0xFF059669), 'Biblioteca',
                'Aprenda hidrogeologia', () => onGo(2)),
            card(Icons.place, AppColors.blue, 'Mapa de poços',
                'Coordenadas salvas', () => onGo(3)),
            card(
                Icons.functions,
                const Color(0xFF7C3AED),
                'Calculadora',
                'Fórmulas rápidas',
                () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const CalculatorHub()))),
          ]);
        }),
        const SizedBox(height: 14),
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _newCalc(context),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
                color: AppColors.navy, borderRadius: BorderRadius.circular(14)),
            child: const Row(children: [
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Simular um poço',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15)),
                      SizedBox(height: 4),
                      Text(
                          'Rebaixamento, vazão e sustentabilidade em poucos passos.',
                          style: TextStyle(
                              color: Color(0xFF9FC2E6), fontSize: 12)),
                    ]),
              ),
              Icon(Icons.arrow_circle_right, color: AppColors.cyan, size: 34),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _HomeCard extends StatelessWidget {
  const _HomeCard(
      {required this.icon,
      required this.color,
      required this.title,
      required this.sub,
      required this.onTap});
  final IconData icon;
  final Color color;
  final String title, sub;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: CardBox(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(9)),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(height: 10),
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14.5)),
            Text(sub,
                style: TextStyle(
                    color: Palette.of(context).muted, fontSize: 11.5)),
          ]),
        ),
      );
}

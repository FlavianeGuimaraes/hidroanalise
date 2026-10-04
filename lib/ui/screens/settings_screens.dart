import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../state/app_state.dart';
import '../widgets/common.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    void open(Widget page) =>
        Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    Widget item(IconData icon, Color color, String t, String s, Widget page) =>
        Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            title: Text(t,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text(s, style: const TextStyle(fontSize: 11.5)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => open(page),
          ),
        );
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const SectionLabel('Minha conta'),
        item(Icons.person, AppColors.blue, 'Perfil', 'Editar nome e e-mail',
            const ProfilePage()),
        item(Icons.lock, const Color(0xFF334155), 'Segurança',
            'Alterar senha e biometria', const SecurityPage()),
        const SectionLabel('Preferências'),
        item(Icons.notifications, const Color(0xFFF59E0B), 'Notificações',
            'Gerenciar alertas do app', const NotificationsPage()),
        item(Icons.dark_mode, const Color(0xFF7C3AED), 'Tema',
            'Claro, escuro ou sistema', const ThemePage()),
        const SectionLabel('Suporte'),
        item(Icons.help, const Color(0xFF059669), 'Ajuda e Suporte',
            'FAQ e contato', const HelpPage()),
        item(Icons.info, AppColors.blue, 'Sobre o App', 'Versão e informações',
            const AboutPage()),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: context.read<AppState>().logout,
            child: const Text('Sair da Conta',
                style: TextStyle(
                    color: AppColors.danger, fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
    );
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final Map<String, TextEditingController> _c;

  @override
  void initState() {
    super.initState();
    final u = context.read<AppState>().user;
    _c = {
      for (final k in ['name', 'email', 'phone', 'cpf'])
        k: TextEditingController(text: u[k] ?? '')
    };
  }

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  Widget _gap(Widget w) =>
      Padding(padding: const EdgeInsets.only(bottom: 12), child: w);

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Meu Perfil')),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          const SizedBox(height: 10),
          const Center(
              child: CircleAvatar(
                  radius: 46,
                  backgroundColor: Color(0xFF3A4658),
                  child:
                      Icon(Icons.person, size: 50, color: Color(0xFFAAB3C2)))),
          const SizedBox(height: 10),
          Center(
              child: Text(
                  _c['name']!.text.isEmpty ? 'Usuário' : _c['name']!.text,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600))),
          const SizedBox(height: 22),
          CardBox(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Dados Pessoais',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _gap(IconField(
                  controller: _c['name']!,
                  label: 'Nome completo',
                  icon: Icons.person_outline)),
              _gap(IconField(
                  controller: _c['email']!,
                  label: 'E-mail',
                  icon: Icons.mail_outline,
                  keyboard: TextInputType.emailAddress)),
              _gap(IconField(
                  controller: _c['phone']!,
                  label: 'Telefone',
                  icon: Icons.phone_outlined,
                  keyboard: TextInputType.phone)),
              IconField(
                  controller: _c['cpf']!,
                  label: 'CPF',
                  icon: Icons.badge_outlined,
                  number: true),
            ]),
          ),
          TextButton.icon(
            icon: const Icon(Icons.save),
            label: const Text('Salvar alterações'),
            onPressed: () {
              context.read<AppState>().updateUser(
                  {for (final e in _c.entries) e.key: e.value.text.trim()});
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Perfil atualizado!')));
              setState(() {});
            },
          ),
        ]),
      );
}

class ThemePage extends StatelessWidget {
  const ThemePage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    const options = {
      ThemeMode.dark: ('Escuro', 'Fundo escuro com acentos ciano (padrão)'),
      ThemeMode.light: ('Claro', 'Ideal para ambientes bem iluminados'),
      ThemeMode.system: ('Sistema', 'Segue o tema do dispositivo'),
    };
    return Scaffold(
      appBar: AppBar(title: const Text('Tema')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        for (final e in options.entries)
          Card(
            child: RadioListTile<ThemeMode>(
              value: e.key,
              groupValue: state.themeMode,
              onChanged: (m) => state.setTheme(m ?? ThemeMode.dark),
              title: Text(e.value.$1,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(e.value.$2, style: const TextStyle(fontSize: 12)),
            ),
          ),
      ]),
    );
  }
}

class SecurityPage extends StatefulWidget {
  const SecurityPage({super.key});
  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> {
  final _cur = TextEditingController(),
      _new = TextEditingController(),
      _new2 = TextEditingController();
  bool _bio = false;

  @override
  void dispose() {
    _cur.dispose();
    _new.dispose();
    _new2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Segurança')),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          IconField(
              controller: _cur,
              label: 'Senha atual',
              icon: Icons.lock_outline,
              password: true),
          const SizedBox(height: 12),
          IconField(
              controller: _new,
              label: 'Nova senha',
              icon: Icons.lock_outline,
              password: true),
          const SizedBox(height: 12),
          IconField(
              controller: _new2,
              label: 'Confirmar nova senha',
              icon: Icons.lock_outline,
              password: true),
          const SizedBox(height: 16),
          PrimaryButton('Alterar senha', () {
            final ok = _new.text.isNotEmpty && _new.text == _new2.text;
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(ok
                    ? 'Senha alterada (simulado neste protótipo).'
                    : 'As senhas não coincidem ou estão em branco.')));
          }),
          const SizedBox(height: 20),
          Card(
            child: SwitchListTile(
              value: _bio,
              onChanged: (v) => setState(() => _bio = v),
              title: const Text('Biometria',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Usar digital / Face ID para entrar',
                  style: TextStyle(fontSize: 12)),
            ),
          ),
        ]),
      );
}

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});
  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _on = <String, bool>{'email': true, 'push': true, 'tips': false};
  static const _items = {
    'email': ('Notificações por e-mail', 'Resumos e alertas por e-mail'),
    'push': ('Alertas no app', 'Avisos sobre testes e sustentabilidade'),
    'tips': ('Dicas de hidrogeologia', 'Sugestões da Biblioteca'),
  };

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Notificações')),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          for (final e in _items.entries)
            Card(
              child: SwitchListTile(
                value: _on[e.key]!,
                onChanged: (v) => setState(() => _on[e.key] = v),
                title: Text(e.value.$1,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle:
                    Text(e.value.$2, style: const TextStyle(fontSize: 12)),
              ),
            ),
        ]),
      );
}

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    const faq = [
      (
        'Como salvo um poço?',
        'Preencha os campos em "Novo cálculo" e toque em Salvar. Ele aparece em "Meus projetos".'
      ),
      (
        'Onde ficam meus dados?',
        'No armazenamento local do aparelho. Desinstalar o app apaga os poços salvos.'
      ),
      (
        'O que significa SUSTENTÁVEL?',
        'Que a vazão requerida é menor ou igual à vazão máxima sustentável (VM), com 30% de margem da coluna d\'água.'
      ),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Ajuda e Suporte')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        for (final (q, a) in faq)
          Card(
            child: ExpansionTile(
              shape: const Border(),
              title: Text(q,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13.5)),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a, style: const TextStyle(fontSize: 12.5, height: 1.5))
              ],
            ),
          ),
        const SectionLabel('Contato'),
        const Text('suporte@hidroanalise.com'),
      ]),
    );
  }
}

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Sobre o App')),
        body: ListView(padding: const EdgeInsets.all(24), children: [
          const Center(child: AppLogo(size: 76)),
          const SizedBox(height: 14),
          const Text('HidroAnálise',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text('Versão 1.0.0',
              textAlign: TextAlign.center,
              style: TextStyle(color: Palette.of(context).muted)),
          const SizedBox(height: 16),
          const Text(
              'Apoio à análise, simulação e sustentabilidade de poços tubulares: rebaixamento, vazão específica, volumes e perfil litológico animado.',
              style: TextStyle(height: 1.5)),
        ]),
      );
}

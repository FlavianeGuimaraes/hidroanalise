import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../state/app_state.dart';
import '../widgets/common.dart';

String? _required(String? v) =>
    (v == null || v.trim().isEmpty) ? 'Campo obrigatório' : null;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController(), _pass = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  void _submit() {
    if (_form.currentState!.validate())
      context.read<AppState>().login(_email.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final muted = Palette.of(context).muted;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(children: [
                const AppLogo(size: 76),
                const SizedBox(height: 12),
                const Text('HidroAnálise',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.cyan)),
                Text('Apoio à análise de poços tubulares',
                    style: TextStyle(fontSize: 12, color: muted)),
                const SizedBox(height: 26),
                CardBox(
                  child: Form(
                    key: _form,
                    child: Column(children: [
                      IconField(
                          controller: _email,
                          label: 'E-mail',
                          icon: Icons.mail_outline,
                          keyboard: TextInputType.emailAddress,
                          validator: _required),
                      const SizedBox(height: 12),
                      IconField(
                          controller: _pass,
                          label: 'Senha',
                          icon: Icons.lock_outline,
                          password: true,
                          validator: _required),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const RecoverScreen())),
                          child: const Text('Esqueci a senha'),
                        ),
                      ),
                      PrimaryButton('Acessar sistema', _submit),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const SignupScreen())),
                          child: const Text('Criar nova conta'),
                        ),
                      ),
                    ]),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(),
      _email = TextEditingController(),
      _cpf = TextEditingController(),
      _phone = TextEditingController(),
      _cep = TextEditingController(),
      _pass = TextEditingController(),
      _pass2 = TextEditingController();
  bool _terms = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _email, _cpf, _phone, _cep, _pass, _pass2]) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    if (_pass.text != _pass2.text) {
      setState(() => _error = 'As senhas não coincidem.');
      return;
    }
    if (!_terms) {
      setState(() => _error = 'Aceite os termos para continuar.');
      return;
    }
    context.read<AppState>().signup({
      'name': _name.text.trim(),
      'email': _email.text.trim(),
      'cpf': _cpf.text.trim(),
      'phone': _phone.text.trim(),
    });
    Navigator.of(context).pop(); // o app troca para a Home automaticamente
  }

  Widget _gap(Widget w) =>
      Padding(padding: const EdgeInsets.only(bottom: 12), child: w);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar Conta')),
      body: Form(
        key: _form,
        child: ListView(padding: const EdgeInsets.all(20), children: [
          if (_error != null)
            _gap(Text(_error!,
                style: const TextStyle(color: AppColors.danger),
                textAlign: TextAlign.center)),
          _gap(IconField(
              controller: _name,
              label: 'Nome completo',
              icon: Icons.person_outline,
              validator: _required)),
          _gap(IconField(
              controller: _email,
              label: 'E-mail',
              icon: Icons.mail_outline,
              keyboard: TextInputType.emailAddress,
              validator: _required)),
          _gap(IconField(
              controller: _cpf,
              label: 'CPF',
              icon: Icons.badge_outlined,
              number: true,
              validator: _required)),
          _gap(IconField(
              controller: _phone,
              label: 'Telefone',
              icon: Icons.phone_outlined,
              keyboard: TextInputType.phone,
              validator: _required)),
          _gap(IconField(
              controller: _cep,
              label: 'CEP',
              icon: Icons.location_on_outlined,
              number: true,
              validator: _required)),
          _gap(IconField(
              controller: _pass,
              label: 'Senha',
              icon: Icons.lock_outline,
              password: true,
              validator: _required)),
          _gap(IconField(
              controller: _pass2,
              label: 'Confirmar senha',
              icon: Icons.lock_outline,
              password: true,
              validator: _required)),
          CheckboxListTile(
            value: _terms,
            onChanged: (v) => setState(() => _terms = v ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            title: const Text(
                'Eu concordo com os Termos de Uso e a Política de Privacidade.',
                style: TextStyle(fontSize: 12)),
          ),
          const SizedBox(height: 8),
          PrimaryButton('Criar conta', _submit),
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Já tem uma conta? Faça login')),
        ]),
      ),
    );
  }
}

class RecoverScreen extends StatefulWidget {
  const RecoverScreen({super.key});
  @override
  State<RecoverScreen> createState() => _RecoverScreenState();
}

class _RecoverScreenState extends State<RecoverScreen> {
  final _email = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final muted = Palette.of(context).muted;
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar Senha')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        const Center(child: AppLogo(size: 60)),
        const SizedBox(height: 14),
        const Text('Recuperar Senha',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(
            'Digite seu e-mail cadastrado e enviaremos um link para redefinir sua senha.',
            textAlign: TextAlign.center,
            style: TextStyle(color: muted, fontSize: 13)),
        const SizedBox(height: 20),
        IconField(
            controller: _email,
            label: 'E-mail cadastrado',
            icon: Icons.mail_outline,
            keyboard: TextInputType.emailAddress),
        const SizedBox(height: 16),
        PrimaryButton('Enviar link de recuperação',
            () => setState(() => _sent = _email.text.trim().isNotEmpty)),
        if (_sent)
          const Padding(
            padding: EdgeInsets.only(top: 14),
            child: Text('✅ Link enviado! Verifique sua caixa de entrada.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.ok)),
          ),
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Voltar para login')),
        const SizedBox(height: 10),
        const CardBox(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('🛡️ Dicas de segurança',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: AppColors.ok)),
            SizedBox(height: 6),
            Text(
                '• O link é válido por 24 horas.\n• Não compartilhe o link.\n• Confira a caixa de spam.\n• Guarde sua senha em local seguro.',
                style: TextStyle(fontSize: 12, height: 1.6)),
          ]),
        ),
      ]),
    );
  }
}

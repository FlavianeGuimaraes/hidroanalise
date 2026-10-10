import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../state/app_state.dart';
import '../widgets/common.dart';

// ---------- funções auxiliares ----------

String? _required(String? v) =>
    (v == null || v.trim().isEmpty) ? 'Campo obrigatório' : null;

String _onlyDigits(String s) => s.replaceAll(RegExp(r'[^0-9]'), '');

String _fmtCpf(String d) =>
    '${d.substring(0, 3)}.${d.substring(3, 6)}.${d.substring(6, 9)}-${d.substring(9)}';

String _fmtCep(String d) => '${d.substring(0, 5)}-${d.substring(5)}';

/// Confere se o CPF é válido (11 dígitos + dígitos verificadores).
/// Para aceitar qualquer número de 11 dígitos em testes, apague tudo
/// o que vem depois do primeiro "if (d.length != 11)".
String? _cpfValidator(String? v) {
  final d = _onlyDigits(v ?? '');
  if (d.length != 11) return 'O CPF deve ter 11 dígitos';
  if (RegExp(r'^(\d)\1{10}$').hasMatch(d)) return 'CPF inválido';
  int digito(int qtd) {
    var soma = 0;
    for (var i = 0; i < qtd; i++) {
      soma += int.parse(d[i]) * (qtd + 1 - i);
    }
    final r = (soma * 10) % 11;
    return r == 10 ? 0 : r;
  }

  if (digito(9) != int.parse(d[9]) || digito(10) != int.parse(d[10]))
    return 'CPF inválido';
  return null;
}

// =====================================================================
// LOGIN
// =====================================================================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController(), _pass = TextEditingController();
  String? _error, _info;

  @override
  void initState() {
    super.initState();
    // Já deixa preenchido o e-mail da conta cadastrada neste aparelho.
    _email.text = context.read<AppState>().user['email'] ?? '';
  }

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    final ok = context.read<AppState>().login(_email.text, _pass.text);
    if (!ok) {
      setState(() {
        _info = null;
        _error = 'E-mail ou senha incorretos.';
      });
    }
    // Se deu certo, o AppState muda "loggedIn" e a Home aparece sozinha.
  }

  // Abre o cadastro. Quando ele volta com "true", mostra a mensagem de sucesso.
  Future<void> _goSignup() async {
    final created = await Navigator.push<bool>(
        context, MaterialPageRoute(builder: (_) => const SignupScreen()));
    if (created == true && mounted) {
      setState(() {
        _email.text = context.read<AppState>().user['email'] ?? '';
        _pass.clear();
        _error = null;
        _info = 'Conta criada com sucesso! Entre com seu e-mail e senha.';
      });
    }
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
                      if (_info != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(_info!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: AppColors.ok, fontSize: 12.5)),
                        ),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(_error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: AppColors.danger, fontSize: 12.5)),
                        ),
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
                            onPressed: _goSignup,
                            child: const Text('Criar nova conta')),
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

// =====================================================================
// CADASTRO (com CEP automático)
// =====================================================================
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
      _logradouro = TextEditingController(),
      _bairro = TextEditingController(),
      _cidade = TextEditingController(),
      _estado = TextEditingController(),
      _pass = TextEditingController(),
      _pass2 = TextEditingController();

  bool _terms = false;
  bool _buscandoCep = false;
  String _ibge = ''; // código do município no IBGE (vem do ViaCEP)
  String? _error, _cepError;

  @override
  void dispose() {
    for (final c in [
      _name,
      _email,
      _cpf,
      _phone,
      _cep,
      _logradouro,
      _bairro,
      _cidade,
      _estado,
      _pass,
      _pass2
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // Busca o endereço assim que o CEP chega a 8 dígitos.
  Future<void> _buscarCep() async {
    final cep = _onlyDigits(_cep.text);
    if (cep.length != 8) return;

    setState(() {
      _buscandoCep = true;
      _cepError = null;
    });

    try {
      final res = await http
          .get(Uri.parse('https://viacep.com.br/ws/$cep/json/'))
          .timeout(const Duration(seconds: 8));
      if (!mounted) return;
      final data = jsonDecode(res.body) as Map<String, dynamic>;

      if (data['erro'] == true || data['erro'] == 'true') {
        setState(() => _cepError = 'CEP não encontrado.');
      } else {
        setState(() {
          _logradouro.text = (data['logradouro'] ?? '').toString();
          _bairro.text = (data['bairro'] ?? '').toString();
          _cidade.text = (data['localidade'] ?? '').toString();
          _estado.text = (data['uf'] ?? '').toString();
          _ibge = (data['ibge'] ?? '').toString();
        });
      }
    } catch (_) {
      if (mounted)
        setState(() =>
            _cepError = 'Não foi possível buscar o CEP. Verifique a conexão.');
    } finally {
      if (mounted) setState(() => _buscandoCep = false);
    }
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    if (_pass.text != _pass2.text) {
      setState(() => _error = 'As senhas não coincidem.');
      return;
    }
    if (!_terms) {
      setState(() => _error = 'Aceite os termos para continuar.');
      return;
    }

    await context.read<AppState>().signup({
      'name': _name.text.trim(),
      'email': _email.text.trim(),
      'cpf': _fmtCpf(_onlyDigits(_cpf.text)),
      'phone': _phone.text.trim(),
      'cep': _fmtCep(_onlyDigits(_cep.text)),
      'logradouro': _logradouro.text.trim(),
      'bairro': _bairro.text.trim(),
      'cidade': _cidade.text.trim(),
      'estado': _estado.text.trim().toUpperCase(),
      'ibge': _ibge,
    }, _pass.text);

    if (!mounted) return;
    Navigator.pop(context, true); // volta para o Login avisando que deu certo
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
              validator: _cpfValidator)),
          _gap(IconField(
              controller: _phone,
              label: 'Telefone',
              icon: Icons.phone_outlined,
              keyboard: TextInputType.phone,
              validator: _required)),

          // ---------- CEP + endereço automático ----------
          _gap(IconField(
            controller: _cep,
            label: 'CEP',
            icon: Icons.location_on_outlined,
            number: true,
            validator: (v) => _onlyDigits(v ?? '').length == 8
                ? null
                : 'O CEP deve ter 8 dígitos',
            onChanged: (v) {
              if (_onlyDigits(v).length == 8) _buscarCep();
            },
          )),
          if (_buscandoCep)
            const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: LinearProgressIndicator()),
          if (_cepError != null)
            _gap(Text(_cepError!,
                style: const TextStyle(color: AppColors.danger, fontSize: 12))),
          _gap(IconField(
              controller: _logradouro,
              label: 'Logradouro',
              icon: Icons.signpost_outlined)),
          _gap(IconField(
              controller: _bairro,
              label: 'Bairro',
              icon: Icons.holiday_village_outlined)),
          _gap(IconField(
              controller: _cidade,
              label: 'Cidade',
              icon: Icons.location_city_outlined)),
          _gap(IconField(
              controller: _estado,
              label: 'Estado (UF)',
              icon: Icons.map_outlined)),

          // ---------- senha ----------
          _gap(IconField(
              controller: _pass,
              label: 'Senha',
              icon: Icons.lock_outline,
              password: true,
              validator: (v) => (v == null || v.length < 6)
                  ? 'Mínimo de 6 caracteres'
                  : null)),
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

// =====================================================================
// RECUPERAR SENHA
// =====================================================================
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

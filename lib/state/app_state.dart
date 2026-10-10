import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import '../data/local_store.dart';
import '../domain/poco.dart';

// Transforma a senha num código irreversível (SHA-256).
String _hash(String password) =>
    sha256.convert(utf8.encode(password)).toString();

class AppState extends ChangeNotifier {
  AppState(this._store)
      : user = _store.loadUser(),
        themeMode = _store.loadTheme(),
        projects = _store.loadProjects();

  final LocalStore _store;
  bool loggedIn = false;
  Map<String, String> user;
  ThemeMode themeMode;
  List<Poco> projects;

  String get firstName {
    final n = (user['name'] ?? '').trim();
    return n.isEmpty ? '' : n.split(' ').first;
  }

  // ---------- autenticação ----------

  /// Cadastro: guarda o perfil e a senha (em hash), mas NÃO faz login.
  Future<void> signup(Map<String, String> profile, String password) async {
    user = profile;
    await _store.saveUser(user);
    await _store.saveCredentials(
      profile['email']!.trim().toLowerCase(),
      _hash(password),
    );
    notifyListeners();
  }

  /// Login: compara e-mail e senha com o que foi guardado.
  bool login(String email, String password) {
    final saved = _store.loadCredentials();
    if (saved == null) return false;
    final ok = saved['email'] == email.trim().toLowerCase() &&
        saved['hash'] == _hash(password);
    if (!ok) return false;
    loggedIn = true;
    notifyListeners();
    return true;
  }

  void logout() {
    loggedIn = false;
    notifyListeners();
  }

  void updateUser(Map<String, String> u) {
    user = u;
    _store.saveUser(user);
    notifyListeners();
  }

  // ---------- tema ----------
  void setTheme(ThemeMode m) {
    themeMode = m;
    _store.saveTheme(m);
    notifyListeners();
  }

  // ---------- poços ----------
  void saveProject(Poco p, {String? originalName}) {
    final i = projects.indexWhere((x) => x.name == (originalName ?? p.name));
    if (i >= 0) {
      projects[i] = p;
    } else {
      projects.add(p);
    }
    _store.saveProjects(projects);
    notifyListeners();
  }

  void deleteProject(Poco p) {
    projects.remove(p);
    _store.saveProjects(projects);
    notifyListeners();
  }
}

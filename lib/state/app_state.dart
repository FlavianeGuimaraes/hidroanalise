// lib/state/app_state.dart
import 'package:flutter/material.dart';
import '../data/local_store.dart';
import '../domain/poco.dart';

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

  String get firstName => (user['name'] ?? '').trim().split(' ').first;

  // --- autenticação (simulada: sem servidor) ---
  void login(String email) {
    user = {...user, 'email': email};
    _store.saveUser(user);
    loggedIn = true;
    notifyListeners();
  }

  void signup(Map<String, String> u) {
    user = u;
    _store.saveUser(user);
    loggedIn = true;
    notifyListeners();
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

  // --- tema ---
  void setTheme(ThemeMode m) {
    themeMode = m;
    _store.saveTheme(m);
    notifyListeners();
  }

  // --- poços ---
  /// [originalName] é o nome antes da edição (evita duplicar ao renomear).
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

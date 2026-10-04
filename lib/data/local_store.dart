// lib/data/local_store.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/poco.dart';

class LocalStore {
  LocalStore(this._p);
  final SharedPreferences _p;

  List<Poco> loadProjects() {
    final raw = _p.getString('projects');
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => Poco(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveProjects(List<Poco> l) =>
      _p.setString('projects', jsonEncode(l.map((e) => e.data).toList()));

  Map<String, String> loadUser() {
    final raw = _p.getString('user');
    if (raw == null) return {};
    return Map<String, String>.from(jsonDecode(raw) as Map);
  }

  Future<void> saveUser(Map<String, String> u) =>
      _p.setString('user', jsonEncode(u));

  ThemeMode loadTheme() =>
      ThemeMode.values.firstWhere((m) => m.name == _p.getString('theme'),
          orElse: () => ThemeMode.dark);

  Future<void> saveTheme(ThemeMode m) => _p.setString('theme', m.name);
}

// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/app_theme.dart';
import 'data/local_store.dart';
import 'state/app_state.dart';
import 'ui/screens/auth_screens.dart';
import 'ui/screens/home_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(ChangeNotifierProvider(
    create: (_) => AppState(LocalStore(prefs)),
    child: const HidroApp(),
  ));
}

class HidroApp extends StatelessWidget {
  const HidroApp({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return MaterialApp(
      title: 'HidroAnálise',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(Brightness.light),
      darkTheme: AppTheme.build(Brightness.dark),
      themeMode: state.themeMode,
      home: state.loggedIn ? const HomeShell() : const LoginScreen(),
    );
  }
}

import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'library_screen.dart';
import 'projects_screen.dart';
import 'settings_screens.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  void _go(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) => Scaffold(
        body: IndexedStack(index: _index, children: [
          HomeScreen(onGo: _go),
          const ProjectsScreen(),
          const LibraryScreen(),
          const MapScreen(),
          const SettingsScreen(),
        ]),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _go,
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Início'),
            NavigationDestination(
                icon: Icon(Icons.folder_outlined),
                selectedIcon: Icon(Icons.folder),
                label: 'Projetos'),
            NavigationDestination(
                icon: Icon(Icons.menu_book_outlined),
                selectedIcon: Icon(Icons.menu_book),
                label: 'Aprender'),
            NavigationDestination(
                icon: Icon(Icons.place_outlined),
                selectedIcon: Icon(Icons.place),
                label: 'Mapa'),
            NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: 'Ajustes'),
          ],
        ),
      );
}

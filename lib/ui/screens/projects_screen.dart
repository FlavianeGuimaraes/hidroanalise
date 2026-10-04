import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../core/format.dart';
import '../../state/app_state.dart';
import 'form_screen.dart';

class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final list = context.watch<AppState>().projects;
    final muted = Palette.of(context).muted;
    return Scaffold(
      appBar: AppBar(title: Text('Meus projetos (${list.length})')),
      body: list.isEmpty
          ? Center(
              child: Text(
                  'Nenhum poço salvo ainda.\nToque em "Novo cálculo" para começar.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: muted)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (context, i) {
                final p = list[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    title: Text(p.name.isEmpty ? 'Poço ${i + 1}' : p.name),
                    subtitle: Text(
                        '${p.location.isEmpty ? 'Sem localização' : p.location} · NE ${fmt(p.ne, 1)} m / ND ${fmt(p.nd, 1)} m'),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => FormScreen(original: p))),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: AppColors.danger),
                      onPressed: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Excluir poço?'),
                            content: Text('"${p.name}" será removido.'),
                            actions: [
                              TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancelar')),
                              TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Excluir')),
                            ],
                          ),
                        );
                        if (ok == true && context.mounted)
                          context.read<AppState>().deleteProject(p);
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}

/// Lista de poços com coordenadas. Para mapa real, use google_maps_flutter.
class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final list = context.watch<AppState>().projects;
    return Scaffold(
      appBar: AppBar(title: Text('Mapa de poços (${list.length})')),
      body: list.isEmpty
          ? const Center(child: Text('Nenhum poço salvo ainda.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (context, i) {
                final p = list[i];
                final has = p.lat != null && p.lon != null;
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: const Icon(Icons.place, color: AppColors.blue),
                    title: Text(p.name),
                    subtitle: Text(has
                        ? '${fmt(p.lat, 5)}, ${fmt(p.lon, 5)}'
                        : 'Sem coordenadas — edite o poço para adicionar.'),
                    trailing: has
                        ? IconButton(
                            icon: const Icon(Icons.copy, size: 18),
                            tooltip: 'Copiar link do Google Maps',
                            onPressed: () {
                              Clipboard.setData(ClipboardData(
                                  text:
                                      'https://www.google.com/maps?q=${p.lat},${p.lon}'));
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Link copiado!')));
                            },
                          )
                        : null,
                  ),
                );
              },
            ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../core/format.dart';
import '../../domain/poco.dart';
import '../../state/app_state.dart';
import 'form_screen.dart';

bool _hasCoords(Poco p) =>
    p.lat != null && p.lon != null && p.lat!.abs() <= 90 && p.lon!.abs() <= 180;

// =====================================================================
// LISTA (aba "Mapa"): tocar num poço abre o mapa nele
// =====================================================================
class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  void _aviso(BuildContext context, String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final list = context.watch<AppState>().projects;
    return Scaffold(
      appBar: AppBar(
        title: Text('Mapa de poços (${list.length})'),
        actions: [
          IconButton(
            tooltip: 'Ver todos no mapa',
            icon: const Icon(Icons.map_outlined),
            onPressed: () {
              if (list.any(_hasCoords)) {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const WellMapPage()));
              } else {
                _aviso(context, 'Nenhum poço com coordenadas.');
              }
            },
          ),
        ],
      ),
      body: list.isEmpty
          ? const Center(child: Text('Nenhum poço salvo ainda.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (context, i) {
                final p = list[i];
                final has = _hasCoords(p);
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: Icon(Icons.place,
                        color: has ? AppColors.blue : Colors.grey),
                    title: Text(p.name.isEmpty ? 'Poço ${i + 1}' : p.name),
                    subtitle: Text(has
                        ? '${fmt(p.lat, 5)}, ${fmt(p.lon, 5)}'
                        : 'Sem coordenadas — edite o poço para adicionar.'),
                    trailing: has ? const Icon(Icons.chevron_right) : null,
                    onTap: () {
                      if (has) {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => WellMapPage(focus: p)));
                      } else {
                        _aviso(context, 'Este poço não tem coordenadas.');
                      }
                    },
                  ),
                );
              },
            ),
    );
  }
}

// =====================================================================
// MAPA: centralizado em um poço (focus) ou mostrando todos
// =====================================================================
class WellMapPage extends StatefulWidget {
  const WellMapPage({super.key, this.focus});
  final Poco? focus;
  @override
  State<WellMapPage> createState() => _WellMapPageState();
}

class _WellMapPageState extends State<WellMapPage> {
  final _ctrl = MapController();
  bool _satellite = false;

  void _fitAll(List<Poco> pts) {
    if (pts.isEmpty) return;
    if (pts.length == 1) {
      _ctrl.move(LatLng(pts.first.lat!, pts.first.lon!), 14);
      return;
    }
    final bounds =
        LatLngBounds.fromPoints([for (final p in pts) LatLng(p.lat!, p.lon!)]);
    _ctrl.fitCamera(
        CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(60)));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pts = context.watch<AppState>().projects.where(_hasCoords).toList();
    final focus = widget.focus;
    final palette = Palette.of(context);
    final start = focus ?? (pts.isNotEmpty ? pts.first : null);

    return Scaffold(
      appBar: AppBar(
        title: Text(focus == null
            ? 'Todos os poços'
            : (focus.name.isEmpty ? 'Poço' : focus.name)),
        actions: [
          if (focus != null)
            IconButton(
              tooltip: 'Centralizar neste poço',
              icon: const Icon(Icons.my_location),
              onPressed: () => _ctrl.move(LatLng(focus.lat!, focus.lon!), 15),
            ),
          IconButton(
            tooltip: 'Ver todos os poços',
            icon: const Icon(Icons.center_focus_strong),
            onPressed: () => _fitAll(pts),
          ),
          IconButton(
            tooltip: 'Mapa / Satélite',
            icon: Icon(_satellite ? Icons.map_outlined : Icons.satellite_alt),
            onPressed: () => setState(() => _satellite = !_satellite),
          ),
        ],
      ),
      body: FlutterMap(
        mapController: _ctrl,
        options: MapOptions(
          initialCenter: start == null
              ? const LatLng(-14.2, -51.9)
              : LatLng(start.lat!, start.lon!),
          initialZoom: start == null ? 4 : (focus != null ? 15 : 12),
          onMapReady: () {
            if (focus == null) _fitAll(pts);
          },
        ),
        children: [
          TileLayer(
            urlTemplate: _satellite
                ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.hidroanalise',
          ),
          MarkerLayer(markers: [
            for (final p in pts)
              Marker(
                point: LatLng(p.lat!, p.lon!),
                width: 90,
                height: 64,
                alignment: Alignment.topCenter,
                child: GestureDetector(
                  // Tocar no marcador abre o poço para editar.
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => FormScreen(original: p))),
                  child: Column(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: palette.card,
                          borderRadius: BorderRadius.circular(6)),
                      child: Text(p.name.isEmpty ? 'Poço' : p.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11)),
                    ),
                    Icon(Icons.location_on,
                        color: p == focus ? AppColors.blue : AppColors.danger,
                        size: 36),
                  ]),
                ),
              ),
          ]),
          RichAttributionWidget(attributions: [
            TextSourceAttribution(_satellite
                ? 'Esri World Imagery'
                : '© OpenStreetMap contributors'),
          ]),
        ],
      ),
    );
  }
}

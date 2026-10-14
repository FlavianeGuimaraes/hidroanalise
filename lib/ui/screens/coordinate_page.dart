import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/coordenadas.dart' as coord;

/// Conversor de coordenadas: digite em decimal ou graus/min/seg.
class CoordinatePage extends StatefulWidget {
  const CoordinatePage({super.key});
  @override
  State<CoordinatePage> createState() => _CoordinatePageState();
}

class _CoordinatePageState extends State<CoordinatePage> {
  final _lat = TextEditingController();
  final _lon = TextEditingController();
  String? _erro;
  List<(String, String)> _res = [];

  @override
  void dispose() {
    _lat.dispose();
    _lon.dispose();
    super.dispose();
  }

  void _calcular() {
    FocusScope.of(context).unfocus();
    final la = coord.parseCoordinate(_lat.text, isLat: true);
    final lo = coord.parseCoordinate(_lon.text, isLat: false);
    if (la == null || lo == null) {
      setState(() {
        _erro = 'Coordenada inválida. Exemplos: -3.548913  ou  3° 32\' 55" S';
        _res = [];
      });
      return;
    }
    if (la < -80 || la > 84) {
      setState(() {
        _erro = 'UTM/MGRS só valem entre 80°S e 84°N.';
        _res = [];
      });
      return;
    }
    final u = coord.toUtm(la, lo);
    setState(() {
      _erro = null;
      _res = [
        (
          'Graus decimais',
          '${la.toStringAsFixed(6)}, ${lo.toStringAsFixed(6)}'
        ),
        (
          'Graus, min e seg',
          '${coord.toDms(la)}\n${coord.toDms(lo, isLat: false)}'
        ),
        (
          'Graus e min decimais',
          '${coord.toDm(la)}\n${coord.toDm(lo, isLat: false)}'
        ),
        (
          'UTM (WGS84)',
          'Zona ${u.zone}${u.band} · ${u.hemisphere}\nE ${u.easting.toStringAsFixed(2)} m\nN ${u.northing.toStringAsFixed(2)} m'
        ),
        ('MGRS', coord.toMgrs(la, lo)),
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Conversor de coordenadas')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
              'Digite em graus decimais ou em graus, minutos e segundos. '
              'Use S/N e O/L (ou sinal negativo).'),
          const SizedBox(height: 16),
          TextField(
            controller: _lat,
            decoration: const InputDecoration(
                labelText: 'Latitude',
                hintText: '-3.548913  ou  3° 32\' 55" S',
                border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _lon,
            decoration: const InputDecoration(
                labelText: 'Longitude',
                hintText: '-44.907288  ou  44° 54\' 26" O',
                border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
              onPressed: _calcular,
              icon: const Icon(Icons.calculate),
              label: const Text('Calcular')),
          if (_erro != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_erro!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          const SizedBox(height: 16),
          for (final (rotulo, valor) in _res)
            Card(
              child: ListTile(
                title: Text(rotulo),
                subtitle: SelectableText(valor,
                    style: const TextStyle(fontSize: 15, height: 1.4)),
                trailing: IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: valor));
                    ScaffoldMessenger.of(context)
                        .showSnackBar(const SnackBar(content: Text('Copiado')));
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

import 'dart:math' as math;

/// Lê uma coordenada em qualquer formato e devolve graus decimais.
/// Aceita: -3.548913 | -3,548913 | 3° 32' 55" S | 3 32 55 S | 3 32.9 S
/// [isLat] só é usado para validar o limite (90 ou 180).
double? parseCoordinate(String input, {bool isLat = true}) {
  var s = input.trim().toUpperCase();
  if (s.isEmpty) return null;
  s = s.replaceAll(',', '.');
  var sign = 1.0;
  if (RegExp(r'(^|[^A-Z])[SWO]($|[^A-Z])').hasMatch(s) ||
      s.endsWith('S') ||
      s.endsWith('W') ||
      s.endsWith('O')) {
    sign = -1.0;
  }
  s = s.replaceAll(RegExp(r'[NSEWLO]'), ' ');
  if (s.contains('-')) sign = -1.0;
  final nums = RegExp(r'\d+(\.\d+)?')
      .allMatches(s)
      .map((m) => double.parse(m.group(0)!))
      .toList();
  if (nums.isEmpty || nums.length > 3) return null;
  final deg = nums[0];
  final min = nums.length > 1 ? nums[1] : 0.0;
  final sec = nums.length > 2 ? nums[2] : 0.0;
  if (min >= 60 || sec >= 60) return null;
  final v = sign * (deg + min / 60 + sec / 3600);
  if (v.abs() > (isLat ? 90 : 180)) return null;
  return v;
}

String _hem(double v, bool isLat) =>
    isLat ? (v < 0 ? 'S' : 'N') : (v < 0 ? 'O' : 'L');

/// 3° 32' 55.89" S
String toDms(double v, {bool isLat = true}) {
  final a = v.abs();
  var d = a.floor();
  var m = ((a - d) * 60).floor();
  var s = ((a - d) * 60 - m) * 60;
  if (s >= 59.9995) {
    s = 0;
    m += 1;
  }
  if (m >= 60) {
    m = 0;
    d += 1;
  }
  return "$d° $m' ${s.toStringAsFixed(3)}\" ${_hem(v, isLat)}";
}

/// 3° 32.9335' S
String toDm(double v, {bool isLat = true}) {
  final a = v.abs();
  final d = a.floor();
  final m = (a - d) * 60;
  return "$d° ${m.toStringAsFixed(5)}' ${_hem(v, isLat)}";
}

class Utm {
  const Utm(this.zone, this.band, this.south, this.easting, this.northing);
  final int zone;
  final String band;
  final bool south;
  final double easting, northing;
  String get hemisphere => south ? 'Sul' : 'Norte';
}

/// WGS84 -> UTM (série de Krüger; confere com a série clássica de Snyder em < 1 mm).
Utm toUtm(double lat, double lon) {
  const a = 6378137.0;
  const f = 1 / 298.257223563;
  const n = f / (2 - f);
  final e = math.sqrt(f * (2 - f));
  final aa = a / (1 + n) * (1 + n * n / 4 + math.pow(n, 4) / 64);
  final al = [
    n / 2 - 2 * n * n / 3 + 5 * math.pow(n, 3) / 16,
    13 * n * n / 48 - 3 * math.pow(n, 3) / 5,
    61 * math.pow(n, 3) / 240,
  ];
  final zone = ((lon + 180) / 6).floor() % 60 + 1;
  final lon0 = (zone - 1) * 6 - 180 + 3;
  final phi = lat * math.pi / 180;
  final dl = (lon - lon0) * math.pi / 180;
  double atanh(double x) => 0.5 * math.log((1 + x) / (1 - x));
  double sinh(double x) => (math.exp(x) - math.exp(-x)) / 2;
  double cosh(double x) => (math.exp(x) + math.exp(-x)) / 2;
  final t = sinh(atanh(math.sin(phi)) - e * atanh(e * math.sin(phi)));
  final xi = math.atan2(t, math.cos(dl));
  final eta = atanh(math.sin(dl) / math.sqrt(1 + t * t));
  var x = xi, y = eta;
  for (var j = 1; j <= 3; j++) {
    x += al[j - 1] * math.sin(2 * j * xi) * cosh(2 * j * eta);
    y += al[j - 1] * math.cos(2 * j * xi) * sinh(2 * j * eta);
  }
  final east = 500000 + 0.9996 * aa * y;
  var north = 0.9996 * aa * x;
  if (lat < 0) north += 10000000;
  const bands = 'CDEFGHJKLMNPQRSTUVWX';
  final b = bands[(((lat + 80) / 8).floor()).clamp(0, 19)];
  return Utm(zone, b, lat < 0, east, north);
}

/// MGRS com 1 m de precisão: "23K LP 33624 94647"
String toMgrs(double lat, double lon) {
  final u = toUtm(lat, lon);
  const sets = ['ABCDEFGH', 'JKLMNPQR', 'STUVWXYZ'];
  const rows = 'ABCDEFGHJKLMNPQRSTUV';
  final ci = (u.easting / 100000).floor() - 1;
  final ri = ((u.northing / 100000).floor() + (u.zone.isEven ? 5 : 0)) % 20;
  final e = (u.easting % 100000).floor().toString().padLeft(5, '0');
  final n = (u.northing % 100000).floor().toString().padLeft(5, '0');
  return '${u.zone}${u.band} ${sets[(u.zone - 1) % 3][ci]}${rows[ri]} $e $n';
}

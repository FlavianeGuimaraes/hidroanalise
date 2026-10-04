import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../domain/poco.dart';

class _Layer {
  const _Layer(this.from, this.to, this.color, this.pattern);
  final double from, to; // fração da profundidade
  final Color color;
  final String pattern;
}

const _layers = [
  _Layer(0, .08, Color(0xFFC9A97A), 'dots'), // solo / aterro
  _Layer(.08, .24, Color(0xFFC47F4E), 'diag'), // argila
  _Layer(.24, .5, Color(0xFFA9967F), 'grid'), // saprolito
  _Layer(.5, 1, Color(0xFF8B8F99), 'frac'), // rocha fraturada
];

/// Desenha o perfil litológico animado do poço. Só desenha: quem controla
/// o tempo [t] (0..1, repetindo) é o AnimationController do widget pai.
class WellPainter extends CustomPainter {
  WellPainter(
      {required this.poco,
      required this.simFlow,
      required this.t,
      required this.label,
      required this.muted});
  final Poco poco;
  final double simFlow, t;
  final Color label, muted;

  @override
  void paint(Canvas canvas, Size size) {
    final double depth =
        (poco.depth ?? 100).clamp(1, double.infinity).toDouble();
    const top = 26.0;
    final bottom = size.height - 26.0;
    double y(double d) =>
        top + (d.clamp(0, depth).toDouble() / depth) * (bottom - top);

    final shaftX = size.width * .36,
        shaftW = size.width * .24,
        cx = shaftX + shaftW / 2;
    final double ne = poco.ne ?? 0.0;
    final double testFlow = poco.testFlow ?? 0.0;
    final double s = (poco.nd ?? ne) - ne;
    final double simND = testFlow > 0 ? ne + simFlow * s / testFlow : ne;
    final casingDepth = min(poco.pumpHeight ?? depth * .32, depth * .9);
    final hasWater = ne < depth;
    final pumping = hasWater && (poco.reqFlow ?? 0.0) > 0;

    final shaft = RRect.fromRectAndRadius(
        Rect.fromLTWH(shaftX, top, shaftW, bottom - top),
        const Radius.circular(6));

    // camadas + água (recortadas no formato do poço)
    canvas.save();
    canvas.clipRRect(shaft);
    for (final l in _layers) {
      final r = Rect.fromLTWH(shaftX, y(depth * l.from), shaftW,
          max(y(depth * l.to) - y(depth * l.from), 0.5));
      canvas.drawRect(r, Paint()..color = l.color);
      _pattern(canvas, r, l.pattern);
    }
    if (hasWater) {
      final w = Rect.fromLTWH(shaftX, y(ne), shaftW, y(depth) - y(ne));
      canvas.drawRect(
          w,
          Paint()
            ..shader = const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xCC8EC8FF), Color(0xEB2F7BF6)])
                .createShader(w));
      _wave(canvas, shaftX, shaftW, y(ne));
      _bubbles(canvas, shaftX, shaftW, y(ne), y(depth));
    }
    canvas.restore();
    canvas.drawRRect(
        shaft,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = muted.withOpacity(.5));

    // revestimento
    final casing =
        Rect.fromLTWH(cx - 11, y(0), 22, max(y(casingDepth) - y(0), 2.0));
    canvas.drawRect(
        casing,
        Paint()
          ..shader = const LinearGradient(colors: [
            Color(0xFFEEF1F5),
            Color(0xFF9AA4B2),
            Color(0xFF9AA4B2),
            Color(0xFFEEF1F5)
          ], stops: [
            0,
            .42,
            .58,
            1
          ]).createShader(casing));
    // filtro (tela)
    final screen = Rect.fromLTWH(
        cx - 8, y(casingDepth), 16, max(y(depth) - y(casingDepth), 2.0));
    canvas.drawRect(screen, Paint()..color = const Color(0xFFC3CAD4));
    final slot = Paint()
      ..color = const Color(0xFF8A94A3)
      ..strokeWidth = .8;
    for (double sy = y(casingDepth) + 8; sy < y(depth); sy += 9) {
      canvas.drawLine(Offset(cx - 8, sy), Offset(cx + 8, sy), slot);
    }

    // setas de fluxo subindo pelo revestimento
    if (pumping) {
      canvas.save();
      canvas.clipRect(casing);
      for (var i = 0; i < 3; i++) {
        final ph = (t + i / 3) % 1.0;
        final ay = y(casingDepth) - 8 - ph * casing.height;
        final op = sin(ph * pi).clamp(0.0, 1.0).toDouble();
        canvas.drawPath(
            Path()
              ..moveTo(cx - 3, ay + 6)
              ..lineTo(cx, ay)
              ..lineTo(cx + 3, ay + 6)
              ..close(),
            Paint()..color = const Color(0xFFBCDCFF).withOpacity(op * .9));
      }
      canvas.restore();
    }

    // bomba
    if (poco.pumpHeight != null) {
      final py = y(poco.pumpHeight!);
      if (pumping) {
        canvas.drawCircle(
            Offset(cx, py),
            9 + t * 7,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5
              ..color = AppColors.blue.withOpacity((1 - t) * .6));
      }
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset(cx, py), width: 18, height: 14),
              const Radius.circular(3)),
          Paint()..color = AppColors.navy);
      canvas.drawCircle(Offset(cx, py), 2, Paint()..color = AppColors.blue);
      _dashed(
          canvas,
          Offset(cx + 11, py),
          Offset(size.width * .22, py),
          Paint()
            ..color = label
            ..strokeWidth = 1);
      _text(canvas, 'Bomba ${poco.pumpHeight!.toStringAsFixed(1)} m',
          Offset(4, py - 12), label,
          align: TextAlign.right, width: size.width * .22 - 4);
    }

    // níveis NE e ND
    _dashed(
        canvas,
        Offset(shaftX - 2, y(ne)),
        Offset(size.width - 4, y(ne)),
        Paint()
          ..color = label
          ..strokeWidth = 1.3);
    _text(canvas, 'NE ${ne.toStringAsFixed(1)} m',
        Offset(shaftX + shaftW * .3, y(ne) - 16), label);
    _dashed(
        canvas,
        Offset(shaftX - 2, y(simND)),
        Offset(size.width - 4, y(simND)),
        Paint()
          ..color = AppColors.cyan
          ..strokeWidth = 1.3);
    _text(canvas, 'ND simulado ${simND.toStringAsFixed(1)} m',
        Offset(shaftX + shaftW * .3, y(simND) + 4), AppColors.cyan);

    // régua de profundidade
    for (final p in [0.0, .25, .5, .75, 1.0]) {
      final d = (depth * p).roundToDouble();
      canvas.drawLine(Offset(shaftX - 18, y(d)), Offset(shaftX - 12, y(d)),
          Paint()..color = muted);
      _text(canvas, '${d.round()}', Offset(0, y(d) - 6), muted,
          align: TextAlign.right, width: shaftX - 20);
    }
    _text(canvas, 'TERRENO', Offset(shaftX, top - 18), muted);
    _text(canvas, 'FUNDO · ${depth.round()} m', Offset(shaftX, bottom + 8),
        muted);
  }

  void _pattern(Canvas canvas, Rect r, String type) {
    final p = Paint()
      ..color = Colors.black.withOpacity(.12)
      ..strokeWidth = .8;
    switch (type) {
      case 'dots':
        for (double yy = r.top + 3; yy < r.bottom; yy += 7) {
          for (double xx = r.left + 3; xx < r.right; xx += 8) {
            canvas.drawCircle(Offset(xx, yy), .8, p);
          }
        }
      case 'diag':
        for (double xx = r.left; xx < r.right + r.height; xx += 7) {
          canvas.drawLine(
              Offset(xx, r.bottom), Offset(xx - r.height, r.top), p);
        }
      case 'grid':
        for (double yy = r.top; yy < r.bottom; yy += 9) {
          canvas.drawLine(Offset(r.left, yy), Offset(r.right, yy), p);
        }
        for (double xx = r.left; xx < r.right; xx += 9) {
          canvas.drawLine(Offset(xx, r.top), Offset(xx, r.bottom), p);
        }
      default: // frac
        final rnd = Random(r.top.toInt());
        for (double yy = r.top; yy < r.bottom; yy += 13) {
          canvas.drawLine(Offset(r.left + rnd.nextDouble() * r.width, yy),
              Offset(r.left + rnd.nextDouble() * r.width, yy + 10), p);
        }
    }
  }

  void _wave(Canvas canvas, double x0, double w, double yBase) {
    const period = 16.0, amp = 2.6;
    final phase = t * period;
    final path = Path()..moveTo(x0 - period, yBase);
    var x = x0 - period;
    var up = true;
    while (x < x0 + w + period) {
      path.quadraticBezierTo(x - phase + period / 4, yBase + (up ? -amp : amp),
          x - phase + period / 2, yBase);
      x += period / 2;
      up = !up;
    }
    canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = Colors.white.withOpacity(.65));
  }

  void _bubbles(
      Canvas canvas, double x0, double w, double topY, double bottomY) {
    const specs = [
      [.25, 3.4, .0],
      [.5, 2.8, .3],
      [.75, 3.8, .6],
      [.4, 3.1, .8]
    ];
    for (final s in specs) {
      final ph = ((t / (s[1] / 4)) + s[2]) % 1.0;
      canvas.drawCircle(
          Offset(x0 + s[0] * w, bottomY - ph * (bottomY - topY)),
          1.6,
          Paint()
            ..color = Colors.white
                .withOpacity(sin(ph * pi).clamp(0.0, 1.0).toDouble() * .75));
    }
  }

  void _dashed(Canvas canvas, Offset a, Offset b, Paint paint) {
    final total = (b - a).distance;
    if (total == 0) return;
    final dir = (b - a) / total;
    for (double d = 0; d < total; d += 7) {
      canvas.drawLine(a + dir * d, a + dir * min(d + 4, total), paint);
    }
  }

  void _text(Canvas canvas, String s, Offset pos, Color color,
      {TextAlign align = TextAlign.left, double? width}) {
    TextPainter(
      text: TextSpan(text: s, style: TextStyle(color: color, fontSize: 9.5)),
      textAlign: align,
      textDirection: TextDirection.ltr,
    )
      ..layout(minWidth: width ?? 0, maxWidth: width ?? 260)
      ..paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant WellPainter old) => true; // anima o tempo todo
}

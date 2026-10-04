import 'package:flutter/material.dart';
import '../../core/app_theme.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 40});
  final double size;
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
            shape: BoxShape.circle, gradient: AppColors.gradient),
        child: Icon(Icons.water_drop, color: Colors.white, size: size * .55),
      );
}

class CardBox extends StatelessWidget {
  const CardBox(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(16)});
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: p.border)),
      child: child,
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: Text(text.toUpperCase(),
            style: TextStyle(
                fontSize: 11,
                letterSpacing: .5,
                color: Palette.of(context).muted)),
      );
}

class StatCard extends StatelessWidget {
  const StatCard(this.label, this.value, {super.key, this.sub});
  final String label, value;
  final String? sub;
  @override
  Widget build(BuildContext context) {
    final muted = Palette.of(context).muted;
    return CardBox(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: TextStyle(fontSize: 10, color: muted, letterSpacing: .3)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        if (sub != null)
          Text(sub!, style: TextStyle(fontSize: 10.5, color: muted)),
      ]),
    );
  }
}

/// Grade de 2 colunas que se ajusta à altura de cada card.
class StatGrid extends StatelessWidget {
  const StatGrid(this.children, {super.key});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        final w = (c.maxWidth - 10) / 2;
        return Wrap(spacing: 10, runSpacing: 10, children: [
          for (final ch in children) SizedBox(width: w, child: ch),
        ]);
      });
}

class StatusBadge extends StatelessWidget {
  const StatusBadge(
      {super.key, required this.ok, required this.yes, required this.no});
  final bool ok;
  final String yes, no;
  @override
  Widget build(BuildContext context) {
    final c = ok ? AppColors.ok : AppColors.warn;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 11),
      alignment: Alignment.center,
      decoration: BoxDecoration(
          color: c.withOpacity(.14),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: c.withOpacity(.4))),
      child: Text(ok ? yes : no,
          style:
              TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton(this.label, this.onPressed, {super.key});
  final String label;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
              backgroundColor: AppColors.blue,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11))),
          child:
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      );
}

/// Campo de texto com ícone, botão de mostrar/ocultar senha e modo numérico.
class IconField extends StatefulWidget {
  const IconField({
    super.key,
    required this.controller,
    required this.label,
    this.icon,
    this.password = false,
    this.number = false,
    this.keyboard,
    this.validator,
    this.onChanged,
  });
  final TextEditingController controller;
  final String label;
  final IconData? icon;
  final bool password, number;
  final TextInputType? keyboard;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  @override
  State<IconField> createState() => _IconFieldState();
}

class _IconFieldState extends State<IconField> {
  bool _hide = true;
  @override
  Widget build(BuildContext context) => TextFormField(
        controller: widget.controller,
        obscureText: widget.password && _hide,
        keyboardType: widget.keyboard ??
            (widget.number
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.text),
        validator: widget.validator,
        onChanged: widget.onChanged,
        decoration: InputDecoration(
          labelText: widget.label,
          prefixIcon: widget.icon == null ? null : Icon(widget.icon, size: 20),
          suffixIcon: widget.password
              ? IconButton(
                  icon: Icon(_hide ? Icons.visibility_off : Icons.visibility,
                      size: 20),
                  onPressed: () => setState(() => _hide = !_hide))
              : null,
        ),
      );
}

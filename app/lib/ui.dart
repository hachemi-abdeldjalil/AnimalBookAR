import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The app's look in one place: colours, card style, section headers and
/// small building blocks shared by the welcome, bookshelf and parents screens.
class AppColors {
  // A bright, friendly palette: a vivid orange accent, deep navy text, and five
  // fun colours for tiles and charts.
  static const brand = Color(0xFFFF6B35);
  static const brandDark = Color(0xFFE2471A);
  static const ink = Color(0xFF1F2547);
  static const muted = Color(0xFF666C8F);
  static const faint = Color(0xFFA3A8C3);
  static const cream = Color(0xFFFFF8EF);
  static const sand = Color(0xFFF3EEE7);
  static const line = Color(0xFFECE5DA);
  static const gold = Color(0xFFFFB81C);
  static const goldBg = Color(0xFFFFF1C7);
  static const green = Color(0xFF22B07D);
  static const sky = Color(0xFF2D9CDB);
  static const grape = Color(0xFF7B61FF);
  static const mint = Color(0xFF14B8A6);
  static const berry = Color(0xFFF2547D);
}

/// A white card with a hairline border and a soft shadow.
class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.onTap, this.color});
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
        boxShadow: const [BoxShadow(color: Color(0x0F2B2118), blurRadius: 14, offset: Offset(0, 4))],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// "YOUR BOOKS" style label above a group, with an optional action on the end.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(4, 22, 4, 10),
      child: Row(children: [
        Expanded(
          child: Text(text.toUpperCase(),
              style: const TextStyle(
                  fontSize: 12.5, fontWeight: FontWeight.w800, letterSpacing: 1.1, color: AppColors.muted)),
        ),
        if (trailing != null) trailing!,
      ]),
    );
  }
}

/// A round initial for a child.
class Avatar extends StatelessWidget {
  const Avatar({super.key, required this.name, this.size = 44, this.selected = false, this.picture});
  final String name;
  final String? picture; // a sticker asset, instead of the initial
  final double size;
  final bool selected;

  static const _palette = [
    Color(0xFFE8702A),
    Color(0xFF2F6FD0),
    Color(0xFF00897B),
    Color(0xFFD81B60),
    Color(0xFF7E57C2),
    Color(0xFF6B8E23),
  ];

  @override
  Widget build(BuildContext context) {
    final c = _palette[name.isEmpty ? 0 : name.codeUnitAt(0) % _palette.length];
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: picture != null ? Color.lerp(c, Colors.white, 0.75) : c,
        border: Border.all(color: selected ? AppColors.ink : Colors.white, width: selected ? 3 : 2),
        boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: picture != null
          ? Padding(
              padding: EdgeInsets.all(size * 0.08),
              child: Image.asset(picture!, fit: BoxFit.contain),
            )
          : Text(name.isEmpty ? '?' : name.characters.first.toUpperCase(),
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: size * 0.42)),
    );
  }
}

/// The star count chip.
class StarsChip extends StatelessWidget {
  const StarsChip(this.stars, {super.key});
  final int stars;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('stars'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(color: AppColors.goldBg, borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.star_rounded, color: AppColors.gold, size: 20),
        const SizedBox(width: 4),
        Text('$stars', style: const TextStyle(color: Color(0xFF8A5A00), fontWeight: FontWeight.w800, fontSize: 15)),
      ]),
    );
  }
}

/// A big number with a label and an icon (dashboards).
class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.icon, this.value = '', this.count, required this.label, this.color});
  final IconData icon;
  final String value;
  final int? count; // counts up when given (instead of [value])
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.brand;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 18, color: c),
        ),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: count != null
              ? CountUp(count!, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.ink))
              : Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.ink)),
        ),
        Text(label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11.5, color: AppColors.muted, height: 1.2)),
      ]),
    );
  }
}

/// A thin rounded progress bar.
class ProgressBar extends StatelessWidget {
  const ProgressBar({super.key, required this.value, required this.color, this.height = 8, this.track});
  final double value;
  final Color color;
  final double height;
  final Color? track;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: LinearProgressIndicator(
        value: value.clamp(0, 1),
        minHeight: height,
        backgroundColor: track ?? color.withOpacity(0.15),
        color: color,
      ),
    );
  }
}

// ---- motion -----------------------------------------------------------------

/// Fades and slides its child in once, after [delay] (for lists: 60 ms × index).
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({super.key, required this.child, this.delay = Duration.zero, this.offset = 24});
  final Widget child;
  final Duration delay;
  final double offset;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
  late final Animation<double> _t = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _c.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      builder: (context, child) => Opacity(
        opacity: _t.value,
        child: Transform.translate(offset: Offset(0, widget.offset * (1 - _t.value)), child: child),
      ),
      child: widget.child,
    );
  }
}

/// Shrinks a little while pressed, then springs back: a tactile tap.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, required this.onTap});
  final Widget child;
  final VoidCallback? onTap;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.95 : 1,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutBack,
        child: widget.child,
      ),
    );
  }
}

/// Bobs gently up and down (and tilts a touch), for stickers and pictures.
class Floating extends StatefulWidget {
  const Floating({super.key, required this.child, this.amount = 6, this.phase = 0, this.period = 2600});
  final Widget child;
  final double amount;
  final double phase; // 0..1, so neighbours don't move together
  final int period; // ms

  @override
  State<Floating> createState() => _FloatingState();
}

class _FloatingState extends State<Floating> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: Duration(milliseconds: widget.period))
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final a = (_c.value + widget.phase) * 2 * math.pi;
        return Transform.translate(
          offset: Offset(0, widget.amount * -0.5 * (1 - math.cos(a))),
          child: Transform.rotate(angle: 0.025 * math.sin(a), child: child),
        );
      },
      child: widget.child,
    );
  }
}

/// A number that counts up to its new value.
class CountUp extends StatelessWidget {
  const CountUp(this.value, {super.key, this.style, this.suffix = ''});
  final int value;
  final TextStyle? style;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text('${v.round()}$suffix', style: style),
    );
  }
}

/// A ring that fills to [value] (0..1) with the percentage in the middle.
class ProgressRing extends StatelessWidget {
  const ProgressRing({super.key, required this.value, this.size = 54, this.color = Colors.white, this.track});
  final double value;
  final double size;
  final Color color;
  final Color? track;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.clamp(0, 1)),
      duration: const Duration(milliseconds: 1100),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => SizedBox(
        width: size,
        height: size,
        child: Stack(alignment: Alignment.center, children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: v,
              strokeWidth: size * 0.11,
              strokeCap: StrokeCap.round,
              color: color,
              backgroundColor: track ?? color.withOpacity(0.25),
            ),
          ),
          Text('${(v * 100).round()}%',
              style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: size * 0.26)),
        ]),
      ),
    );
  }
}

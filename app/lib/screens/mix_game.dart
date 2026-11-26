import 'package:flutter/material.dart';

import '../l10n.dart';
import '../progress.dart';
import '../speech.dart';
import 'home_screen.dart' show ink;

/// Mixing paints (Colors book, no camera): tap two paint pots, they pour into
/// the bowl and make a new colour, which is named aloud.
class MixGame extends StatefulWidget {
  const MixGame({super.key, required this.progress});
  final Progress progress;

  @override
  State<MixGame> createState() => _MixGameState();
}

class _Paint {
  const _Paint(this.id, this.color, this.en, this.fr, this.ar);
  final String id;
  final Color color;
  final String en, fr, ar;
  String name(Lang l) => switch (l) { Lang.en => en, Lang.fr => fr, Lang.ar => ar };
}

const _pots = [
  _Paint('red', Color(0xFFE53935), 'red', 'le rouge', 'الأحمر'),
  _Paint('yellow', Color(0xFFFDD835), 'yellow', 'le jaune', 'الأصفر'),
  _Paint('blue', Color(0xFF1E88E5), 'blue', 'le bleu', 'الأزرق'),
  _Paint('white', Color(0xFFF5F5F5), 'white', 'le blanc', 'الأبيض'),
];

const _results = {
  'red+yellow': _Paint('orange', Color(0xFFFB8C00), 'orange', "l'orange", 'البرتقالي'),
  'blue+yellow': _Paint('green', Color(0xFF43A047), 'green', 'le vert', 'الأخضر'),
  'blue+red': _Paint('purple', Color(0xFF8E24AA), 'purple', 'le violet', 'البنفسجي'),
  'red+white': _Paint('pink', Color(0xFFEC6FA9), 'pink', 'le rose', 'الوردي'),
  'blue+white': _Paint('lightblue', Color(0xFF90CAF9), 'light blue', 'le bleu clair', 'الأزرق الفاتح'),
  'white+yellow': _Paint('lightyellow', Color(0xFFFFF59D), 'light yellow', 'le jaune clair', 'الأصفر الفاتح'),
};

class _MixGameState extends State<MixGame> {
  final List<_Paint> _picked = [];

  _Paint? get _result {
    if (_picked.length < 2) return null;
    final ids = [_picked[0].id, _picked[1].id]..sort();
    return _results[ids.join('+')];
  }

  void _tap(_Paint p) {
    setState(() {
      if (_picked.length == 2) _picked.clear();
      if (_picked.contains(p)) {
        _picked.remove(p);
      } else {
        _picked.add(p);
      }
    });
    final r = _result;
    final lang = widget.progress.lang;
    if (r != null) {
      final s = widget.progress.s;
      final text = s.mixResult(_cap(_picked[0].name(lang)), _picked[1].name(lang), r.name(lang));
      Speech.instance.say(text, lang);
    } else {
      Speech.instance.say(_cap(p.name(lang)), lang);
    }
  }

  String _cap(String t) => t.isEmpty ? t : t[0].toUpperCase() + t.substring(1);

  @override
  Widget build(BuildContext context) {
    final s = widget.progress.s;
    final lang = widget.progress.lang;
    final r = _result;
    Widget blob(Color? c, {double size = 84, Key? key}) => AnimatedContainer(
          key: key,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutBack,
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: c ?? const Color(0xFFF3EEE7),
            shape: BoxShape.circle,
            border: Border.all(color: c == null ? const Color(0xFFECE5DA) : const Color(0x33000000), width: 3),
          ),
          child: c == null ? const Icon(Icons.question_mark_rounded, color: Color(0xFFA3A8C3)) : null,
        );
    return Scaffold(
      appBar: AppBar(title: Text(s.mixGame), backgroundColor: const Color(0xFFFFF8EF)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            Text(s.mixPick, style: const TextStyle(fontSize: 18, color: Color(0xFF666C8F))),
            const SizedBox(height: 30),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                blob(_picked.isNotEmpty ? _picked[0].color : null),
                const Padding(padding: EdgeInsets.all(10), child: Icon(Icons.add_rounded, size: 34, color: ink)),
                blob(_picked.length > 1 ? _picked[1].color : null),
                const Padding(
                    padding: EdgeInsets.all(10), child: Icon(Icons.drag_handle_rounded, size: 34, color: ink)),
                blob(r?.color, size: 104, key: const Key('mix-result')),
              ]),
            ),
            const SizedBox(height: 22),
            SizedBox(
              height: 70,
              child: r == null
                  ? null
                  : Text(
                      s.mixResult(_cap(_picked[0].name(lang)), _picked[1].name(lang), r.name(lang)),
                      key: const Key('mix-text'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: ink),
                    ),
            ),
            const Spacer(),
            Wrap(spacing: 18, runSpacing: 18, alignment: WrapAlignment.center, children: [
              for (final p in _pots)
                GestureDetector(
                  key: Key('pot-${p.id}'),
                  onTap: () => _tap(p),
                  child: Column(children: [
                    AnimatedScale(
                      scale: _picked.contains(p) ? 1.15 : 1,
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: p.color,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                              color: _picked.contains(p) ? ink : const Color(0x22000000),
                              width: _picked.contains(p) ? 4 : 2),
                          boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 6, offset: Offset(0, 3))],
                        ),
                        child: const Icon(Icons.format_paint_rounded, color: Color(0x88FFFFFF), size: 30),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(_cap(p.name(lang).replaceFirst(RegExp(r"^(le |l')"), '').replaceFirst('ال', '')),
                        style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF3D4266))),
                  ]),
                ),
            ]),
            const SizedBox(height: 30),
          ]),
        ),
      ),
    );
  }
}

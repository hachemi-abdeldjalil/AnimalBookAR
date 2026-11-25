import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../animals.dart';
import '../progress.dart';

/// The book's map on the home screen, one theme per book ("map" in
/// books.json): a zoo (animals), a town (vehicles), a notebook page
/// (letters), a paint studio (colours) and the Sahara (Algeria). A path runs
/// from the gate past one stop per item, where the item's 3D model stands;
/// a little scene sits next to each stop. Drawn in code at a 360-wide design
/// size and scaled to the screen.
class ZooPath extends StatelessWidget {
  const ZooPath({
    super.key,
    required this.progress,
    required this.level,
    required this.onTap,
    this.highlight,
  });

  final Progress progress;
  final int level; // which level's progress the signs show (1..3)
  final String? highlight; // the mission animal, drawn bigger with a pulse
  final void Function(Animal) onTap;

  static const designWidth = 360.0;

  /// The sign under each stop, in each map's colours.
  static const signColors = {
    'zoo': Color(0xFF8B5A2B),
    'town': Color(0xFF2F4A6D),
    'school': Color(0xFF2E5E4E),
    'studio': Color(0xFF6A4FB5),
    'desert': Color(0xFF006233),
    'playroom': Color(0xFF7E57C2),
  };
  static const _step = 152.0; // between enclosures

  /// Enclosure centres for [n] animals, zig-zagging down, in design units.
  static List<Offset> spotsFor(int n) => [for (var i = 0; i < n; i++) Offset(i.isEven ? 108 : 252, 220 + i * _step)];
  static double heightFor(int n) => 220 + (n - 1) * _step + 140;

  /// Enclosure centres, in design units, in book order.

  @override
  Widget build(BuildContext context) {
    final animals = progress.animals;
    final style = progress.book.map;
    return LayoutBuilder(builder: (context, c) {
      final k = c.maxWidth / designWidth;
      return SizedBox(
        width: c.maxWidth,
        height: heightFor(animals.length) * k,
        child: Stack(clipBehavior: Clip.none, children: [
          Positioned.fill(
            child: CustomPaint(
                painter: _ZooPainter(
              style: style,
              gateText: switch (style) {
                'town' => progress.s.town,
                'zoo' => progress.s.zoo,
                _ => progress.book.title(progress.lang).toUpperCase(),
              },
              ids: [for (final a in animals) a.id],
              colors: [for (final a in animals) a.color],
              labels: [for (final a in animals) a.letter ?? ''],
              habitats: [for (final a in animals) a.habitat ?? ''],
              habitatNames: [for (final a in animals) a.habitat == null ? '' : progress.s.habitatName(a.habitat!)],
            )),
          ),
          for (var i = 0; i < animals.length; i++)
            Positioned(
              left: spotsFor(animals.length)[i].dx * k - 60,
              top: spotsFor(animals.length)[i].dy * k - 52,
              width: 120,
              child: _AnimalStop(
                animal: animals[i],
                progress: progress,
                level: level,
                current: animals[i].id == highlight,
                signColor: signColors[style],
                onTap: () => onTap(animals[i]),
              ),
            ),
        ]),
      );
    });
  }
}

/// A round photo in its enclosure, with a wooden sign showing the progress.
class _AnimalStop extends StatefulWidget {
  const _AnimalStop({
    required this.animal,
    required this.progress,
    required this.level,
    required this.current,
    required this.onTap,
    this.signColor,
  });

  final Color? signColor;
  final Animal animal;
  final Progress progress;
  final int level;
  final bool current;
  final VoidCallback onTap;

  @override
  State<_AnimalStop> createState() => _AnimalStopState();
}

class _AnimalStopState extends State<_AnimalStop> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    if (widget.current) _pulse.repeat();
  }

  @override
  void didUpdateWidget(covariant _AnimalStop old) {
    super.didUpdateWidget(old);
    if (widget.current && !_pulse.isAnimating) _pulse.repeat();
    if (!widget.current && _pulse.isAnimating) _pulse.stop();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.animal;
    final p = widget.progress;
    final lang = p.lang;
    final met = p.met(a.id);
    final done = p.animalDone(a, widget.level);
    final size = widget.current ? 100.0 : 84.0;

    final (score, total) = switch (widget.level) {
      1 => (met ? 1 : 0, 1),
      2 => (p.partsFound(a), a.parts.length),
      _ => (p.quizScore(a.id), quizGoal),
    };

    // The 3D model standing on the map; softer (less colour, a little faded) until it is met.
    Widget sticker = Image.asset(a.stickerAsset,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) =>
            ClipOval(child: Image.asset(a.thumbAsset, width: size * 0.8, height: size * 0.8)));
    if (!met) {
      sticker =
          Opacity(opacity: 0.8, child: ColorFiltered(colorFilter: const ColorFilter.matrix(_soft), child: sticker));
    }

    return Semantics(
      button: true,
      label: a.name(lang),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
            width: 116,
            height: 108,
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (context, child) {
                final t = widget.current ? _pulse.value : 0.0;
                return Stack(alignment: Alignment.bottomCenter, clipBehavior: Clip.none, children: [
                  // the platform: a coloured disc with a soft shadow, a pulse when it's the mission
                  if (widget.current)
                    Positioned(
                      bottom: 2 - 6 * t,
                      child: Container(
                        width: 84 + 30 * t,
                        height: 26 + 10 * t,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.elliptical(57 + 15 * t, 18 + 5 * t)),
                          border: Border.all(color: a.color.withOpacity(0.6 * (1 - t)), width: 3),
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: 4,
                    child: Container(
                      width: 82,
                      height: 24,
                      decoration: BoxDecoration(
                        color: done ? const Color(0xFF2E9E6A) : (met ? a.color : const Color(0xFFBFB3A3)),
                        borderRadius: const BorderRadius.all(Radius.elliptical(41, 12)),
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 6, offset: Offset(0, 3))],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12 + (widget.current ? 6 * math.sin(t * math.pi) : 0),
                    child: sticker,
                  ),
                  if (!met)
                    Positioned(
                      top: 0,
                      right: 14,
                      child: Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: a.color, width: 2.5),
                          boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 4, offset: Offset(0, 2))],
                        ),
                        child: Text('?', style: TextStyle(color: a.color, fontWeight: FontWeight.w900, fontSize: 16)),
                      ),
                    ),
                  if (done)
                    Positioned(
                      top: 2,
                      right: 14,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF2E9E6A),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
                      ),
                    ),
                ]);
              },
            ),
          ),
          const SizedBox(height: 2),
          // the sign
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: widget.signColor ?? const Color(0xFF8B5A2B),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: Colors.white.withOpacity(0.35), width: 1.5),
              boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 3, offset: Offset(0, 2))],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Flexible(
                child: Text(a.name(lang),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xFFFFF4DC), fontWeight: FontWeight.w700, fontSize: 12)),
              ),
              if (widget.level > 1 && met) ...[
                const SizedBox(width: 6),
                Text('$score/$total',
                    style: const TextStyle(color: Color(0xFFFFD166), fontWeight: FontWeight.w800, fontSize: 11)),
              ],
            ]),
          ),
        ]),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _ZooPainter extends CustomPainter {
  _ZooPainter({
    required this.style,
    required this.gateText,
    required this.ids,
    this.colors = const [],
    this.labels = const [],
    this.habitats = const [],
    this.habitatNames = const [],
  });

  final String style; // zoo | town | school | studio | desert | playroom
  final String gateText;
  final List<String> ids; // item ids in path order, for their scenes
  final List<Color> colors; // each item's colour (paint pots)
  final List<String> labels; // each item's letter (toy blocks)
  final List<String> habitats; // the zoo: each animal's habitat, drawn as the ground of its row
  final List<String> habitatNames; // its name, on a little sign

  bool get town => style == 'town';

  static const _grass = Color(0xFFCDE8B0);
  static const _grassLight = Color(0xFFDDF1C6);
  static const _sand = Color(0xFFF2E3C2);
  static const _sandEdge = Color(0xFFDDC48F);
  static const _wood = Color(0xFF9A6A3A);
  static const _woodDark = Color(0xFF6E4520);
  static const _rainbow = [
    Color(0xFFE53935),
    Color(0xFFFB8C00),
    Color(0xFFFDD835),
    Color(0xFF43A047),
    Color(0xFF1E88E5),
    Color(0xFF8E24AA),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / ZooPath.designWidth;
    canvas.save();
    canvas.scale(k);
    const w = ZooPath.designWidth;
    final h = ZooPath.heightFor(ids.length);
    final spots = ZooPath.spotsFor(ids.length);
    // each item's scene sits in the other column, level with its stop
    final scenePos = [for (final s in spots) Offset(s.dx < w / 2 ? s.dx + 150 : s.dx - 150, s.dy - 8)];
    final rnd = math.Random(7); // fixed seed: the same map every time

    // ---- ground ----
    final bg = RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h), const Radius.circular(28));
    canvas.save();
    canvas.clipRRect(bg);
    _ground(canvas, w, h, rnd);
    if (style == 'zoo') _habitats(canvas, w, h, spots);

    // ---- the path: gate -> each stop -> exit ----
    final path = Path()..moveTo(w / 2, 96);
    var prev = const Offset(w / 2, 96);
    for (final p in [...spots, Offset(w / 2, h + 10)]) {
      final dy = (p.dy - prev.dy) / 2;
      path.cubicTo(prev.dx, prev.dy + dy, p.dx, p.dy - dy, p.dx, p.dy);
      prev = p;
    }
    final samples = <Offset>[];
    for (final m in path.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 6) {
        final t = m.getTangentForOffset(d);
        if (t != null) samples.add(t.position);
      }
    }
    _path(canvas, path);

    // keep decorations off the path and the stops
    bool free(Offset o, double r) {
      for (final s in samples) {
        if ((s - o).distance < r + 24) return false;
      }
      for (final s in spots) {
        if ((s - o).distance < r + 62) return false;
      }
      return o.dy > 120 || (o.dx < 90 || o.dx > 270);
    }

    // ---- a little scene by each stop ----
    for (var i = 0; i < ids.length; i++) {
      final o = scenePos[i];
      final color = colors.length > i ? colors[i] : const Color(0xFF888888);
      switch (style) {
        case 'town':
          _townBuilding(canvas, ids[i], o);
        case 'school' || 'playroom':
          _block(canvas, o, labels.length > i && labels[i].isNotEmpty ? labels[i] : '?', color);
        case 'studio':
          _paintPot(canvas, o, color);
        case 'desert':
          if (i % 3 == 1) {
            _pond(canvas, o + const Offset(0, 12));
            _palm(canvas, o + const Offset(28, -22));
          } else {
            _palm(canvas, o + const Offset(0, -16));
          }
        default:
          _zooScene(canvas, ids[i], o);
      }
    }

    // ---- under the stops ----
    for (final s in spots) {
      if (town) _parking(canvas, s);
      if (style == 'zoo') _fence(canvas, s, 58);
    }

    // ---- decorations wherever there is room ----
    final spotsFree = <Offset>[];
    final count = (h / 44).round();
    for (var i = 0; i < 400 && spotsFree.length < count; i++) {
      final o = Offset(14 + rnd.nextDouble() * (w - 28), 110 + rnd.nextDouble() * (h - 130));
      if (!free(o, 22) || spotsFree.any((t) => (t - o).distance < 46)) continue;
      if (scenePos.any((p) => (p - o).distance < 70)) continue; // keep scenes clear
      spotsFree.add(o);
    }
    spotsFree.sort((a, b) => a.dy.compareTo(b.dy)); // back to front
    for (var i = 0; i < spotsFree.length; i++) {
      _decoration(canvas, spotsFree[i], i);
    }
    for (var i = 0; i < (h / 13).round(); i++) {
      final o = Offset(rnd.nextDouble() * w, 110 + rnd.nextDouble() * (h - 110));
      if (!free(o, 4)) continue;
      _speck(canvas, o, i);
    }
    if (style == 'zoo') _habitatSigns(canvas, w, h, spots);
    canvas.restore(); // clip

    _gate(canvas, const Offset(w / 2, 58));
    canvas.restore(); // scale
  }

  // ---- per theme ----
  void _ground(Canvas c, double w, double h, math.Random rnd) {
    switch (style) {
      case 'school': // a page of a school notebook
        c.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = const Color(0xFFFFFDF4));
        final line = Paint()
          ..color = const Color(0x553F7FD0)
          ..strokeWidth = 1;
        for (var y = 30.0; y < h; y += 24) {
          c.drawLine(Offset(0, y), Offset(w, y), line);
        }
        c.drawLine(
            const Offset(34, 0),
            Offset(34, h),
            Paint()
              ..color = const Color(0x88E04F3F)
              ..strokeWidth = 1.6);
      case 'studio': // a white canvas with soft splashes of every colour
        c.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = const Color(0xFFFFFCF7));
        for (var y = 80.0, i = 0; y < h; y += 110, i++) {
          final col = (colors.isEmpty ? _rainbow : colors)[i % (colors.isEmpty ? _rainbow.length : colors.length)];
          c.drawOval(Rect.fromCenter(center: Offset(i.isEven ? 50 : 310, y), width: 170, height: 110),
              Paint()..color = col.withOpacity(0.12));
        }
      case 'desert': // the Sahara: warm sand and dunes
        c.drawRect(
            Rect.fromLTWH(0, 0, w, h),
            Paint()
              ..shader = const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFF6DFAE), Color(0xFFEBC383)],
              ).createShader(Rect.fromLTWH(0, 0, w, h)));
        final dune = Paint()
          ..color = const Color(0x33B5762E)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        for (var y = 140.0, left = true; y < h; y += 95, left = !left) {
          final x0 = left ? -20.0 : 160.0;
          c.drawPath(
              Path()
                ..moveTo(x0, y + 20)
                ..quadraticBezierTo(x0 + 110, y - 25, x0 + 220, y + 20),
              dune);
          c.drawOval(Rect.fromCenter(center: Offset(x0 + 110, y + 8), width: 170, height: 34),
              Paint()..color = const Color(0x18FFFFFF));
        }
      case 'playroom': // a wooden floor
        c.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = const Color(0xFFEBD2A6));
        final plank = Paint()
          ..color = const Color(0x33A0723A)
          ..strokeWidth = 1.5;
        for (var y = 0.0, row = 0; y < h; y += 30, row++) {
          c.drawLine(Offset(0, y), Offset(w, y), plank);
          for (var x = (row.isEven ? 40.0 : 110.0); x < w; x += 150) {
            c.drawLine(Offset(x, y), Offset(x, y + 30), plank);
          }
        }
      case 'town':
        c.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = const Color(0xFFD5E3C6));
        _patches(c, w, h, const Color(0xFFE3ECD6));
      default:
        c.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = _grass);
        _patches(c, w, h, _grassLight);
    }
  }

  void _patches(Canvas c, double w, double h, Color color) {
    final patch = Paint()..color = color;
    for (var y = 120.0, left = true; y < h; y += 140, left = !left) {
      c.drawOval(Rect.fromCenter(center: Offset(left ? 60 : 300, y), width: 150, height: 70), patch);
    }
  }

  Paint _stroke(Color color, double width) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round;

  void _path(Canvas c, Path path) {
    switch (style) {
      case 'town': // a road with a dashed white line
        c.drawPath(path, _stroke(const Color(0xFF5E6670), 48));
        c.drawPath(path, _stroke(const Color(0xFF7A838E), 41));
        _alongPath(c, path, 28, (a, b) => c.drawLine(a, b, _stroke(const Color(0xFFF4F4F4), 3)), dash: 12);
      case 'school': // a fat yellow pencil line, with the graphite in the middle
        c.drawPath(path, _stroke(const Color(0xFFD9A520), 40));
        c.drawPath(path, _stroke(const Color(0xFFF7C948), 34));
        c.drawPath(path, _stroke(const Color(0x66FFFFFF), 8));
        _alongPath(c, path, 22, (a, b) => c.drawLine(a, b, _stroke(const Color(0x88444444), 2.4)), dash: 9);
      case 'playroom': // a soft blue rug with white stitches
        c.drawPath(path, _stroke(const Color(0xFF3F6CC0), 46));
        c.drawPath(path, _stroke(const Color(0xFF6C98E6), 38));
        _alongPath(c, path, 16, (a, b) => c.drawLine(a, b, _stroke(const Color(0xCCFFFFFF), 2)), dash: 7);
      case 'studio': // a rainbow
        for (var i = 0; i < _rainbow.length; i++) {
          c.drawPath(path, _stroke(_rainbow[i], 46 - i * 7.0));
        }
        c.drawPath(path, _stroke(Colors.white, 5));
      case 'desert': // a sandy track with camel footprints
        c.drawPath(path, _stroke(const Color(0xFFDDB97A), 42));
        c.drawPath(path, _stroke(const Color(0xFFF8E6BF), 35));
        final print = Paint()..color = const Color(0x66B5762E);
        var left = true;
        _alongPath(c, path, 16, (a, b) {
          final d = b - a;
          final n = Offset(-d.dy, d.dx) / (d.distance == 0 ? 1 : d.distance);
          c.drawOval(Rect.fromCenter(center: a + n * (left ? 5 : -5), width: 5, height: 6), print);
          left = !left;
        }, dash: 1);
      default: // the zoo's sandy path with footprints
        c.drawPath(path, _stroke(_sandEdge, 44));
        c.drawPath(path, _stroke(_sand, 37));
        _alongPath(c, path, 24, (a, b) => c.drawCircle(a, 2.2, Paint()..color = _sandEdge.withOpacity(0.8)), dash: 1);
    }
  }

  void _alongPath(Canvas c, Path path, double every, void Function(Offset a, Offset b) draw, {double dash = 1}) {
    for (final m in path.computeMetrics()) {
      for (var d = 20.0; d + dash < m.length; d += every) {
        final a = m.getTangentForOffset(d), b = m.getTangentForOffset(d + dash);
        if (a != null && b != null) draw(a.position, b.position);
      }
    }
  }

  void _decoration(Canvas c, Offset o, int i) {
    switch (style) {
      case 'school':
        if (i % 3 == 0) {
          _crayon(c, o, _rainbow[i % _rainbow.length], i.isEven ? -0.6 : 0.5);
        } else if (i % 3 == 1) {
          _doodleStar(c, o, _rainbow[(i + 2) % _rainbow.length]);
        } else {
          _pencil(c, o, i.isEven ? 0.4 : -0.3);
        }
      case 'playroom':
        if (i % 2 == 0) {
          _toyBall(c, o, _rainbow[i % _rainbow.length]);
        } else {
          _block(c, o, '', _rainbow[(i + 2) % _rainbow.length]);
        }
      case 'studio':
        if (i % 2 == 0) {
          _splat(c, o, _rainbow[i % _rainbow.length]);
        } else {
          _brush(c, o, _rainbow[(i + 3) % _rainbow.length], i % 4 == 1 ? -0.7 : 0.6);
        }
      case 'desert':
        if (i % 3 == 0) {
          _palm(c, o + const Offset(0, -16));
        } else if (i % 3 == 1) {
          _rocks(c, o);
        } else {
          _dune(c, o);
        }
      default:
        // in the zoo, each row's decorations come from its animal's habitat
        final spots = ZooPath.spotsFor(ids.length);
        var k = 0;
        for (var j = 1; j < spots.length; j++) {
          if ((spots[j].dy - o.dy).abs() < (spots[k].dy - o.dy).abs()) k = j;
        }
        switch (habitats.length > k ? habitats[k] : '') {
          case 'forest':
            _pine(c, o, 18 + (i % 4) * 2.0);
            return;
          case 'savannah':
            if (i.isEven) {
              _acacia(c, o + const Offset(0, -10));
            } else {
              _grassTuft(c, o, const Color(0xFFB8A04A));
            }
            return;
          case 'desert':
            if (i.isEven) {
              _palm(c, o + const Offset(0, -16));
            } else {
              _rocks(c, o);
            }
            return;
          case 'wetland':
            _reeds(c, o);
            return;
          case 'farm':
            if (i % 3 == 0) {
              _hay(c, o);
              return;
            }
        }
        if (i % 3 == 1) {
          _pine(c, o, 18 + (i % 4) * 2.0);
        } else {
          _roundTree(c, o, 18 + (i % 5) * 2.0);
        }
    }
  }

  void _speck(Canvas c, Offset o, int i) {
    switch (style) {
      case 'school':
        if (i % 4 == 0) c.drawCircle(o, 1.8, Paint()..color = _rainbow[i % _rainbow.length].withOpacity(0.6));
      case 'studio':
        c.drawCircle(o, 2.2, Paint()..color = _rainbow[i % _rainbow.length].withOpacity(0.55));
      case 'desert':
        if (i.isEven) c.drawCircle(o, 1.6, Paint()..color = const Color(0x55A0682C));
      default:
        final flowerColors = [const Color(0xFFF7A1C4), const Color(0xFFFFD166), const Color(0xFFFFFFFF)];
        c.drawCircle(o, 2.6, Paint()..color = flowerColors[i % 3]);
        c.drawCircle(o, 1, Paint()..color = const Color(0xFFE9A23B));
    }
  }

  void _zooScene(Canvas canvas, String id, Offset o) {
    switch (id) {
      case 'horse' || 'sheep' || 'llama':
        _hay(canvas, o);
      case 'fox' || 'lion':
        _rocks(canvas, o);
      case 'flamingo' || 'elephant':
        _pond(canvas, o);
      case 'camel':
        _palm(canvas, o + const Offset(0, -16));
      case 'parrot':
        _roundTree(canvas, o + const Offset(0, -20), 34);
      case 'stork':
        _nest(canvas, o);
      case 'cow':
        _trough(canvas, o);
      case 'zebra' || 'giraffe':
        _acacia(canvas, o + const Offset(0, -10));
      case 'dog':
        _kennel(canvas, o);
      default:
        _roundTree(canvas, o, 24);
    }
  }

  // ---- zoo habitats ----
  static const _habitatColors = {
    'farm': Color(0xFFE9DCA8),
    'home': Color(0xFFD8EFC2),
    'forest': Color(0xFFA9CF8C),
    'savannah': Color(0xFFEBD48A),
    'desert': Color(0xFFF2DBAA),
    'wetland': Color(0xFFB7E0D3),
  };

  /// Each animal's row takes the colour of its habitat (rows of the same
  /// habitat merge), with a little texture and a sign naming it.
  void _habitats(Canvas c, double w, double h, List<Offset> spots) {
    for (var i = 0; i < spots.length && i < habitats.length; i++) {
      final color = _habitatColors[habitats[i]];
      if (color == null) continue;
      final top = i == 0 ? 120.0 : (spots[i - 1].dy + spots[i].dy) / 2;
      final bottom = i == spots.length - 1 ? h : (spots[i].dy + spots[i + 1].dy) / 2;
      final band = Rect.fromLTRB(0, top, w, bottom);
      c.drawRect(band, Paint()..color = color);
      final rnd = math.Random(i * 31 + 3);
      switch (habitats[i]) {
        case 'farm': // furrows of a field
          final line = Paint()
            ..color = const Color(0x22A07A3A)
            ..strokeWidth = 3;
          for (var y = top + 12; y < bottom; y += 16) {
            c.drawLine(Offset(0, y), Offset(w, y + 6), line);
          }
        case 'wetland': // water
          c.drawOval(
              Rect.fromCenter(center: Offset(spots[i].dx < w / 2 ? w - 70 : 70, bottom - 34), width: 120, height: 36),
              Paint()..color = const Color(0x667CC4E4));
        case 'desert' || 'savannah': // ripples in the sand / dry grass
          final ripple = Paint()
            ..color = const Color(0x22B5762E)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2;
          for (var k = 0; k < 4; k++) {
            final x = rnd.nextDouble() * w, y = top + 20 + rnd.nextDouble() * (bottom - top - 40);
            c.drawArc(Rect.fromCenter(center: Offset(x, y), width: 70, height: 22), math.pi * 1.1, math.pi * 0.8, false,
                ripple);
          }
        default:
          break;
      }
    }
  }

  /// The habitat signs, drawn after the trees so nothing covers them.
  void _habitatSigns(Canvas c, double w, double h, List<Offset> spots) {
    for (var i = 0; i < spots.length && i < habitats.length; i++) {
      final color = _habitatColors[habitats[i]];
      if (color == null) continue;
      final top = i == 0 ? 120.0 : (spots[i - 1].dy + spots[i].dy) / 2;
      // the sign, on the stop's side, near the top of the row
      if (i < habitatNames.length && habitatNames[i].isNotEmpty && (i == 0 || habitats[i] != habitats[i - 1])) {
        final tp = TextPainter(
          text: TextSpan(
              text: habitatNames[i].toUpperCase(),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  fontFamilyFallback: ['Tajawal', 'Poppins'])),
          textDirection: TextDirection.ltr,
        )..layout();
        final left = spots[i].dx < w / 2;
        final r = Rect.fromLTWH(left ? 12 : w - 12 - tp.width - 16, top + 10, tp.width + 16, tp.height + 8);
        c.drawRRect(RRect.fromRectAndRadius(r.shift(const Offset(0, 2)), const Radius.circular(8)),
            Paint()..color = const Color(0x33000000));
        c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(8)),
            Paint()..color = Color.lerp(color, Colors.black, 0.45)!);
        tp.paint(c, r.topLeft + const Offset(8, 4));
      }
    }
  }

  void _grassTuft(Canvas c, Offset o, Color color) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    for (var k = -3; k <= 3; k++) {
      c.drawLine(o + const Offset(0, 8), o + Offset(k * 3.5, -8 - (3 - k.abs()) * 3.0), p);
    }
  }

  void _reeds(Canvas c, Offset o) {
    final stem = Paint()
      ..color = const Color(0xFF5E8C3A)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    for (var k = -2; k <= 2; k++) {
      final top = o + Offset(k * 6.0, -22 + k.abs() * 4.0);
      c.drawLine(o + Offset(k * 3.0, 10), top, stem);
      c.drawOval(Rect.fromCenter(center: top + const Offset(0, 4), width: 5, height: 11),
          Paint()..color = const Color(0xFF7A4E27));
    }
  }

  /// A small flat shape (circle, square, triangle...) of radius about [r].
  void _shapeIcon(Canvas c, Offset o, String id, double r, Paint paint) {
    Path poly(int n, double rot) {
      final p = Path();
      for (var i = 0; i < n; i++) {
        final a = rot + i * 2 * math.pi / n;
        final pt = o + Offset(math.cos(a), math.sin(a)) * r;
        i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
      }
      return p..close();
    }

    switch (id) {
      case 'circle':
        c.drawCircle(o, r, paint);
      case 'square':
        c.drawRect(Rect.fromCenter(center: o, width: r * 1.7, height: r * 1.7), paint);
      case 'rectangle':
        c.drawRect(Rect.fromCenter(center: o, width: r * 2.1, height: r * 1.2), paint);
      case 'oval':
        c.drawOval(Rect.fromCenter(center: o, width: r * 2.1, height: r * 1.3), paint);
      case 'triangle':
        c.drawPath(poly(3, -math.pi / 2), paint);
      case 'diamond':
        c.drawPath(
            Path()
              ..moveTo(o.dx, o.dy - r)
              ..lineTo(o.dx + r * 0.7, o.dy)
              ..lineTo(o.dx, o.dy + r)
              ..lineTo(o.dx - r * 0.7, o.dy)
              ..close(),
            paint);
      case 'pentagon':
        c.drawPath(poly(5, -math.pi / 2), paint);
      case 'hexagon':
        c.drawPath(poly(6, 0), paint);
      case 'star':
        final p = Path();
        for (var i = 0; i < 10; i++) {
          final rr = i.isEven ? r : r * 0.45, a = -math.pi / 2 + i * math.pi / 5;
          final pt = o + Offset(math.cos(a), math.sin(a)) * rr;
          i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
        }
        c.drawPath(p..close(), paint);
      case 'heart':
        c.drawPath(
            Path()
              ..moveTo(o.dx, o.dy + r)
              ..cubicTo(o.dx - r * 1.4, o.dy, o.dx - r * 0.8, o.dy - r * 1.2, o.dx, o.dy - r * 0.4)
              ..cubicTo(o.dx + r * 0.8, o.dy - r * 1.2, o.dx + r * 1.4, o.dy, o.dx, o.dy + r)
              ..close(),
            paint);
    }
  }

  void _toyBall(Canvas c, Offset o, Color color) {
    _shadow(c, o + const Offset(0, 14), 14, 4);
    c.drawCircle(o, 13, Paint()..color = color);
    c.drawArc(Rect.fromCircle(center: o, radius: 13), -0.4, math.pi * 0.8, false,
        _stroke(Colors.white.withOpacity(0.85), 4)..strokeCap = StrokeCap.butt);
    c.drawCircle(o + const Offset(-4, -5), 3, Paint()..color = Colors.white.withOpacity(0.6));
  }

  // ---- school, studio and desert pieces ----
  void _crayon(Canvas c, Offset o, Color color, double angle) {
    c.save();
    c.translate(o.dx, o.dy);
    c.rotate(angle);
    _shadow(c, const Offset(2, 8), 22, 4);
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-20, -5, 34, 10), const Radius.circular(3)),
        Paint()..color = color);
    c.drawRect(const Rect.fromLTWH(-12, -5, 14, 10), Paint()..color = Colors.white.withOpacity(0.35));
    c.drawPath(
        Path()
          ..moveTo(14, -5)
          ..lineTo(24, 0)
          ..lineTo(14, 5)
          ..close(),
        Paint()..color = color);
    c.restore();
  }

  void _pencil(Canvas c, Offset o, double angle) {
    c.save();
    c.translate(o.dx, o.dy);
    c.rotate(angle);
    _shadow(c, const Offset(2, 8), 26, 4);
    c.drawRect(const Rect.fromLTWH(-24, -4, 36, 8), Paint()..color = const Color(0xFFF7C948));
    c.drawRect(const Rect.fromLTWH(-30, -4, 6, 8), Paint()..color = const Color(0xFFF2A0B0));
    c.drawPath(
        Path()
          ..moveTo(12, -4)
          ..lineTo(24, 0)
          ..lineTo(12, 4)
          ..close(),
        Paint()..color = const Color(0xFFF1D6A8));
    c.drawCircle(const Offset(22, 0), 1.6, Paint()..color = const Color(0xFF444444));
    c.restore();
  }

  void _doodleStar(Canvas c, Offset o, Color color) {
    final p = Path();
    for (var i = 0; i < 10; i++) {
      final r = i.isEven ? 11.0 : 5.0, a = -math.pi / 2 + i * math.pi / 5;
      final pt = o + Offset(math.cos(a) * r, math.sin(a) * r);
      i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
    }
    p.close();
    c.drawPath(p, _stroke(color, 2)..strokeJoin = StrokeJoin.round);
  }

  void _splat(Canvas c, Offset o, Color color) {
    final paint = Paint()..color = color.withOpacity(0.75);
    c.drawCircle(o, 11, paint);
    for (var i = 0; i < 7; i++) {
      final a = i * 0.9;
      c.drawCircle(o + Offset(math.cos(a), math.sin(a)) * (13 + (i % 3) * 3.0), 2.5 + (i % 2) * 1.5, paint);
    }
  }

  void _brush(Canvas c, Offset o, Color color, double angle) {
    c.save();
    c.translate(o.dx, o.dy);
    c.rotate(angle);
    _shadow(c, const Offset(2, 8), 24, 4);
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-26, -2.5, 30, 5), const Radius.circular(2)),
        Paint()..color = const Color(0xFF9A6A3A));
    c.drawRect(const Rect.fromLTWH(4, -4, 6, 8), Paint()..color = const Color(0xFFB9BEC4));
    c.drawPath(
        Path()
          ..moveTo(10, -5)
          ..quadraticBezierTo(24, 0, 10, 5)
          ..close(),
        Paint()..color = color);
    c.restore();
  }

  void _dune(Canvas c, Offset o) {
    c.drawPath(
        Path()
          ..moveTo(o.dx - 30, o.dy + 8)
          ..quadraticBezierTo(o.dx - 6, o.dy - 16, o.dx + 30, o.dy + 8)
          ..close(),
        Paint()..color = const Color(0xFFE2AE63));
    c.drawPath(
        Path()
          ..moveTo(o.dx - 6, o.dy - 4)
          ..quadraticBezierTo(o.dx + 10, o.dy - 2, o.dx + 30, o.dy + 8)
          ..lineTo(o.dx - 30, o.dy + 8)
          ..close(),
        Paint()..color = const Color(0x22000000));
  }

  // ---- pieces ----
  void _shadow(Canvas c, Offset o, double rx, double ry) =>
      c.drawOval(Rect.fromCenter(center: o, width: rx * 2, height: ry * 2), Paint()..color = const Color(0x22000000));

  void _roundTree(Canvas c, Offset o, double r) {
    _shadow(c, o + Offset(0, r * 0.9), r * 0.9, r * 0.28);
    c.drawRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: o + Offset(0, r * 0.55), width: r * 0.32, height: r * 0.9),
            const Radius.circular(3)),
        Paint()..color = const Color(0xFF8A5A2E));
    final dark = Paint()..color = const Color(0xFF4E9E55);
    final mid = Paint()..color = const Color(0xFF66B862);
    final light = Paint()..color = const Color(0xFF8ED07A);
    c.drawCircle(o + Offset(-r * 0.45, 0), r * 0.62, dark);
    c.drawCircle(o + Offset(r * 0.45, r * 0.05), r * 0.6, dark);
    c.drawCircle(o + Offset(0, -r * 0.35), r * 0.7, mid);
    c.drawCircle(o + Offset(-r * 0.22, -r * 0.5), r * 0.32, light);
  }

  void _pine(Canvas c, Offset o, double r) {
    _shadow(c, o + Offset(0, r * 0.95), r * 0.7, r * 0.22);
    c.drawRect(Rect.fromCenter(center: o + Offset(0, r * 0.75), width: r * 0.25, height: r * 0.5),
        Paint()..color = const Color(0xFF7A4E27));
    for (var i = 0; i < 3; i++) {
      final top = o.dy - r * 1.1 + i * r * 0.5;
      final half = r * (0.5 + i * 0.22);
      final tri = Path()
        ..moveTo(o.dx, top)
        ..lineTo(o.dx + half, top + r * 0.75)
        ..lineTo(o.dx - half, top + r * 0.75)
        ..close();
      c.drawPath(tri, Paint()..color = i.isEven ? const Color(0xFF3D8B57) : const Color(0xFF4FA066));
    }
  }

  void _fence(Canvas c, Offset center, double r) {
    final rail = Paint()
      ..color = _wood
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;
    final rect = Rect.fromCircle(center: center + const Offset(0, 6), radius: r);
    c.drawArc(rect, math.pi * 0.08, math.pi * 0.84, false, rail);
    c.drawArc(rect.inflate(-5), math.pi * 0.08, math.pi * 0.84, false, rail..strokeWidth = 1.8);
    final post = Paint()..color = _woodDark;
    for (var a = math.pi * 0.08; a <= math.pi * 0.93; a += math.pi * 0.12) {
      final p = rect.center + Offset(math.cos(a), math.sin(a)) * (r - 2);
      c.drawRRect(
          RRect.fromRectAndRadius(Rect.fromCenter(center: p, width: 4.5, height: 13), const Radius.circular(2)), post);
    }
  }

  void _hay(Canvas c, Offset o) {
    _shadow(c, o + const Offset(0, 12), 22, 6);
    final body = RRect.fromRectAndRadius(Rect.fromCenter(center: o, width: 42, height: 26), const Radius.circular(7));
    c.drawRRect(body, Paint()..color = const Color(0xFFE9C46A));
    final line = Paint()
      ..color = const Color(0xFFC9A04A)
      ..strokeWidth = 1.5;
    for (final y in [-5.0, 0.0, 5.0]) {
      c.drawLine(o + Offset(-17, y), o + Offset(17, y), line);
    }
    c.drawLine(o + const Offset(-9, -13), o + const Offset(-9, 13), line..color = const Color(0xFFB5452F));
    c.drawLine(o + const Offset(9, -13), o + const Offset(9, 13), line);
  }

  void _rocks(Canvas c, Offset o) {
    _shadow(c, o + const Offset(4, 14), 30, 6);
    c.drawOval(Rect.fromCenter(center: o, width: 46, height: 30), Paint()..color = const Color(0xFFA9A397));
    c.drawOval(Rect.fromCenter(center: o + const Offset(20, 6), width: 28, height: 20),
        Paint()..color = const Color(0xFFBDB8AD));
    c.drawOval(Rect.fromCenter(center: o + const Offset(-4, 5), width: 16, height: 10),
        Paint()..color = const Color(0xFF5E584E)); // den
    c.drawOval(Rect.fromCenter(center: o + const Offset(-8, -6), width: 14, height: 6),
        Paint()..color = const Color(0x55FFFFFF));
  }

  void _pond(Canvas c, Offset o) {
    c.drawOval(Rect.fromCenter(center: o, width: 112, height: 56), Paint()..color = const Color(0xFF9BCFA0));
    c.drawOval(Rect.fromCenter(center: o, width: 102, height: 48), Paint()..color = const Color(0xFF7CC4E4));
    c.drawOval(Rect.fromCenter(center: o + const Offset(-14, -8), width: 40, height: 10),
        Paint()..color = const Color(0x66FFFFFF));
    final pad = Paint()..color = const Color(0xFF4FA066);
    c.drawCircle(o + const Offset(24, 8), 7, pad);
    c.drawCircle(o + const Offset(-30, 10), 5.5, pad);
    c.drawCircle(o + const Offset(25, 7), 2, Paint()..color = const Color(0xFFF7A1C4));
  }

  void _nest(Canvas c, Offset o) {
    _shadow(c, o + const Offset(0, 40), 10, 4);
    c.drawRect(Rect.fromCenter(center: o + const Offset(0, 14), width: 6, height: 52),
        Paint()..color = const Color(0xFF7A4E27));
    c.drawOval(Rect.fromCenter(center: o + const Offset(0, -12), width: 38, height: 16),
        Paint()..color = const Color(0xFF8B6B3D));
    final twig = Paint()
      ..color = const Color(0xFF5E4423)
      ..strokeWidth = 1.4;
    for (var i = -3; i <= 3; i++) {
      c.drawLine(o + Offset(i * 5.0 - 3, -17), o + Offset(i * 5.0 + 4, -7), twig);
    }
    c.drawOval(Rect.fromCenter(center: o + const Offset(-5, -18), width: 8, height: 6), Paint()..color = Colors.white);
    c.drawOval(Rect.fromCenter(center: o + const Offset(5, -18), width: 8, height: 6), Paint()..color = Colors.white);
  }

  void _trough(Canvas c, Offset o) {
    _shadow(c, o + const Offset(0, 14), 30, 6);
    final wood = RRect.fromRectAndRadius(Rect.fromCenter(center: o, width: 58, height: 24), const Radius.circular(5));
    c.drawRRect(wood, Paint()..color = const Color(0xFF8A5A2E));
    c.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: o + const Offset(0, -3), width: 50, height: 12), const Radius.circular(4)),
        Paint()..color = const Color(0xFF7CC4E4));
    c.drawOval(Rect.fromCenter(center: o + const Offset(-10, -5), width: 16, height: 4),
        Paint()..color = const Color(0x66FFFFFF));
  }

  void _acacia(Canvas c, Offset o) {
    _shadow(c, o + const Offset(0, 34), 30, 7);
    final trunk = Paint()
      ..color = const Color(0xFF7A4E27)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    c.drawLine(o + const Offset(0, 34), o + const Offset(0, 0), trunk);
    c.drawLine(o, o + const Offset(-14, -10), trunk..strokeWidth = 4);
    c.drawLine(o, o + const Offset(14, -10), trunk);
    c.drawOval(Rect.fromCenter(center: o + const Offset(0, -16), width: 78, height: 20),
        Paint()..color = const Color(0xFF6F9E3E));
    c.drawOval(Rect.fromCenter(center: o + const Offset(-6, -20), width: 46, height: 10),
        Paint()..color = const Color(0xFF8DBA55));
  }

  void _palm(Canvas c, Offset o) {
    // a little sand dune and a date palm
    c.drawOval(Rect.fromCenter(center: o + const Offset(0, 40), width: 90, height: 22),
        Paint()..color = const Color(0xFFEBD3A0));
    final trunk = Path()
      ..moveTo(o.dx - 4, o.dy + 40)
      ..quadraticBezierTo(o.dx - 2, o.dy + 10, o.dx + 4, o.dy - 18)
      ..lineTo(o.dx + 9, o.dy - 17)
      ..quadraticBezierTo(o.dx + 4, o.dy + 10, o.dx + 5, o.dy + 40)
      ..close();
    c.drawPath(trunk, Paint()..color = const Color(0xFF9A6A3A));
    final leaf = Paint()..color = const Color(0xFF4FA066);
    for (final a in [-2.6, -2.0, -1.2, -0.6, 0.0]) {
      final tip = o + const Offset(6, -18) + Offset(math.cos(a), math.sin(a) * 0.6) * 32;
      final path = Path()
        ..moveTo(o.dx + 6, o.dy - 18)
        ..quadraticBezierTo((o.dx + 6 + tip.dx) / 2, o.dy - 34, tip.dx, tip.dy)
        ..quadraticBezierTo((o.dx + 6 + tip.dx) / 2, o.dy - 22, o.dx + 6, o.dy - 18);
      c.drawPath(path, leaf);
    }
    for (final d in [const Offset(2, -14), const Offset(9, -13), const Offset(5, -10)]) {
      c.drawCircle(o + d, 3, Paint()..color = const Color(0xFF7A3E1D)); // dates
    }
  }

  void _kennel(Canvas c, Offset o) {
    _shadow(c, o + const Offset(0, 18), 28, 6);
    c.drawRect(Rect.fromCenter(center: o + const Offset(0, 4), width: 46, height: 28),
        Paint()..color = const Color(0xFFC98A12));
    final roof = Path()
      ..moveTo(o.dx - 30, o.dy - 8)
      ..lineTo(o.dx, o.dy - 30)
      ..lineTo(o.dx + 30, o.dy - 8)
      ..close();
    c.drawPath(roof, Paint()..color = const Color(0xFFB5452F));
    c.drawRRect(
        RRect.fromRectAndCorners(Rect.fromCenter(center: o + const Offset(0, 10), width: 18, height: 18),
            topLeft: const Radius.circular(9), topRight: const Radius.circular(9)),
        Paint()..color = const Color(0xFF4A3420));
    c.drawCircle(o + const Offset(20, 16), 4, Paint()..color = const Color(0xFFF2F2F2)); // bowl
  }

  void _gate(Canvas c, Offset o) {
    final (postColor, capColor, signColor, edgeColor, textColor) = switch (style) {
      'town' => (const Color(0xFF9AA3AD), const Color(0xFF6B7480), const Color(0xFF2F6FD0), Colors.white, Colors.white),
      'school' => (
          const Color(0xFFB07A44),
          const Color(0xFF8B5A2B),
          const Color(0xFF2E5E4E),
          const Color(0xFFB07A44),
          Colors.white
        ),
      'playroom' => (
          const Color(0xFFE53935),
          const Color(0xFFB71C1C),
          const Color(0xFF7E57C2),
          const Color(0xFFFDD835),
          Colors.white
        ),
      'studio' => (
          const Color(0xFFEDE3D5),
          const Color(0xFFD9CBB8),
          const Color(0xFF6A4FB5),
          const Color(0xFFFDD835),
          Colors.white
        ),
      'desert' => (
          const Color(0xFFE2C08A),
          const Color(0xFFC79A5A),
          const Color(0xFF006233),
          Colors.white,
          Colors.white
        ),
      _ => (_wood, _woodDark, const Color(0xFF8B5A2B), const Color(0xFFB07A44), const Color(0xFFFFF4DC)),
    };
    final post = Paint()..color = postColor;
    final cap = Paint()..color = capColor;
    for (final dx in [-78.0, 78.0]) {
      final p = o + Offset(dx, 6);
      _shadow(c, p + const Offset(0, 36), 14, 4);
      c.drawRRect(
          RRect.fromRectAndRadius(Rect.fromCenter(center: p, width: 18, height: 72), const Radius.circular(4)), post);
      c.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(center: p + const Offset(0, -38), width: 24, height: 9), const Radius.circular(3)),
          cap);
      final side = p + Offset(dx > 0 ? 34 : -34, 20);
      switch (style) {
        case 'desert':
          _palm(c, side + const Offset(0, -18));
        case 'studio':
          _paintPot(c, side + const Offset(0, 10), dx > 0 ? const Color(0xFF1E88E5) : const Color(0xFFE53935));
        case 'school' || 'playroom':
          _block(c, side + const Offset(0, 10), labels.length > 1 ? labels[dx > 0 ? 1 : 0] : (dx > 0 ? 'B' : 'A'),
              dx > 0 ? const Color(0xFF1E88E5) : const Color(0xFFE53935));
        default:
          _roundTree(c, side, 20);
      }
    }
    // the arch sign
    final sign = RRect.fromRectAndRadius(
        Rect.fromCenter(center: o + const Offset(0, -20), width: 190, height: 40), const Radius.circular(12));
    c.drawRRect(sign.shift(const Offset(0, 3)), Paint()..color = const Color(0x33000000));
    c.drawRRect(sign, Paint()..color = signColor);
    if (style == 'desert') {
      // a red crescent-and-star touch, as on the flag
      c.drawRRect(
          RRect.fromRectAndCorners(Rect.fromLTWH(sign.left, sign.top, 14, sign.height),
              topLeft: const Radius.circular(12), bottomLeft: const Radius.circular(12)),
          Paint()..color = const Color(0xFFD21034));
    }
    c.drawRRect(
        sign.deflate(4),
        Paint()
          ..color = edgeColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
    // Shrinks to fit ("حديقة الحيوانات" is longer than "ZOO"); no letter
    // spacing for Arabic, it would break the joined letters.
    final latin = RegExp(r'^[\x00-\x7F]*$').hasMatch(gateText);
    TextPainter label(double size) => TextPainter(
          text: TextSpan(
            text: gateText,
            style: TextStyle(
                color: textColor,
                fontSize: size,
                fontWeight: FontWeight.w800,
                letterSpacing: latin ? 2 : 0,
                fontFamily: latin ? 'Poppins' : 'Tajawal',
                fontFamilyFallback: const ['Tajawal', 'Poppins']),
          ),
          textDirection: TextDirection.ltr,
          maxLines: 1,
        )..layout();
    var tp = label(22);
    if (tp.width > 170) tp = label(22 * 170 / tp.width);
    tp.paint(c, o + Offset(-tp.width / 2, -20 - tp.height / 2));
    // leaves on the sign
    for (final dx in [-92.0, 92.0]) {
      c.drawCircle(o + Offset(dx, -30), 10, Paint()..color = const Color(0xFF66B862));
      c.drawCircle(o + Offset(dx * 0.93, -38), 7, Paint()..color = const Color(0xFF8ED07A));
    }
  }

  // ---- park pieces ----
  void _block(Canvas c, Offset o, String letter, Color color) {
    _shadow(c, o + const Offset(4, 22), 26, 6);
    final side = Path()
      ..moveTo(o.dx + 20, o.dy - 20)
      ..lineTo(o.dx + 30, o.dy - 28)
      ..lineTo(o.dx + 30, o.dy + 12)
      ..lineTo(o.dx + 20, o.dy + 20)
      ..close();
    c.drawPath(side, Paint()..color = Color.lerp(color, Colors.black, 0.35)!);
    final top = Path()
      ..moveTo(o.dx - 20, o.dy - 20)
      ..lineTo(o.dx - 10, o.dy - 28)
      ..lineTo(o.dx + 30, o.dy - 28)
      ..lineTo(o.dx + 20, o.dy - 20)
      ..close();
    c.drawPath(top, Paint()..color = Color.lerp(color, Colors.white, 0.35)!);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: o, width: 40, height: 40), const Radius.circular(4)),
        Paint()..color = color);
    if (letter.isEmpty) return;
    if (letter.startsWith('shape:')) {
      _shapeIcon(c, o, letter.substring(6), 13, Paint()..color = Colors.white);
      return;
    }
    final latin = RegExp(r'^[\x00-\x7F]*$').hasMatch(letter);
    final tp = TextPainter(
      text: TextSpan(
          text: latin ? letter.substring(0, 1) : letter,
          style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              fontFamily: latin ? 'Poppins' : 'Tajawal',
              height: 1.1)),
      textDirection: latin ? TextDirection.ltr : TextDirection.rtl,
    )..layout();
    tp.paint(c, o - Offset(tp.width / 2, tp.height / 2 - (latin ? 0 : 3)));
  }

  void _paintPot(Canvas c, Offset o, Color color) {
    _shadow(c, o + const Offset(0, 20), 26, 6);
    // a splash on the grass, then the pot
    final splash = Paint()..color = color.withOpacity(0.55);
    for (final d in [const Offset(-26, 14), const Offset(24, 18), const Offset(-8, 22), const Offset(30, 2)]) {
      c.drawCircle(o + d, 7, splash);
    }
    c.drawOval(Rect.fromCenter(center: o + const Offset(4, 18), width: 58, height: 16), splash);
    final body = RRect.fromRectAndRadius(
        Rect.fromCenter(center: o + const Offset(0, 2), width: 36, height: 34), const Radius.circular(6));
    c.drawRRect(body, Paint()..color = const Color(0xFFB9BEC4));
    c.drawOval(Rect.fromCenter(center: o + const Offset(0, -15), width: 36, height: 12),
        Paint()..color = const Color(0xFF8E959C));
    c.drawOval(Rect.fromCenter(center: o + const Offset(0, -15), width: 30, height: 9), Paint()..color = color);
    c.drawRect(Rect.fromCenter(center: o + const Offset(0, 4), width: 36, height: 10), Paint()..color = color);
  }

  // ---- town pieces ----
  void _parking(Canvas c, Offset center) {
    // a round paved stop with a kerb, like a little roundabout
    final r = Rect.fromCircle(center: center + const Offset(0, 6), radius: 56);
    c.drawArc(
        r,
        math.pi * 0.08,
        math.pi * 0.84,
        false,
        Paint()
          ..color = const Color(0xFFB9BEC4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5);
    final stripe = Paint()
      ..color = const Color(0xFFE04F3F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    for (var a = math.pi * 0.08; a < math.pi * 0.9; a += math.pi * 0.16) {
      c.drawArc(r, a, math.pi * 0.06, false, stripe);
    }
  }

  void _house(Canvas c, Offset o,
      {required double w,
      required double h,
      required Color wall,
      required Color roof,
      bool flat = false,
      int windows = 2,
      Color? door}) {
    _shadow(c, o + Offset(0, h / 2 + 4), w * 0.55, 6);
    final body = Rect.fromCenter(center: o, width: w, height: h);
    c.drawRRect(RRect.fromRectAndRadius(body, const Radius.circular(3)), Paint()..color = wall);
    if (flat) {
      c.drawRect(Rect.fromLTWH(body.left - 3, body.top - 6, w + 6, 7), Paint()..color = roof);
    } else {
      final p = Path()
        ..moveTo(body.left - 6, body.top + 1)
        ..lineTo(o.dx, body.top - h * 0.5)
        ..lineTo(body.right + 6, body.top + 1)
        ..close();
      c.drawPath(p, Paint()..color = roof);
    }
    final glass = Paint()..color = const Color(0xFFBFE3F5);
    for (var i = 0; i < windows; i++) {
      final x = body.left + w * (i + 0.5) / windows;
      c.drawRect(Rect.fromCenter(center: Offset(x, body.top + h * 0.3), width: 9, height: 8), glass);
    }
    if (door != null) {
      c.drawRect(Rect.fromLTWH(o.dx - 6, body.bottom - 14, 12, 14), Paint()..color = door);
    }
  }

  void _text(Canvas c, String t, Offset o, double size, Color color) {
    final tp = TextPainter(
      text: TextSpan(text: t, style: TextStyle(color: color, fontSize: size, fontWeight: FontWeight.w900)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, o - Offset(tp.width / 2, tp.height / 2));
  }

  void _townBuilding(Canvas c, String id, Offset o) {
    switch (id) {
      case 'firetruck': // fire station: red, two big doors
        _house(c, o,
            w: 66, h: 38, wall: const Color(0xFFD9473A), roof: const Color(0xFF8E2A22), flat: true, windows: 0);
        for (final dx in [-15.0, 15.0]) {
          c.drawRect(Rect.fromCenter(center: o + Offset(dx, 6), width: 24, height: 24),
              Paint()..color = const Color(0xFFF2D3CF));
          for (var y = -3.0; y < 18; y += 5) {
            c.drawLine(o + Offset(dx - 12, y), o + Offset(dx + 12, y), Paint()..color = const Color(0xFFC9A9A4));
          }
        }
        c.drawCircle(o + const Offset(0, -15), 5, Paint()..color = const Color(0xFFFFD166));
      case 'police': // police station: blue, flat, a light on top
        _house(c, o,
            w: 62,
            h: 36,
            wall: const Color(0xFF3E6FB8),
            roof: const Color(0xFF223F6B),
            flat: true,
            windows: 3,
            door: const Color(0xFF223F6B));
        c.drawRect(Rect.fromCenter(center: o + const Offset(0, -26), width: 10, height: 7),
            Paint()..color = const Color(0xFF5BB4FF));
      case 'ambulance': // hospital: white, red cross / H
        _house(c, o,
            w: 60,
            h: 46,
            wall: const Color(0xFFF6F6F6),
            roof: const Color(0xFFB9BEC4),
            flat: true,
            windows: 3,
            door: const Color(0xFF9BC3E0));
        c.drawCircle(o + const Offset(0, -2), 9, Paint()..color = const Color(0xFFE04F3F));
        _text(c, 'H', o + const Offset(0, -2), 12, Colors.white);
      case 'bus': // school: yellow with a clock and a flag
        _house(c, o,
            w: 64,
            h: 36,
            wall: const Color(0xFFF2C14E),
            roof: const Color(0xFFB5452F),
            windows: 3,
            door: const Color(0xFF8A5A2E));
        c.drawCircle(o + const Offset(0, -26), 6, Paint()..color = Colors.white);
        c.drawLine(o + const Offset(0, -26), o + const Offset(0, -30), Paint()..color = const Color(0xFF333333));
        c.drawLine(o + const Offset(0, -26), o + const Offset(3, -26), Paint()..color = const Color(0xFF333333));
      case 'tractor': // farm: red barn and a little field
        for (var i = 0; i < 4; i++) {
          c.drawRect(Rect.fromLTWH(o.dx - 52, o.dy + 22 + i * 5.0, 104, 3), Paint()..color = const Color(0xFFB98A4E));
        }
        _house(c, o, w: 48, h: 36, wall: const Color(0xFFB5452F), roof: const Color(0xFF6E2A1F), windows: 0);
        final x = Paint()
          ..color = Colors.white
          ..strokeWidth = 2;
        c.drawRect(Rect.fromCenter(center: o + const Offset(0, 6), width: 18, height: 22),
            Paint()..color = const Color(0xFF6E2A1F));
        c.drawLine(o + const Offset(-9, -5), o + const Offset(9, 17), x);
        c.drawLine(o + const Offset(9, -5), o + const Offset(-9, 17), x);
      case 'taxi': // taxi stand: a sign and a shelter
        _house(c, o,
            w: 54, h: 26, wall: const Color(0xFFF7F1E1), roof: const Color(0xFF333333), flat: true, windows: 2);
        c.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromCenter(center: o + const Offset(0, -24), width: 40, height: 14), const Radius.circular(3)),
            Paint()..color = const Color(0xFFFFC928));
        _text(c, 'TAXI', o + const Offset(0, -24), 9, const Color(0xFF222222));
      case 'truck': // warehouse with boxes
        _house(c, o, w: 70, h: 36, wall: const Color(0xFF9AA3AD), roof: const Color(0xFF5E6670), windows: 0);
        c.drawRect(Rect.fromCenter(center: o + const Offset(-8, 6), width: 30, height: 24),
            Paint()..color = const Color(0xFF6B7480));
        for (final d in [const Offset(26, 14), const Offset(38, 14), const Offset(32, 4)]) {
          c.drawRect(Rect.fromCenter(center: o + d, width: 11, height: 10), Paint()..color = const Color(0xFFC98A4E));
        }
      case 'motorcycle': // petrol station: canopy and a pump
        c.drawRect(Rect.fromCenter(center: o + const Offset(0, -16), width: 70, height: 9),
            Paint()..color = const Color(0xFF2E9E6A));
        for (final dx in [-30.0, 30.0]) {
          c.drawRect(Rect.fromCenter(center: o + Offset(dx, 4), width: 4, height: 32),
              Paint()..color = const Color(0xFFB9BEC4));
        }
        _shadow(c, o + const Offset(0, 22), 30, 5);
        c.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromCenter(center: o + const Offset(0, 8), width: 16, height: 24), const Radius.circular(3)),
            Paint()..color = const Color(0xFFE04F3F));
        c.drawRect(
            Rect.fromCenter(center: o + const Offset(0, 2), width: 10, height: 6), Paint()..color = Colors.white);
      default: // car: a house with a garage
        _house(c, o + const Offset(-10, 0),
            w: 42,
            h: 34,
            wall: const Color(0xFFF4E3C3),
            roof: const Color(0xFFB5452F),
            windows: 2,
            door: const Color(0xFF8A5A2E));
        c.drawRect(Rect.fromCenter(center: o + const Offset(24, 6), width: 26, height: 22),
            Paint()..color = const Color(0xFFE9D3AB));
        c.drawRect(Rect.fromCenter(center: o + const Offset(24, 9), width: 20, height: 16),
            Paint()..color = const Color(0xFFB9BEC4));
    }
  }

  @override
  bool shouldRepaint(covariant _ZooPainter old) =>
      old.gateText != gateText ||
      old.style != style ||
      old.ids.join() != ids.join() ||
      old.habitatNames.join() != habitatNames.join();
}

/// Keeps 40% of the colour (the rest goes grey), for items not met yet.
const _soft = <double>[
  0.6 * 0.33 + 0.4, 0.6 * 0.59, 0.6 * 0.11, 0, 0, //
  0.6 * 0.33, 0.6 * 0.59 + 0.4, 0.6 * 0.11, 0, 0, //
  0.6 * 0.33, 0.6 * 0.59, 0.6 * 0.11 + 0.4, 0, 0, //
  0, 0, 0, 1, 0,
];

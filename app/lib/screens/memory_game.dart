import 'dart:math';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../animals.dart';
import '../l10n.dart';
import '../progress.dart';
import '../speech.dart';
import 'home_screen.dart' show brand, ink;

/// Memory: 6 pairs, each an animal photo and its name (in a language the
/// child picks). Turn two cards; a match stays open and the name is said
/// aloud. Finishing the board gives a star. No camera needed.
class MemoryGame extends StatefulWidget {
  const MemoryGame({super.key, required this.progress});
  final Progress progress;

  @override
  State<MemoryGame> createState() => _MemoryGameState();
}

class _Card {
  _Card(this.animal, this.isPhoto);
  final Animal animal;
  final bool isPhoto;
  bool open = false;
  bool matched = false;
}

class _MemoryGameState extends State<MemoryGame> {
  late Lang _wordLang = widget.progress.lang;
  List<_Card> _cards = [];
  final List<_Card> _up = [];
  int _moves = 0;
  bool _won = false;

  @override
  void initState() {
    super.initState();
    _deal();
  }

  void _deal() {
    final pick = [...widget.progress.animals]..shuffle(Random());
    final six = pick.take(6);
    _cards = [
      for (final a in six) ...[_Card(a, true), _Card(a, false)]
    ]..shuffle(Random());
    _up.clear();
    _moves = 0;
    _won = false;
  }

  void _tap(_Card c) {
    if (c.open || c.matched || _up.length == 2) return;
    setState(() {
      c.open = true;
      _up.add(c);
    });
    if (_up.length < 2) return;
    _moves++;
    final [a, b] = _up;
    if (a.animal.id == b.animal.id && a.isPhoto != b.isPhoto) {
      Speech.instance.say(a.animal.name(_wordLang), _wordLang);
      setState(() {
        a.matched = b.matched = true;
        _up.clear();
      });
      if (_cards.every((c) => c.matched)) {
        widget.progress.markMemoryWin();
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) setState(() => _won = true);
        });
      }
    } else {
      Future.delayed(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        setState(() {
          a.open = b.open = false;
          _up.clear();
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.progress.s;
    return Scaffold(
      appBar: AppBar(title: Text(s.memoryGame), backgroundColor: const Color(0xFFFFFAF0)),
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(children: [
              Expanded(
                  child: Text(s.memoryHint(kind: widget.progress.book.kind),
                      style: const TextStyle(color: Color(0xFF7A6A5C)))),
              Text('${s.namesIn} '),
              SegmentedButton<Lang>(
                showSelectedIcon: false,
                segments: [for (final l in Lang.values) ButtonSegment(value: l, label: Text(l.short))],
                selected: {_wordLang},
                onSelectionChanged: (v) => setState(() => _wordLang = v.first),
              ),
            ]),
          ),
          Expanded(
            child: _won
                ? Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.emoji_events_rounded, size: 90, color: Color(0xFFF2A60C)),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(s.movesWin(_moves),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: ink)),
                      ),
                      const Text('+1 ★',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFFF2A60C))),
                      const SizedBox(height: 16),
                      FilledButton(
                        key: const Key('memory-again'),
                        onPressed: () => setState(_deal),
                        style: FilledButton.styleFrom(backgroundColor: brand),
                        child: Text(s.playAgainBtn),
                      ),
                    ]),
                  )
                : GridView.count(
                    padding: const EdgeInsets.all(12),
                    crossAxisCount: 3,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.82,
                    children: [for (var i = 0; i < _cards.length; i++) _cardView(_cards[i], i)],
                  ),
          ),
        ]),
      ),
    );
  }

  Widget _cardView(_Card c, int i) {
    final showing = c.open || c.matched;
    return GestureDetector(
      key: Key('card-$i'),
      onTap: () => _tap(c),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 420),
        // a card flip: the old face turns away, the new one turns in
        transitionBuilder: (child, anim) {
          final rotate = Tween(begin: math.pi, end: 0.0).animate(anim);
          return AnimatedBuilder(
            animation: rotate,
            child: child,
            builder: (context, child) {
              final isOut = child!.key != ValueKey(showing);
              final angle = isOut ? math.min(rotate.value, math.pi / 2) : rotate.value;
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0015)
                  ..rotateY(angle),
                child: angle > math.pi / 2 ? const SizedBox.shrink() : child,
              );
            },
          );
        },
        layoutBuilder: (current, previous) => Stack(children: [...previous, if (current != null) current]),
        child: Container(
          key: ValueKey(showing),
          decoration: BoxDecoration(
            color: showing ? Colors.white : widget.progress.book.color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: c.matched ? const Color(0xFF2E9E6A) : (showing ? c.animal.color : Colors.white), width: 3),
            boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 6, offset: Offset(0, 3))],
          ),
          clipBehavior: Clip.antiAlias,
          child: !showing
              ? Center(
                  child: Icon(
                      switch (widget.progress.book.kind) {
                        'vehicles' => Icons.directions_car_rounded,
                        'letters' => Icons.abc_rounded,
                        'colors' => Icons.palette_rounded,
                        'heritage' => Icons.mosque_rounded,
                        'shapes' => Icons.category_rounded,
                        'numbers' => Icons.pin_rounded,
                        _ => Icons.pets_rounded,
                      },
                      color: Colors.white,
                      size: 40))
              : c.isPhoto
                  ? Image.asset(c.animal.thumbAsset, fit: BoxFit.cover)
                  : Center(
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Text(c.animal.name(_wordLang),
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: c.animal.color)),
                      ),
                    ),
        ),
      ),
    );
  }
}

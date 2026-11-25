import 'dart:math';

import 'package:flutter/material.dart';

import '../animals.dart';
import '../l10n.dart';
import '../progress.dart';
import '../speech.dart';
import '../ui.dart';

/// Sort the animals (no camera): an animal appears, the child picks where it
/// lives (farm, pet, wild) or what it eats (plants, meat, everything).
/// Ten questions, a mix of both kinds; finishing gives a star.
class SortGame extends StatefulWidget {
  const SortGame({super.key, required this.progress});
  final Progress progress;

  @override
  State<SortGame> createState() => _SortGameState();
}

class _Question {
  const _Question(this.animal, this.byDiet);
  final Animal animal;
  final bool byDiet; // what it eats (else: farm / pet / wild)
  String get answer => byDiet ? animal.diet! : animal.group!;
  List<String> get choices => byDiet ? const ['herbivore', 'carnivore', 'omnivore'] : const ['farm', 'pet', 'wild'];
}

class _SortGameState extends State<SortGame> {
  static const rounds = 10;
  final _rnd = Random();
  late List<_Question> _qs;
  int _i = 0;
  int _right = 0;
  String? _picked; // the last choice, while it shows right / wrong
  bool _missed = false; // a wrong try on this question

  @override
  void initState() {
    super.initState();
    _deal();
  }

  void _deal() {
    final animals = widget.progress.animals.where((a) => a.group != null && a.diet != null).toList()..shuffle(_rnd);
    _qs = [for (var k = 0; k < rounds; k++) _Question(animals[k % animals.length], k.isOdd)];
    _i = 0;
    _right = 0;
    _picked = null;
    _missed = false;
  }

  void _choose(String c) {
    if (_picked != null && _picked == _qs[_i].answer) return; // waiting for the next one
    final q = _qs[_i];
    final s = widget.progress.s;
    final lang = widget.progress.lang;
    setState(() => _picked = c);
    if (c == q.answer) {
      if (!_missed) _right++;
      Speech.instance.say(s.sortRight(q.animal.name(lang), s.category(c)), lang);
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (!mounted) return;
        setState(() {
          _i++;
          _picked = null;
          _missed = false;
        });
        if (_i == rounds) widget.progress.markMemoryWin(); // a game won: a star
      });
    } else {
      _missed = true;
      Speech.instance.say(s.sortWrong, lang);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.progress.s;
    final lang = widget.progress.lang;
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: Text(s.sortGame), backgroundColor: AppColors.cream, surfaceTintColor: Colors.transparent),
      body: SafeArea(
        child: _i >= rounds
            ? Center(
                child: FadeSlideIn(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.emoji_events_rounded, size: 96, color: AppColors.gold),
                    const SizedBox(height: 12),
                    Text(s.sortDone(_right, rounds),
                        key: const Key('sort-done'),
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.ink)),
                    const SizedBox(height: 6),
                    const Text('+1 ★',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.gold)),
                    const SizedBox(height: 18),
                    FilledButton(
                      onPressed: () => setState(_deal),
                      style: FilledButton.styleFrom(backgroundColor: AppColors.brand),
                      child: Text(s.playAgainBtn),
                    ),
                  ]),
                ),
              )
            : _question(context, _qs[_i], s, lang),
      ),
    );
  }

  Widget _question(BuildContext context, _Question q, S s, Lang lang) {
    final a = q.animal;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(children: [
        ProgressBar(value: _i / rounds, color: a.color),
        const SizedBox(height: 18),
        Text(q.byDiet ? s.sortEats : s.sortWhere,
            key: const Key('sort-question'),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink)),
        Expanded(
          child: Center(
            child: FadeSlideIn(
              key: ValueKey(_i),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Floating(
                  amount: 8,
                  child: Image.asset(a.stickerAsset,
                      width: 200,
                      height: 200,
                      errorBuilder: (_, __, ___) =>
                          ClipOval(child: Image.asset(a.thumbAsset, width: 180, height: 180, fit: BoxFit.cover))),
                ),
                const SizedBox(height: 8),
                Text(a.name(lang), style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: a.color)),
              ]),
            ),
          ),
        ),
        for (final c in q.choices) ...[
          Pressable(
            key: Key('sort-$c'),
            onTap: () => _choose(c),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: _picked == c ? (c == q.answer ? AppColors.green : const Color(0xFFD9483B)) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.line),
                boxShadow: const [BoxShadow(color: Color(0x0F2B2118), blurRadius: 10, offset: Offset(0, 3))],
              ),
              child: Row(children: [
                Icon(_icon(c), color: _picked == c ? Colors.white : a.color, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(s.category(c),
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: _picked == c ? Colors.white : AppColors.ink)),
                ),
                if (_picked == c)
                  Icon(c == q.answer ? Icons.check_circle_rounded : Icons.cancel_rounded, color: Colors.white),
              ]),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ]),
    );
  }

  IconData _icon(String c) => switch (c) {
        'farm' => Icons.agriculture_rounded,
        'pet' => Icons.home_rounded,
        'wild' => Icons.forest_rounded,
        'herbivore' => Icons.eco_rounded,
        'carnivore' => Icons.set_meal_rounded,
        _ => Icons.restaurant_rounded,
      };
}

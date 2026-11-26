import 'package:flutter/material.dart';

import '../animals.dart';
import '../progress.dart';
import '../speech.dart';
import 'page_screen.dart';

/// Opens from the zoo path: the animal's photo, names, fact, the body parts
/// found so far (the others stay a mystery), its quiz score, and buttons.
class AnimalSheet extends StatelessWidget {
  const AnimalSheet({super.key, required this.animal, required this.progress, required this.onScan});
  final Animal animal;
  final Progress progress;
  final void Function({bool quiz}) onScan;

  @override
  Widget build(BuildContext context) {
    final a = animal;
    final p = progress;
    final s = p.s;
    final lang = p.lang;
    final others = [a.en, a.fr, a.ar].where((n) => n != a.name(lang)).join(' · ');
    final found = p.partsFound(a);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              height: 150,
              child: Stack(fit: StackFit.expand, children: [
                Image.asset(a.pageAsset, fit: BoxFit.cover, alignment: const Alignment(0, -0.62)),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x00000000), Color(0x99000000)],
                    ),
                  ),
                ),
                PositionedDirectional(
                  start: 14,
                  bottom: 10,
                  end: 14,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Flexible(
                        child: Text(a.name(lang),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800, height: 1.1)),
                      ),
                      IconButton(
                        key: const Key('speak-name'),
                        tooltip: a.name(lang),
                        onPressed: () => Speech.instance.say(a.name(lang), lang),
                        icon: const Icon(Icons.volume_up_rounded, color: Colors.white),
                      ),
                    ]),
                    Text('$others · ${s.page(a.page)}', style: const TextStyle(color: Colors.white, fontSize: 13)),
                  ]),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          Text(p.met(a.id) ? a.fact(lang) : s.notMet,
              style: const TextStyle(fontSize: 15, height: 1.35, color: Color(0xFF3D4266))),
          // categories: where it lives, farm / pet / wild, what it eats
          if (a.habitat != null) ...[
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [
              _Tag(icon: _habitatIcon(a.habitat!), text: '${s.livesIn}: ${s.habitatName(a.habitat!)}', color: a.color),
              if (a.group != null)
                _Tag(
                    icon: switch (a.group) {
                      'farm' => Icons.agriculture_rounded,
                      'pet' => Icons.home_rounded,
                      _ => Icons.forest_rounded,
                    },
                    text: s.category(a.group!),
                    color: a.color),
              if (a.diet != null)
                _Tag(
                    icon: switch (a.diet) {
                      'herbivore' => Icons.eco_rounded,
                      'carnivore' => Icons.set_meal_rounded,
                      _ => Icons.restaurant_rounded,
                    },
                    text: s.category(a.diet!),
                    color: a.color),
            ]),
          ],
          if (a.parts.isNotEmpty && p.book.levels > 1 && !p.unlocked(2)) ...[
            // level 1 is only about meeting it: the parts wait for level 2
            const SizedBox(height: 14),
            Row(children: [
              const Icon(Icons.lock_rounded, size: 18, color: Color(0xFFA3A8C3)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(s.partsLocked(p.book.kind),
                    key: const Key('parts-locked'),
                    style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF666C8F))),
              ),
            ]),
          ] else if (a.parts.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(children: [
              Text(s.partsTitle(p.book.kind), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              const Spacer(),
              Text(s.found(found, a.parts.length), style: const TextStyle(color: Color(0xFF666C8F), fontSize: 13)),
            ]),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final part in a.parts)
                p.partFound(a.id, part.id)
                    ? GestureDetector(
                        onTap: () => Speech.instance.say(part.name(lang), lang),
                        child: _Chip(text: part.name(lang), found: true),
                      )
                    : const _Chip(text: '?', found: false),
            ]),
          ],
          if (p.unlocked(3)) ...[
            const SizedBox(height: 12),
            Row(children: [
              for (var i = 0; i < quizGoal; i++)
                Icon(i < p.quizScore(a.id) ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: const Color(0xFFFFB81C), size: 22),
              const SizedBox(width: 6),
              Text(s.quizScore(p.quizScore(a.id)), style: const TextStyle(color: Color(0xFF666C8F))),
            ]),
          ],
          const SizedBox(height: 18),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () =>
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => PageScreen(animal: a, progress: p))),
                icon: const Icon(Icons.menu_book_rounded),
                label: Text(s.showPage),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => onScan(quiz: p.unlocked(3)),
                icon: Icon(p.unlocked(3) ? Icons.quiz_rounded : Icons.photo_camera_rounded),
                label: Text(p.unlocked(3) ? s.startQuiz : s.scan),
                style: FilledButton.styleFrom(
                  backgroundColor: a.color,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text, required this.found});
  final String text;
  final bool found;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: found ? const Color(0xFFDFF3E7) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: found ? const Color(0xFF9ED6B4) : const Color(0xFFD9CDBE)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (found) ...[
          const Icon(Icons.check_rounded, size: 16, color: Color(0xFF1F7A4D)),
          const SizedBox(width: 4),
        ],
        Text(text,
            style: TextStyle(
                fontWeight: FontWeight.w700, color: found ? const Color(0xFF1F7A4D) : const Color(0xFFA3A8C3))),
      ]),
    );
  }
}

IconData _habitatIcon(String h) => switch (h) {
      'farm' => Icons.agriculture_rounded,
      'home' => Icons.home_rounded,
      'forest' => Icons.park_rounded,
      'savannah' => Icons.grass_rounded,
      'desert' => Icons.wb_sunny_rounded,
      'wetland' => Icons.water_rounded,
      _ => Icons.public_rounded,
    };

/// A small coloured label (habitat, group, diet).
class _Tag extends StatelessWidget {
  const _Tag({required this.icon, required this.text, required this.color});
  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 5),
        Text(text,
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color.lerp(color, Colors.black, 0.35))),
      ]),
    );
  }
}

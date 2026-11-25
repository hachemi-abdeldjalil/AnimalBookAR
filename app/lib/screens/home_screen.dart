import 'package:flutter/material.dart';

import '../animals.dart';
import '../cloud.dart';
import '../l10n.dart';
import '../progress.dart';
import '../ui.dart';
import '../widgets/zoo_path.dart';
import 'animal_sheet.dart';
import 'ar_screen.dart';
import 'memory_game.dart';
import 'mix_game.dart';
import 'sort_game.dart';
import 'parents_screen.dart';

const brand = Color(0xFFE8702A);
const ink = Color(0xFF2B2118);

/// Home: greeting and stars, the next mission, the three levels, and the zoo
/// path with one stop per animal. The round button opens the AR camera.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.progress, this.cloud});
  final Progress progress;
  final Cloud? cloud;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int? _shownLevel; // null = follow the current level

  Progress get p => widget.progress;

  void _openAr({bool quiz = false, bool soundQuiz = false, bool helps = false}) {
    final mode = helps ? ArMode.helps : (soundQuiz ? ArMode.sound : (quiz ? ArMode.quiz : ArMode.explore));
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => ArScreen(progress: p, mode: mode)));
  }

  void _openAnimal(Animal a) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: const Color(0xFFFFFAF0),
      builder: (_) => AnimalSheet(
        animal: a,
        progress: p,
        onScan: ({bool quiz = false}) {
          Navigator.of(context).pop();
          _openAr(quiz: quiz);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: p,
      builder: (context, _) {
        final s = p.s;
        final current = p.currentLevel.clamp(1, p.book.levels);
        final level = (_shownLevel != null && p.unlocked(_shownLevel!)) ? _shownLevel! : current;
        final mission = p.mission;
        return Scaffold(
          floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
          floatingActionButton: _ScanButton(label: s.scanBook, onTap: () => _openAr(quiz: level == 3)),
          backgroundColor: AppColors.cream,
          body: CustomScrollView(slivers: [
            // the mission card overlaps the header: both in one Column, so its top edge stays tappable
            SliverToBoxAdapter(
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                _BookHeader(progress: p, onParents: () => openParents(context, p, widget.cloud)),
                Transform.translate(
                  offset: const Offset(0, -24),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: FadeSlideIn(
                      delay: const Duration(milliseconds: 100),
                      child: _MissionCard(mission: mission, progress: p, onGo: () => _openAr(quiz: mission.quiz)),
                    ),
                  ),
                ),
              ]),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
              sliver: SliverList.list(children: [
                if (p.book.levels > 1)
                  _LevelSwitcher(
                    progress: p,
                    selected: level,
                    onSelect: (l) {
                      if (p.unlocked(l)) {
                        setState(() => _shownLevel = l);
                      } else {
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(SnackBar(content: Text(s.finishFirst(l - 1))));
                      }
                    },
                  ),
                if (p.book.levels > 1) const SizedBox(height: 10),
                _LevelBar(progress: p, level: level),
                const SizedBox(height: 14),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 220),
                  child: _Games(
                    progress: p,
                    onHelps: () => _openAr(helps: true),
                    onMemory: () =>
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => MemoryGame(progress: p))),
                    onSoundQuiz: () => _openAr(soundQuiz: true),
                    onMix: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => MixGame(progress: p))),
                    onSort: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => SortGame(progress: p))),
                  ),
                ),
                const SizedBox(height: 14),
              ]),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 110),
              sliver: SliverToBoxAdapter(
                child: ZooPath(
                  progress: p,
                  level: level,
                  highlight: mission.level == level ? mission.animal?.id : null,
                  onTap: _openAnimal,
                ),
              ),
            ),
          ]),
        );
      },
    );
  }
}

/// The book's header: its colour as a gradient, back to the library, the
/// title and progress ring, stars, language and the parents' door, with three
/// of the book's stickers bobbing on the right.
class _BookHeader extends StatelessWidget {
  const _BookHeader({required this.progress, required this.onParents});
  final Progress progress;
  final VoidCallback onParents;

  @override
  Widget build(BuildContext context) {
    final s = progress.s;
    final b = progress.book;
    final met = progress.metIn(b);
    final total = b.items.length;
    final picks = b.items.take(3).toList();
    final white = Colors.white.withOpacity(0.22);
    return Container(
      padding: EdgeInsets.fromLTRB(10, MediaQuery.of(context).padding.top + 6, 14, 42),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.lerp(b.color, Colors.white, 0.18)!, b.color, Color.lerp(b.color, Colors.black, 0.25)!],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          if (Navigator.of(context).canPop())
            IconButton(
              key: const Key('back-to-books'),
              tooltip: s.booksTitle,
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            ),
          Expanded(
            child: Text(s.hello(progress.name.isEmpty ? s.explorer : progress.name),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13.5)),
          ),
          StarsChip(progress.stars),
          const SizedBox(width: 6),
          PopupMenuButton<Lang>(
            key: const Key('language'),
            tooltip: s.language,
            onSelected: progress.setLang,
            itemBuilder: (_) => [
              for (final l in Lang.values)
                CheckedPopupMenuItem(value: l, checked: l == progress.lang, child: Text(l.label)),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(color: white, borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.translate_rounded, size: 16, color: Colors.white),
                const SizedBox(width: 4),
                Text(progress.lang.short, style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
              ]),
            ),
          ),
          IconButton(
            key: const Key('parents'),
            tooltip: s.parents,
            onPressed: onParents,
            icon: const Icon(Icons.family_restroom_rounded, color: Colors.white),
          ),
        ]),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 8),
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            ProgressRing(value: total == 0 ? 0 : met / total, size: 58),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(b.title(progress.lang),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style:
                        const TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w800, height: 1.1)),
                const SizedBox(height: 3),
                Text(s.metOf(b.kind, met, total), style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13)),
              ]),
            ),
            SizedBox(
              width: 112,
              height: 70,
              child: Stack(clipBehavior: Clip.none, children: [
                for (final (i, a) in picks.indexed)
                  PositionedDirectional(
                    end: i * 34.0,
                    top: i.isOdd ? 0 : 8,
                    child: Floating(
                      phase: i / 3,
                      amount: 7,
                      child: Image.asset(a.stickerAsset,
                          width: 56, height: 56, errorBuilder: (_, __, ___) => const SizedBox(width: 56, height: 56)),
                    ),
                  ),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _MissionCard extends StatelessWidget {
  const _MissionCard({required this.mission, required this.progress, required this.onGo});
  final Mission mission;
  final Progress progress;
  final VoidCallback onGo;

  @override
  Widget build(BuildContext context) {
    final s = progress.s;
    final a = mission.animal;
    final (title, subtitle) = switch (mission.level) {
      1 => (s.meet(a!, kind: progress.book.kind), s.openPage(a.page)),
      2 => (s.findPart(a!, mission.part!, kind: progress.book.kind), s.openPage(a.page)),
      3 => (s.quizOf(a!), '${s.answer3} · ${s.page(a.page)}'),
      _ => (s.allDone, s.playAgain),
    };
    final color = a?.color ?? brand;
    return Material(
      key: const Key('mission'),
      color: color,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onGo,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.nextMission.toUpperCase(),
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1)),
                const SizedBox(height: 3),
                Text(title,
                    style:
                        const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800, height: 1.2)),
                const SizedBox(height: 3),
                Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(mission.quiz ? Icons.quiz_rounded : Icons.photo_camera_rounded, size: 18, color: color),
                    const SizedBox(width: 6),
                    Text(s.go, style: TextStyle(color: color, fontWeight: FontWeight.w800)),
                  ]),
                ),
              ]),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: a == null
                  ? const CircleAvatar(
                      radius: 38,
                      backgroundColor: Color(0xFFFFF0C2),
                      child: Icon(Icons.emoji_events_rounded, size: 40, color: Color(0xFFF2A60C)))
                  : ClipOval(
                      child: Container(
                        width: 76,
                        height: 76,
                        color: Color.lerp(color, Colors.white, 0.85),
                        padding: const EdgeInsets.all(6),
                        child: Floating(
                          amount: 4,
                          child: Image.asset(a.stickerAsset,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Image.asset(a.thumbAsset, fit: BoxFit.cover)),
                        ),
                      ),
                    ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _LevelSwitcher extends StatelessWidget {
  const _LevelSwitcher({required this.progress, required this.selected, required this.onSelect});
  final Progress progress;
  final int selected;
  final void Function(int) onSelect;

  @override
  Widget build(BuildContext context) {
    final s = progress.s;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: const Color(0xFFF1E9DD), borderRadius: BorderRadius.circular(18)),
      child: Row(children: [
        for (final l in [1, 2, 3])
          Expanded(
            child: GestureDetector(
              key: Key('level-$l'),
              onTap: () => onSelect(l),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                decoration: BoxDecoration(
                  color: l == selected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: l == selected
                      ? const [BoxShadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, 2))]
                      : null,
                ),
                child: Column(children: [
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    if (progress.levelDone(l))
                      const Icon(Icons.check_circle_rounded, size: 15, color: Color(0xFF2E9E6A))
                    else if (!progress.unlocked(l))
                      const Icon(Icons.lock_rounded, size: 14, color: Color(0xFFA89A8C))
                    else
                      const Icon(Icons.play_circle_fill_rounded, size: 15, color: brand),
                    const SizedBox(width: 3),
                    Text('$l',
                        style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF7A6A5C), fontSize: 12)),
                  ]),
                  Text(s.levelName(l, kind: progress.book.kind),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: l == selected ? FontWeight.w800 : FontWeight.w600,
                        color: progress.unlocked(l) ? ink : const Color(0xFFA89A8C),
                      )),
                ]),
              ),
            ),
          ),
      ]),
    );
  }
}

class _LevelBar extends StatelessWidget {
  const _LevelBar({required this.progress, required this.level});
  final Progress progress;
  final int level;

  @override
  Widget build(BuildContext context) {
    final (done, total) = progress.levelCount(level);
    final s = progress.s;
    return Row(children: [
      Text(s.levelTitle(level), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: ink)),
      const SizedBox(width: 10),
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: total == 0 ? 0 : done / total,
            minHeight: 8,
            backgroundColor: const Color(0xFFEDE3D5),
            color: progress.levelDone(level) ? const Color(0xFF2E9E6A) : const Color(0xFFF2A60C),
          ),
        ),
      ),
      const SizedBox(width: 10),
      Text(s.levelProgress(level, done, total, kind: progress.book.kind),
          style: const TextStyle(fontSize: 12, color: Color(0xFF7A6A5C))),
    ]);
  }
}

class _ScanButton extends StatelessWidget {
  const _ScanButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        key: const Key('open-camera'),
        onTap: onTap,
        child: Container(
          width: 74,
          height: 74,
          decoration: BoxDecoration(
            color: brand,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 5),
            boxShadow: const [BoxShadow(color: Color(0x55E8702A), blurRadius: 16, offset: Offset(0, 6))],
          ),
          child: const Icon(Icons.center_focus_strong_rounded, color: Colors.white, size: 34),
        ),
      ),
    );
  }
}

/// The book's games (books.json "games"): memory (no camera), the sound quiz,
/// "Who helps?" / "Find the letter" / "Find the colour" (camera: scan the
/// right page) and mixing paints (no camera). Two tiles per row.
class _Games extends StatelessWidget {
  const _Games({
    required this.progress,
    required this.onMemory,
    required this.onSoundQuiz,
    required this.onHelps,
    required this.onMix,
    required this.onSort,
  });
  final Progress progress;
  final VoidCallback onMemory;
  final VoidCallback onSoundQuiz;
  final VoidCallback onHelps;
  final VoidCallback onMix;
  final VoidCallback onSort;

  @override
  Widget build(BuildContext context) {
    final s = progress.s;
    final kind = progress.book.kind;
    Widget tile(Key key, IconData icon, String title, String sub, Color color, VoidCallback onTap) => Expanded(
          child: Pressable(
            key: key,
            onTap: onTap,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color, Color.lerp(color, Colors.black, 0.18)!],
                ),
                boxShadow: [BoxShadow(color: color.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(children: [
                  CircleAvatar(radius: 20, backgroundColor: Colors.white, child: Icon(icon, color: color)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(title,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                      Text(sub,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 11.5, height: 1.2)),
                    ]),
                  ),
                ]),
              ),
            ),
          ),
        );
    final tiles = [
      for (final g in progress.book.games)
        switch (g) {
          'memory' => tile(const Key('game-memory'), Icons.grid_view_rounded, s.memoryGame, s.memoryHint(kind: kind),
              const Color(0xFF7A6BB5), onMemory),
          'sound' => tile(const Key('game-sound'), Icons.hearing_rounded, s.soundQuiz, s.soundQuizHint,
              const Color(0xFF1F8A8A), onSoundQuiz),
          'helps' => tile(const Key('game-helps'), Icons.volunteer_activism_rounded, s.helpsGame, s.helpsHint,
              const Color(0xFFD9483B), onHelps),
          'find' => tile(const Key('game-find'), kind == 'colors' ? Icons.colorize_rounded : Icons.spellcheck_rounded,
              s.findGame(kind), s.findHint, const Color(0xFF1F8A8A), onHelps),
          'sort' => tile(
              const Key('game-sort'), Icons.category_rounded, s.sortGame, s.sortHint, const Color(0xFF6B8E23), onSort),
          'mix' =>
            tile(const Key('game-mix'), Icons.palette_rounded, s.mixGame, s.mixHint, const Color(0xFFD9483B), onMix),
          _ => const SizedBox.shrink(),
        },
    ];
    return Column(children: [
      for (var i = 0; i < tiles.length; i += 2) ...[
        if (i > 0) const SizedBox(height: 10),
        Row(children: [
          tiles[i],
          if (i + 1 < tiles.length) ...[const SizedBox(width: 10), tiles[i + 1]],
        ]),
      ],
    ]);
  }
}

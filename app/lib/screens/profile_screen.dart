import 'package:flutter/material.dart';

import '../books.dart';
import '../cloud.dart';
import '../l10n.dart';
import '../progress.dart';
import '../ui.dart';
import 'home_screen.dart';

/// The child's own page (tap their name or picture): who they are, a medal per
/// book, what they did in each book, and what to do next, with a button to
/// go straight there. Settings for the child: their picture, name and language.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.progress, this.cloud});
  final Progress progress;
  final Cloud? cloud;

  void _open(BuildContext context, Book b) {
    progress.openBook(b.id);
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => HomeScreen(progress: progress, cloud: cloud)));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: progress,
      builder: (context, _) {
        final p = progress;
        final s = p.s;
        final c = p.child;
        final total = p.books.fold(0, (n, b) => n + b.items.length);
        return Scaffold(
          backgroundColor: AppColors.cream,
          body: ListView(padding: EdgeInsets.zero, children: [
            // ---- who I am ----
            Container(
              padding: EdgeInsets.fromLTRB(8, MediaQuery.of(context).padding.top + 4, 18, 26),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.sky, AppColors.grape],
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
              child: Column(children: [
                Row(children: [
                  IconButton(
                    key: const Key('profile-back'),
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  ),
                  Text(s.myPage,
                      style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  StarsChip(p.stars),
                ]),
                const SizedBox(height: 8),
                Floating(amount: 5, child: Avatar(name: p.name, size: 96, picture: p.avatarOf(c.id))),
                const SizedBox(height: 10),
                Text(p.name,
                    key: const Key('profile-name'),
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('${p.metAll} / $total · ${s.statDiscovered}',
                    style: TextStyle(color: Colors.white.withOpacity(0.92), fontSize: 13.5)),
                const SizedBox(height: 12),
                ProgressBar(
                    value: total == 0 ? 0 : p.metAll / total,
                    color: Colors.white,
                    track: Colors.white.withOpacity(0.25),
                    height: 8),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                // ---- medals: one per book ----
                SectionLabel(s.myBadges),
                FadeSlideIn(
                  child: Wrap(spacing: 10, runSpacing: 10, children: [
                    for (final b in p.books) _Medal(book: b, progress: p),
                  ]),
                ),
                // ---- what's next ----
                SectionLabel(s.whatNext),
                for (final (i, b) in p.books.indexed)
                  FadeSlideIn(
                    delay: Duration(milliseconds: 60 * i),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _NextCard(book: b, progress: p, onTap: () => _open(context, b)),
                    ),
                  ),
                // ---- what I did ----
                SectionLabel(s.whatIDid),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.86,
                  children: [
                    StatTile(
                        icon: Icons.explore_rounded, count: p.metAll, label: s.statDiscovered, color: AppColors.sky),
                    StatTile(
                        icon: Icons.translate_rounded,
                        count: p.wordsLearned,
                        label: s.statWords,
                        color: AppColors.mint),
                    StatTile(
                        icon: Icons.quiz_rounded,
                        count: c.quiz.values.fold<int>(0, (n, v) => n + v),
                        label: s.statQuiz,
                        color: AppColors.berry),
                    StatTile(
                        icon: Icons.emoji_events_rounded,
                        count: c.memoryWins + c.soundCorrect,
                        label: s.statGames,
                        color: AppColors.grape),
                    StatTile(
                        icon: Icons.volunteer_activism_rounded,
                        count: c.food.length,
                        label: s.statFood,
                        color: AppColors.brand),
                    StatTile(
                        icon: Icons.timer_rounded,
                        value: s.minutes((c.playSeconds / 60).round()),
                        label: s.statTime,
                        color: AppColors.green),
                  ],
                ),
                // ---- my settings ----
                SectionLabel(s.settings),
                AppCard(child: _Settings(progress: p)),
              ]),
            ),
          ]),
        );
      },
    );
  }
}

/// A medal per book: grey until started, silver when level 1 is done, gold when the whole book is.
class _Medal extends StatelessWidget {
  const _Medal({required this.book, required this.progress});
  final Book book;
  final Progress progress;

  @override
  Widget build(BuildContext context) {
    final p = progress;
    final level = p.currentLevelIn(book);
    final started = p.metIn(book) > 0;
    final (ring, label) = level == 4
        ? (AppColors.gold, '★')
        : level > 1
            ? (const Color(0xFFB8C2CC), '${level - 1}')
            : (started ? book.color.withOpacity(0.5) : const Color(0xFFECE5DA), '');
    return Tooltip(
      message: book.title(p.lang),
      child: SizedBox(
        width: 70,
        child: Column(children: [
          Container(
            width: 58,
            height: 58,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(shape: BoxShape.circle, color: ring),
            child: Container(
              decoration: BoxDecoration(shape: BoxShape.circle, color: started ? Colors.white : AppColors.sand),
              padding: const EdgeInsets.all(5),
              child: Opacity(
                opacity: started ? 1 : 0.4,
                child: Image.asset(book.items.first.stickerAsset, errorBuilder: (_, __, ___) => const SizedBox()),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(label.isEmpty ? book.title(p.lang) : '${book.title(p.lang)} $label',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.muted)),
        ]),
      ),
    );
  }
}

/// A book's next step: its level, the mission and a Play button.
class _NextCard extends StatelessWidget {
  const _NextCard({required this.book, required this.progress, required this.onTap});
  final Book book;
  final Progress progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = progress;
    final s = p.s;
    final m = p.missionIn(book);
    final a = m.animal;
    final title = switch (m.level) {
      1 => s.meet(a!, kind: book.kind),
      2 => s.findPart(a!, m.part!, kind: book.kind),
      3 => s.quizOf(a!),
      _ => s.finishedBook,
    };
    final (done, total) = p.levelCountIn(book, m.level.clamp(1, book.levels));
    return Pressable(
      onTap: onTap,
      child: AppCard(
        key: Key('next-${book.id}'),
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          Container(
            width: 54,
            height: 54,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: book.color.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
            child: a == null
                ? const Icon(Icons.emoji_events_rounded, color: AppColors.gold, size: 34)
                : Image.asset(a.stickerAsset, errorBuilder: (_, __, ___) => Image.asset(a.thumbAsset)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${book.title(p.lang)} · ${m.level == 4 ? s.finishedBook : s.levelOf(m.level, book.levels)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: book.color)),
              const SizedBox(height: 2),
              Text(title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink)),
              const SizedBox(height: 6),
              ProgressBar(value: total == 0 ? 1 : done / total, color: book.color, height: 5),
            ]),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
              radius: 18,
              backgroundColor: book.color,
              child: Icon(m.level == 4 ? Icons.replay_rounded : Icons.play_arrow_rounded, color: Colors.white)),
        ]),
      ),
    );
  }
}

/// The child's settings: their picture (an item from the books, or their initial), name and language.
class _Settings extends StatelessWidget {
  const _Settings({required this.progress});
  final Progress progress;

  Future<void> _rename(BuildContext context) async {
    final p = progress;
    final s = p.s;
    final ctrl = TextEditingController(text: p.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.myName),
        content: TextField(
            key: const Key('profile-name-field'),
            controller: ctrl,
            autofocus: true,
            maxLength: 20,
            textCapitalization: TextCapitalization.words),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(s.cancel)),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()), child: Text(s.save)),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) p.renameChild(p.child.id, name);
  }

  @override
  Widget build(BuildContext context) {
    final p = progress;
    final s = p.s;
    final id = p.child.id;
    final current = p.avatarOf(id);
    // one picture from each book, plus a few more animals
    final choices = <String>{
      for (final b in p.books) b.items.first.stickerAsset,
      for (final a in p.books.first.items.take(8)) a.stickerAsset,
    }.toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(s.myPicture, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink)),
      const SizedBox(height: 10),
      Wrap(spacing: 8, runSpacing: 8, children: [
        GestureDetector(
          key: const Key('avatar-initial'),
          onTap: () => p.setAvatar(id, null),
          child: Avatar(name: p.name, size: 48, selected: current == null),
        ),
        for (final pic in choices)
          GestureDetector(
            onTap: () => p.setAvatar(id, pic),
            child: Avatar(name: p.name, size: 48, picture: pic, selected: current == pic),
          ),
      ]),
      const Divider(height: 28),
      Row(children: [
        const Icon(Icons.badge_rounded, color: AppColors.brand, size: 20),
        const SizedBox(width: 8),
        Expanded(child: Text('${s.myName}: ${p.name}', style: const TextStyle(fontWeight: FontWeight.w700))),
        TextButton(key: const Key('profile-rename'), onPressed: () => _rename(context), child: Text(s.rename)),
      ]),
      const SizedBox(height: 6),
      Row(children: [
        const Icon(Icons.translate_rounded, color: AppColors.brand, size: 20),
        const SizedBox(width: 8),
        Text(s.appLanguage, style: const TextStyle(fontWeight: FontWeight.w700)),
      ]),
      const SizedBox(height: 8),
      SizedBox(
        width: double.infinity,
        child: SegmentedButton<Lang>(
          showSelectedIcon: false,
          segments: [for (final l in Lang.values) ButtonSegment(value: l, label: Text(l.label))],
          selected: {p.lang},
          onSelectionChanged: (v) => p.setLang(v.first),
        ),
      ),
    ]);
  }
}

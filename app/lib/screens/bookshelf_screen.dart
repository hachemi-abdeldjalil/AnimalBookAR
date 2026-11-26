import 'package:flutter/material.dart';

import '../books.dart';
import '../cloud.dart';
import '../progress.dart';
import '../ui.dart';
import 'home_screen.dart';
import 'parents_screen.dart';
import 'profile_screen.dart';

/// The library: the child's greeting and stars, a card to continue the last
/// book, three numbers, and the books as a grid of covers.
class BookshelfScreen extends StatefulWidget {
  const BookshelfScreen({super.key, required this.progress, this.cloud});
  final Progress progress;
  final Cloud? cloud;

  @override
  State<BookshelfScreen> createState() => _BookshelfScreenState();
}

class _BookshelfScreenState extends State<BookshelfScreen> {
  // the header's stickers drift up and fade as the list scrolls
  final _scroll = ScrollController();

  Progress get progress => widget.progress;
  Cloud? get cloud => widget.cloud;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _open(BuildContext context, Book b) {
    progress.openBook(b.id);
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => HomeScreen(progress: progress, cloud: cloud)));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: progress,
      builder: (context, _) {
        final s = progress.s;
        final name = progress.name.isEmpty ? s.explorer : progress.name;
        final c = progress.child;
        return Scaffold(
          backgroundColor: AppColors.cream,
          body: ListView(controller: _scroll, padding: EdgeInsets.zero, children: [
            // the Continue card overlaps the header: both in one Column, so its top edge stays tappable
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              _LibraryHeader(
                  scroll: _scroll,
                  progress: progress,
                  name: name,
                  cloud: cloud,
                  onParents: () => openParents(context, progress, cloud)),
              Transform.translate(
                offset: const Offset(0, -26),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: FadeSlideIn(
                    delay: const Duration(milliseconds: 120),
                    child: _ContinueCard(progress: progress, onTap: () => _open(context, progress.book)),
                  ),
                ),
              ),
            ]),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                FadeSlideIn(
                  delay: const Duration(milliseconds: 220),
                  child: Row(children: [
                    Expanded(
                        child: StatTile(
                            icon: Icons.star_rounded,
                            count: progress.stars,
                            label: s.statStars,
                            color: AppColors.gold)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: StatTile(
                            icon: Icons.explore_rounded,
                            count: progress.metAll,
                            label: s.statDiscovered,
                            color: const Color(0xFF2F6FD0))),
                    const SizedBox(width: 10),
                    Expanded(
                        child: StatTile(
                            icon: Icons.timer_rounded,
                            count: (c.playSeconds / 60).round(),
                            label: s.statMinutes,
                            color: AppColors.green)),
                  ]),
                ),
                SectionLabel(s.yourBooks),
                GridView.count(
                  padding: EdgeInsets.zero, // no extra status-bar padding (the screen is edge to edge)
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.74,
                  children: [
                    for (final (i, b) in progress.books.indexed)
                      FadeSlideIn(
                        delay: Duration(milliseconds: 300 + 80 * i),
                        child: Pressable(
                          onTap: () => _open(context, b),
                          child: _BookCover(book: b, progress: progress),
                        ),
                      ),
                  ],
                ),
              ]),
            ),
          ]),
        );
      },
    );
  }
}

/// The book the child was last in, with its next mission.
class _ContinueCard extends StatelessWidget {
  const _ContinueCard({required this.progress, required this.onTap});
  final Progress progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = progress.s;
    final b = progress.book;
    final m = progress.mission;
    final a = m.animal;
    final title = switch (m.level) {
      1 => s.meet(a!, kind: b.kind),
      2 => s.findPart(a!, m.part!, kind: b.kind),
      3 => s.quizOf(a!),
      _ => s.allDone,
    };
    return Material(
      key: const Key('continue'),
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      color: b.color,
      child: Stack(children: [
        InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [b.color, Color.lerp(b.color, Colors.black, 0.22)!],
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${s.continueLearning.toUpperCase()} · ${b.title(progress.lang)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8)),
                  const SizedBox(height: 4),
                  Text(title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800, height: 1.2)),
                  const SizedBox(height: 10),
                  ProgressBar(
                    value: b.items.isEmpty ? 0 : progress.metIn(b) / b.items.length,
                    color: Colors.white,
                    track: Colors.white.withOpacity(0.25),
                    height: 6,
                  ),
                  const SizedBox(height: 6),
                  Text(s.metOf(b.kind, progress.metIn(b), b.items.length),
                      style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12)),
                ]),
              ),
              const SizedBox(width: 14),
              Stack(clipBehavior: Clip.none, children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: a == null
                      ? const CircleAvatar(
                          radius: 34,
                          backgroundColor: AppColors.goldBg,
                          child: Icon(Icons.emoji_events_rounded, size: 36, color: AppColors.gold))
                      : ClipOval(
                          child: Container(
                            width: 68,
                            height: 68,
                            color: Color.lerp(b.color, Colors.white, 0.85),
                            padding: const EdgeInsets.all(5),
                            child: Floating(
                              amount: 4,
                              child: Image.asset(a.stickerAsset,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => Image.asset(a.thumbAsset, fit: BoxFit.cover)),
                            ),
                          ),
                        ),
                ),
                PositionedDirectional(
                  end: -4,
                  bottom: -4,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: b.color, width: 2),
                    ),
                    child: Icon(Icons.play_arrow_rounded, size: 18, color: b.color),
                  ),
                ),
              ]),
            ]),
          ),
        ),
        const Positioned.fill(child: Shine()),
      ]),
    );
  }
}

class _BookCover extends StatelessWidget {
  const _BookCover({required this.book, required this.progress});
  final Book book;
  final Progress progress;

  @override
  Widget build(BuildContext context) {
    final s = progress.s;
    final met = progress.metIn(book);
    final total = book.items.length;
    final done = total > 0 && met == total;
    return AppCard(
      key: Key('book-${book.id}'),
      padding: EdgeInsets.zero,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // four pictures from the book, on its colour
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: book.color, borderRadius: BorderRadius.circular(15)),
            child: GridView.count(
              padding: EdgeInsets.zero, // no extra status-bar padding (the screen is edge to edge)
              crossAxisCount: 2,
              mainAxisSpacing: 5,
              crossAxisSpacing: 5,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (final a in book.items.take(4))
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(a.thumbAsset, fit: BoxFit.cover),
                  ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text(book.title(progress.lang),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.ink)),
              ),
              if (done) const Icon(Icons.check_circle_rounded, color: AppColors.green, size: 18),
            ]),
            const SizedBox(height: 8),
            ProgressBar(value: total == 0 ? 0 : met / total, color: book.color, height: 6),
            const SizedBox(height: 5),
            Text(s.metOf(book.kind, met, total), style: const TextStyle(color: AppColors.muted, fontSize: 11.5)),
          ]),
        ),
      ]),
    );
  }
}

/// The library's header: the child, their stars and the parents' door on a
/// warm gradient, the title, and three stickers from the books bobbing about.
class _LibraryHeader extends StatelessWidget {
  const _LibraryHeader(
      {required this.progress, required this.name, required this.onParents, required this.scroll, this.cloud});
  final Progress progress;
  final ScrollController scroll;
  final Cloud? cloud;
  final String name;
  final VoidCallback onParents;

  @override
  Widget build(BuildContext context) {
    final s = progress.s;
    final picks = [for (final b in progress.books.take(3)) b.items.first];
    final total = progress.books.fold(0, (n, b) => n + b.items.length);
    return Container(
      padding: EdgeInsets.fromLTRB(18, MediaQuery.of(context).padding.top + 12, 18, 44),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF8C5A), AppColors.brand, AppColors.brandDark],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          // the child's picture and name open their own page
          Expanded(
            child: GestureDetector(
              key: const Key('open-profile'),
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => ProfileScreen(progress: progress, cloud: cloud))),
              child: Row(children: [
                Avatar(name: name, size: 44, picture: progress.avatarOf(progress.child.id)),
                const SizedBox(width: 10),
                Flexible(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(s.hello(name),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                    Text(s.myPage,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 12,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.white.withOpacity(0.6))),
                  ]),
                ),
              ]),
            ),
          ),
          StarsChip(progress.stars),
          const SizedBox(width: 6),
          IconButton(
            key: const Key('parents'),
            tooltip: s.parents,
            onPressed: onParents,
            style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.22)),
            icon: const Icon(Icons.family_restroom_rounded, color: Colors.white),
          ),
        ]),
        const SizedBox(height: 18),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.booksTitle,
                  style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800, height: 1.1)),
              const SizedBox(height: 4),
              Text('${progress.metAll} / $total · ${s.statDiscovered}',
                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13)),
            ]),
          ),
          AnimatedBuilder(
            animation: scroll,
            builder: (context, child) {
              final y = scroll.hasClients ? scroll.offset.clamp(0.0, 200.0) : 0.0;
              return Opacity(
                opacity: (1 - y / 160).clamp(0.0, 1.0),
                child: Transform.translate(offset: Offset(0, -y * 0.45), child: child),
              );
            },
            child: SizedBox(
              width: 150,
              height: 76,
              child: Stack(clipBehavior: Clip.none, children: [
                for (final (i, a) in picks.indexed)
                  Positioned(
                    left: i * 46.0,
                    top: i.isOdd ? 0 : 10,
                    child: Floating(
                      phase: i / 3,
                      amount: 8,
                      child: Image.asset(a.stickerAsset,
                          width: 64, height: 64, errorBuilder: (_, __, ___) => const SizedBox(width: 64, height: 64)),
                    ),
                  ),
              ]),
            ),
          ),
        ]),
      ]),
    );
  }
}

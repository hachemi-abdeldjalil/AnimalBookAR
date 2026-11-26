import 'dart:math';

import 'package:flutter/material.dart';

import '../cloud.dart';
import '../l10n.dart';
import '../progress.dart';
import '../ui.dart';
import 'home_screen.dart' show brand;

/// Asks a small sum children usually can't do yet, then opens [ParentsScreen].
Future<void> openParents(BuildContext context, Progress progress, Cloud? cloud) async {
  final s = progress.s;
  final r = Random();
  final a = 6 + r.nextInt(7), b = 5 + r.nextInt(8);
  final answers = {a + b, a + b + 1 + r.nextInt(3), a + b - 1 - r.nextInt(3)}.toList()..shuffle();
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.brand.withOpacity(0.12), shape: BoxShape.circle),
            child: const Icon(Icons.lock_rounded, color: AppColors.brand, size: 28),
          ),
          const SizedBox(height: 12),
          Text(s.forParents, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.ink)),
          const SizedBox(height: 6),
          Text(s.gateQuestion(a, b),
              textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, color: AppColors.muted)),
          const SizedBox(height: 18),
          Row(children: [
            for (final n in answers) ...[
              Expanded(
                child: FilledButton.tonal(
                  key: Key('gate-$n'),
                  onPressed: () => Navigator.of(ctx).pop(n == a + b),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('$n', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                ),
              ),
              if (n != answers.last) const SizedBox(width: 10),
            ],
          ]),
          const SizedBox(height: 6),
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(s.cancel)),
        ]),
      ),
    ),
  );
  if (ok == true && context.mounted) {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => ParentsScreen(progress: progress, cloud: cloud)));
  }
}

class ParentsScreen extends StatelessWidget {
  const ParentsScreen({super.key, required this.progress, required this.cloud});
  final Progress progress;
  final Cloud? cloud;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([progress, if (cloud != null) cloud!]),
      builder: (context, _) {
        final s = progress.s;
        return Scaffold(
          backgroundColor: AppColors.cream,
          appBar: AppBar(
            title: Text(s.parents, style: const TextStyle(fontWeight: FontWeight.w800)),
            backgroundColor: AppColors.cream,
            surfaceTintColor: Colors.transparent,
          ),
          body: ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 32), children: [
            for (final (i, w) in <Widget>[
              _ChildHeader(progress: progress),
              SectionLabel(s.overview),
              _Overview(progress: progress),
              SectionLabel(s.byBook),
              _BookProgress(progress: progress),
              SectionLabel(s.children),
              AppCard(padding: const EdgeInsets.fromLTRB(14, 6, 6, 12), child: _ChildrenCard(progress: progress)),
              SectionLabel(s.account),
              AppCard(child: _AccountCard(progress: progress, cloud: cloud)),
              SectionLabel(s.settings),
              AppCard(child: _Settings(progress: progress)),
            ].indexed)
              FadeSlideIn(delay: Duration(milliseconds: 40 * i), child: w),
          ]),
        );
      },
    );
  }
}

/// The active child: a big avatar, the name and stars, and how far along.
class _ChildHeader extends StatelessWidget {
  const _ChildHeader({required this.progress});
  final Progress progress;

  @override
  Widget build(BuildContext context) {
    final p = progress;
    final s = p.s;
    final total = p.books.fold(0, (n, b) => n + b.items.length);
    return AppCard(
      child: Row(children: [
        Avatar(name: p.name, size: 60),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p.name, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: AppColors.ink)),
            const SizedBox(height: 4),
            Text(s.progressOf(p.name), style: const TextStyle(color: AppColors.muted, fontSize: 13)),
            const SizedBox(height: 8),
            ProgressBar(value: total == 0 ? 0 : p.metAll / total, color: AppColors.brand),
          ]),
        ),
        const SizedBox(width: 12),
        StarsChip(p.stars),
      ]),
    );
  }
}

class _Overview extends StatelessWidget {
  const _Overview({required this.progress});
  final Progress progress;

  @override
  Widget build(BuildContext context) {
    final p = progress;
    final s = p.s;
    final c = p.child;
    final tiles = [
      StatTile(icon: Icons.explore_rounded, count: p.metAll, label: s.statDiscovered, color: const Color(0xFF2F6FD0)),
      StatTile(
          icon: Icons.translate_rounded, count: p.wordsLearned, label: s.statWords, color: const Color(0xFF00897B)),
      StatTile(
          icon: Icons.timer_rounded,
          value: s.minutes((c.playSeconds / 60).round()),
          label: s.statTime,
          color: AppColors.green),
      StatTile(
          icon: Icons.emoji_events_rounded,
          count: c.memoryWins + c.soundCorrect,
          label: s.statGames,
          color: const Color(0xFF7E57C2)),
      StatTile(
          icon: Icons.quiz_rounded,
          count: c.quiz.values.fold<int>(0, (n, v) => n + v),
          label: s.statQuiz,
          color: const Color(0xFFD81B60)),
      StatTile(icon: Icons.volunteer_activism_rounded, count: c.food.length, label: s.statFood, color: AppColors.brand),
    ];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 0.86,
      children: tiles,
    );
  }
}

/// One row per book: met, and the parts and quiz when the book has them.
class _BookProgress extends StatelessWidget {
  const _BookProgress({required this.progress});
  final Progress progress;

  @override
  Widget build(BuildContext context) {
    final p = progress;
    final s = p.s;
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Column(children: [
        for (final (i, b) in p.books.indexed) ...[
          if (i > 0) const Divider(height: 1, color: AppColors.line),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  color: b.color,
                  padding: const EdgeInsets.all(3),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: Image.asset(b.items.first.thumbAsset, width: 40, height: 40, fit: BoxFit.cover),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(
                      child: Text(b.title(p.lang),
                          style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink, fontSize: 14.5)),
                    ),
                    Text('${p.metIn(b)} / ${b.items.length}',
                        style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink, fontSize: 13)),
                  ]),
                  const SizedBox(height: 6),
                  ProgressBar(value: b.items.isEmpty ? 0 : p.metIn(b) / b.items.length, color: b.color, height: 6),
                  if (b.levels > 1) ...[
                    const SizedBox(height: 5),
                    Text(s.partsQuiz(p.partsIn(b), p.totalPartsIn(b), p.quizIn(b), b.items.length * quizGoal),
                        style: const TextStyle(color: AppColors.muted, fontSize: 11.5)),
                  ],
                ]),
              ),
            ]),
          ),
        ],
      ]),
    );
  }
}

class _Settings extends StatelessWidget {
  const _Settings({required this.progress});
  final Progress progress;

  @override
  Widget build(BuildContext context) {
    final s = progress.s;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.translate_rounded, size: 18, color: AppColors.brand),
        const SizedBox(width: 8),
        Text(s.appLanguage, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
      ]),
      const SizedBox(height: 10),
      SizedBox(
        width: double.infinity,
        child: SegmentedButton<Lang>(
          showSelectedIcon: false,
          segments: [for (final l in Lang.values) ButtonSegment(value: l, label: Text(l.label))],
          selected: {progress.lang},
          onSelectionChanged: (v) => progress.setLang(v.first),
        ),
      ),
    ]);
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.progress, required this.cloud});
  final Progress progress;
  final Cloud? cloud;

  @override
  Widget build(BuildContext context) {
    final s = progress.s;
    final c = cloud;
    if (c == null) {
      return Row(children: [
        const Icon(Icons.cloud_off_rounded, size: 20, color: AppColors.faint),
        const SizedBox(width: 8),
        Expanded(child: Text(s.cloudOff, style: const TextStyle(color: AppColors.muted))),
      ]);
    }
    final user = c.user;
    final error = c.lastError;
    if (user != null) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.verified_user_rounded, color: Color(0xFF22B07D)),
          const SizedBox(width: 8),
          Expanded(
              child: Text(s.signedInAs(user.email ?? user.displayName ?? ''),
                  style: const TextStyle(fontWeight: FontWeight.w700))),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          if (c.syncing) const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
          if (!c.syncing) const Icon(Icons.cloud_done_rounded, size: 18, color: Color(0xFF22B07D)),
          const SizedBox(width: 6),
          Text(c.syncing ? s.syncingNow : s.synced, style: const TextStyle(color: Color(0xFF666C8F))),
        ]),
        if (error != null)
          Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(s.authError(error), style: const TextStyle(color: Colors.red))),
        const SizedBox(height: 10),
        OutlinedButton.icon(
            key: const Key('sign-out'),
            onPressed: c.signOut,
            icon: const Icon(Icons.logout_rounded),
            label: Text(s.signOut)),
      ]);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        const Icon(Icons.cloud_off_rounded, size: 20, color: AppColors.faint),
        const SizedBox(width: 8),
        Expanded(child: Text(s.notSignedIn, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink))),
      ]),
      const SizedBox(height: 8),
      Text(s.syncPitch, style: const TextStyle(color: AppColors.muted, height: 1.35)),
      const SizedBox(height: 12),
      FilledButton.icon(
        key: const Key('google-sign-in'),
        onPressed: c.signInWithGoogle,
        icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
        label: Text(s.continueGoogle),
        style: FilledButton.styleFrom(backgroundColor: brand, padding: const EdgeInsets.symmetric(vertical: 12)),
      ),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        key: const Key('email-sign-in'),
        onPressed: () => showDialog<void>(context: context, builder: (_) => _EmailDialog(progress: progress, cloud: c)),
        icon: const Icon(Icons.mail_outline_rounded),
        label: Text(s.useEmail),
        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
      ),
      if (error != null)
        Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(s.authError(error), style: const TextStyle(color: Colors.red))),
    ]);
  }
}

class _EmailDialog extends StatefulWidget {
  const _EmailDialog({required this.progress, required this.cloud});
  final Progress progress;
  final Cloud cloud;

  @override
  State<_EmailDialog> createState() => _EmailDialogState();
}

class _EmailDialogState extends State<_EmailDialog> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _message;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() call, {String? success}) async {
    setState(() {
      _busy = true;
      _message = null;
    });
    await call();
    if (!mounted) return;
    final err = widget.cloud.lastError;
    setState(() {
      _busy = false;
      _message = err != null ? widget.progress.s.authError(err) : success;
    });
    if (err == null && success == null && widget.cloud.user != null) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.progress.s;
    final c = widget.cloud;
    return AlertDialog(
      title: Text(s.useEmail),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            decoration: InputDecoration(labelText: s.email)),
        TextField(controller: _password, obscureText: true, decoration: InputDecoration(labelText: s.password)),
        if (_message != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(_message!)),
        if (_busy) const Padding(padding: EdgeInsets.only(top: 10), child: LinearProgressIndicator()),
      ]),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => _run(() => c.resetPassword(_email.text), success: s.resetSent),
          child: Text(s.forgotPassword),
        ),
        TextButton(
          onPressed: _busy ? null : () => _run(() => c.createAccount(_email.text, _password.text)),
          child: Text(s.createAccount),
        ),
        FilledButton(
          onPressed: _busy ? null : () => _run(() => c.signInWithEmail(_email.text, _password.text)),
          child: Text(s.signIn),
        ),
      ],
    );
  }
}

class _ChildrenCard extends StatelessWidget {
  const _ChildrenCard({required this.progress});
  final Progress progress;

  Future<String?> _askName(BuildContext context, {String initial = ''}) {
    final s = progress.s;
    final ctrl = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.yourName),
        content:
            TextField(controller: ctrl, autofocus: true, maxLength: 20, textCapitalization: TextCapitalization.words),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(s.cancel)),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()), child: Text(s.save)),
        ],
      ),
    );
  }

  Future<bool> _confirm(BuildContext context, String text) async {
    final s = progress.s;
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            content: Text(text),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(s.cancel)),
              FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(s.delete)),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final p = progress;
    final s = p.s;
    return Column(children: [
      for (final c in p.children)
        ListTile(
          contentPadding: EdgeInsets.zero,
          onTap: () => p.switchChild(c.id),
          leading: Avatar(name: c.name, size: 40, selected: c.id == p.child.id && p.children.length > 1),
          title: Text(c.name, style: TextStyle(fontWeight: c.id == p.child.id ? FontWeight.w800 : FontWeight.w600)),
          subtitle: Row(children: [
            const Icon(Icons.star_rounded, size: 16, color: Color(0xFFFFB81C)),
            Text(' ${p.starsOf(c)}'),
          ]),
          trailing: PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'rename') {
                final n = await _askName(context, initial: c.name);
                if (n != null && n.isNotEmpty) p.renameChild(c.id, n);
              } else if (v == 'reset') {
                if (context.mounted && await _confirm(context, s.confirmReset(c.name))) p.resetChild(c.id);
              } else if (v == 'delete') {
                if (context.mounted && await _confirm(context, s.confirmDelete(c.name))) p.deleteChild(c.id);
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'rename', child: Text(s.rename)),
              PopupMenuItem(value: 'reset', child: Text(s.resetProgress)),
              if (p.children.length > 1) PopupMenuItem(value: 'delete', child: Text(s.delete)),
            ],
          ),
        ),
      const SizedBox(height: 4),
      OutlinedButton.icon(
        key: const Key('add-child'),
        onPressed: () async {
          final n = await _askName(context);
          if (n != null && n.isNotEmpty) p.addChild(n);
        },
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: Text(s.addChild),
      ),
    ]);
  }
}

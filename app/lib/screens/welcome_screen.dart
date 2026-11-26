import 'package:flutter/material.dart';

import '../l10n.dart';
import '../progress.dart';
import '../ui.dart';

/// First launch: a branded header with a peek at the books, then a short
/// form: language and the child's first name (kept on the phone).
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key, required this.progress});
  final Progress progress;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _name = TextEditingController();
  late Lang _lang = widget.progress.lang;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _start() {
    if (_name.text.trim().isEmpty) return;
    widget.progress.setProfile(name: _name.text, lang: _lang);
  }

  @override
  Widget build(BuildContext context) {
    final s = S(_lang);
    // one picture from each book, then more from the first ones
    final books = widget.progress.books;
    final pics = <String>[
      for (var round = 0; round < 3; round++)
        for (final b in books)
          if (b.items.length > round) b.items[round * 3 % b.items.length].thumbAsset,
    ].take(8).toList();
    final ready = _name.text.trim().isNotEmpty;
    return Directionality(
      textDirection: _lang.rtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppColors.cream,
        body: ListView(padding: EdgeInsets.zero, children: [
          // ---- header ----
          Container(
            padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 24, 24, 28),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFF8C5A), AppColors.brandDark],
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            child: Column(children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.auto_stories_rounded, color: AppColors.brand, size: 26),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Animal Book AR',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                ),
              ]),
              const SizedBox(height: 24),
              // the books' pictures, a little tilted
              SizedBox(
                height: 150,
                child: Stack(alignment: Alignment.center, children: [
                  for (var i = 0; i < pics.length; i++)
                    Transform.translate(
                      offset: Offset((i % 4 - 1.5) * 74, i < 4 ? -36 : 36),
                      child: FadeSlideIn(
                        delay: Duration(milliseconds: 60 * i),
                        child: Floating(
                          phase: i / 8,
                          amount: 7,
                          child: Transform.rotate(
                            angle: (i.isEven ? -1 : 1) * 0.06,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: const [
                                  BoxShadow(color: Color(0x33000000), blurRadius: 10, offset: Offset(0, 4))
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(13),
                                child: Image.asset(pics[i], width: 64, height: 64, fit: BoxFit.cover),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ]),
              ),
              const SizedBox(height: 20),
              Text(s.welcomeTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: Colors.white)),
              const SizedBox(height: 6),
              Text(s.welcomeSub,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14.5, color: Colors.white.withOpacity(0.92), height: 1.35)),
            ]),
          ),

          // ---- form ----
          FadeSlideIn(
            delay: const Duration(milliseconds: 250),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              child: AppCard(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  _Label(icon: Icons.translate_rounded, text: s.chooseLanguage),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: AppColors.sand, borderRadius: BorderRadius.circular(14)),
                    child: Row(children: [
                      for (final l in Lang.values)
                        Expanded(
                          child: GestureDetector(
                            key: Key('lang-${l.name}'),
                            onTap: () => setState(() => _lang = l),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              decoration: BoxDecoration(
                                color: _lang == l ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(11),
                                boxShadow: _lang == l
                                    ? const [BoxShadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, 2))]
                                    : null,
                              ),
                              child: Text(l.label,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: _lang == l ? AppColors.ink : AppColors.muted)),
                            ),
                          ),
                        ),
                    ]),
                  ),
                  const SizedBox(height: 20),
                  _Label(icon: Icons.child_care_rounded, text: s.yourName),
                  const SizedBox(height: 10),
                  TextField(
                    key: const Key('name'),
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    maxLength: 20,
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _start(),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    decoration: InputDecoration(
                      hintText: s.nameHint,
                      hintStyle: const TextStyle(color: AppColors.faint, fontWeight: FontWeight.w500),
                      counterText: '',
                      filled: true,
                      fillColor: AppColors.cream,
                      prefixIcon: const Icon(Icons.person_rounded, color: AppColors.faint),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.line)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.brand, width: 2)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(s.nameNote, style: const TextStyle(fontSize: 12, color: AppColors.faint)),
                  const SizedBox(height: 20),
                  FilledButton(
                    key: const Key('start'),
                    onPressed: ready ? _start : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.brand,
                      disabledBackgroundColor: AppColors.sand,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(s.letsGo, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                      const SizedBox(width: 8),
                      Icon(_lang.rtl ? Icons.arrow_back_rounded : Icons.arrow_forward_rounded, size: 20),
                    ]),
                  ),
                ]),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.family_restroom_rounded, size: 18, color: AppColors.faint),
              const SizedBox(width: 8),
              Expanded(
                child:
                    Text(s.parentsLater, style: const TextStyle(fontSize: 12.5, color: AppColors.muted, height: 1.4)),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 18, color: AppColors.brand),
      const SizedBox(width: 8),
      Flexible(
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.ink)),
      ),
    ]);
  }
}

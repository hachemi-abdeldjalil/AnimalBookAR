import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'books.dart';
import 'cloud.dart';
import 'l10n.dart';
import 'progress.dart';
import 'screens/bookshelf_screen.dart';
import 'screens/home_screen.dart';
import 'screens/welcome_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final books = await Book.loadAll();
  final progress = await Progress.loadLibrary(books);
  final cloud = await Cloud.start(progress); // null without Firebase: local only
  runApp(AnimalBookApp(progress: progress, cloud: cloud));
}

class AnimalBookApp extends StatelessWidget {
  const AnimalBookApp({super.key, required this.progress, this.cloud});
  final Progress progress;
  final Cloud? cloud;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: progress,
      builder: (context, _) {
        final lang = progress.lang;
        return MaterialApp(
          title: 'Animal Book AR',
          debugShowCheckedModeBanner: false,
          locale: lang.locale,
          supportedLocales: [for (final l in Lang.values) l.locale],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: brand),
            scaffoldBackgroundColor: const Color(0xFFFFF8EF),
            // Tajawal first for Arabic (it has Latin too); Poppins otherwise.
            fontFamily: lang == Lang.ar ? 'Tajawal' : 'Poppins',
            fontFamilyFallback: const ['Poppins', 'Tajawal'],
            useMaterial3: true,
          ),
          home: progress.hasProfile
              ? BookshelfScreen(progress: progress, cloud: cloud)
              : WelcomeScreen(progress: progress),
        );
      },
    );
  }
}

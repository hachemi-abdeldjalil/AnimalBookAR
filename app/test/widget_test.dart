import 'package:animal_book_ar/books.dart';
import 'package:animal_book_ar/main.dart';
import 'package:animal_book_ar/progress.dart';
import 'package:animal_book_ar/screens/animal_sheet.dart';
import 'package:animal_book_ar/screens/bookshelf_screen.dart';
import 'package:animal_book_ar/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<Progress> _progress(WidgetTester tester, Map<String, Object> saved) async {
  SharedPreferences.setMockInitialValues(saved);
  return (await tester.runAsync(() async => Progress.loadLibrary(await Book.loadAll())))!;
}

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300))); // images
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> _openBook(WidgetTester tester, String id) async {
  await tester.tap(find.byKey(Key('book-$id')));
  await _settle(tester);
  await tester.pump(const Duration(milliseconds: 400)); // the page transition
}

void main() {
  testWidgets('first launch asks for a name, then the bookshelf, then the zoo', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final p = await _progress(tester, {});
    await tester.pumpWidget(AnimalBookApp(progress: p));
    await _settle(tester);

    expect(find.text('Welcome!'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('name')), 'Yahia');
    await tester.pump();
    await tester.tap(find.byKey(const Key('start')));
    await _settle(tester);

    expect(find.byType(BookshelfScreen), findsOneWidget);
    expect(find.text('Hello, Yahia'), findsOneWidget);
    await _openBook(tester, 'animals');
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Meet the horse'), findsOneWidget); // the first mission
    expect(find.text('Open your book at page 1'), findsOneWidget);
  });

  testWidgets('home shows the levels, the path and an animal sheet', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 3400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final p = await _progress(tester, {
      'name': 'Yahia',
      'met': [
        'horse',
        'fox',
        'flamingo',
        'parrot',
        'stork',
        'cow',
        'sheep',
        'zebra',
        'llama',
        'dog',
        'lion',
        'elephant',
        'giraffe',
        'camel'
      ],
      'parts': ['fox:head', 'fox:ear'],
    });
    await tester.pumpWidget(AnimalBookApp(progress: p));
    await _settle(tester);
    expect(find.text('14 of 14 animals'), findsWidgets); // the book cover's progress
    await _openBook(tester, 'animals');

    expect(find.text("Find the horse's head"), findsOneWidget); // level 2 mission
    expect(find.text('2 of 122 parts'), findsOneWidget);
    for (final name in [
      'Horse',
      'Fox',
      'Flamingo',
      'Parrot',
      'Stork',
      'Cow',
      'Sheep',
      'Zebra',
      'Llama',
      'Dog',
      'Lion',
      'Elephant',
      'Giraffe',
      'Camel'
    ]) {
      expect(find.text(name), findsOneWidget); // the zoo signs
    }
    expect(find.text('2/9'), findsOneWidget); // fox sign: 2 of 9 parts

    // level 3 is locked
    await tester.tap(find.byKey(const Key('level-3')));
    await tester.pump();
    expect(find.text('Finish level 2 first'), findsOneWidget);

    await tester.tap(find.text('Fox'));
    await _settle(tester);
    expect(find.byType(AnimalSheet), findsOneWidget);
    expect(find.text('2 of 9 found'), findsOneWidget);
    expect(find.text('Head'), findsOneWidget);
    expect(find.text('?'), findsNWidgets(7)); // parts not found yet stay a mystery
  });

  testWidgets('parents page opens after the grown-up check; memory game deals 12 cards', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final p = await _progress(tester, {
      'name': 'Yahia',
      'met': ['fox']
    });
    await tester.pumpWidget(AnimalBookApp(progress: p));
    await _settle(tester);

    await tester.tap(find.byKey(const Key('parents')));
    await _settle(tester);
    final q = tester.widget<Text>(find.textContaining('Grown-ups only')).data!;
    final m = RegExp(r'(\d+) \+ (\d+)').firstMatch(q)!;
    final sum = int.parse(m[1]!) + int.parse(m[2]!);
    await tester.tap(find.byKey(Key('gate-$sum')));
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
    expect(find.text('Parents'), findsOneWidget);
    expect(find.text('1 / 14'), findsOneWidget); // animals met, in "Progress by book"
    await tester.scrollUntilVisible(find.byKey(const Key('add-child')), 300, scrollable: find.byType(Scrollable).first);
    await tester.scrollUntilVisible(find.textContaining('Accounts are not available'), 300,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Accounts are not available right now (no connection).'), findsOneWidget); // no Firebase in tests
    expect(find.text('Yahia'), findsWidgets);

    await tester.pageBack();
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
    await _openBook(tester, 'animals');
    await tester.tap(find.byKey(const Key('game-memory')));
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pump();
    expect(find.byKey(const Key('card-11')), findsOneWidget);
    expect(find.byKey(const Key('card-12')), findsNothing);
  });

  testWidgets('switching to Arabic lays the app out right to left', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final p = await _progress(tester, {'name': 'Yahia', 'lang': 'ar'});
    await tester.pumpWidget(AnimalBookApp(progress: p));
    await _settle(tester);
    await _openBook(tester, 'animals');

    expect(find.text('تعرّف على الحصان'), findsOneWidget);
    expect(Directionality.of(tester.element(find.byKey(const Key('mission')))), TextDirection.rtl);
  });

  testWidgets('the Cars book: town map, its own games, back to the books', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 2200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final p = await _progress(tester, {
      'name': 'Yahia',
      'met': ['horse']
    });
    await tester.pumpWidget(AnimalBookApp(progress: p));
    await _settle(tester);

    expect(find.text('Cars and trucks'), findsOneWidget);
    expect(find.text('0 of 9 vehicles'), findsWidgets);
    await _openBook(tester, 'cars');
    expect(p.book.id, 'cars');
    expect(find.text('Meet the car'), findsOneWidget); // the first mission
    for (final name in [
      'Car',
      'Taxi',
      'Police car',
      'Ambulance',
      'Fire truck',
      'School bus',
      'Tractor',
      'Truck',
      'Motorcycle'
    ]) {
      expect(find.text(name), findsOneWidget); // the town signs
    }
    expect(find.byKey(const Key('game-helps')), findsOneWidget); // "Who helps?"

    await tester.tap(find.byKey(const Key('back-to-books')));
    await _settle(tester);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(BookshelfScreen), findsOneWidget);
  });

  testWidgets('letter books have one level and a Find game; colours mix paints', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final p = await _progress(tester, {'name': 'Yahia'});
    await tester.pumpWidget(AnimalBookApp(progress: p));
    await _settle(tester);

    expect(find.text('Arabic letters'), findsOneWidget);
    expect(find.text('0 of 28 letters'), findsOneWidget);
    await _openBook(tester, 'letters_ar');
    expect(find.text('Learn Alif · Lion'), findsOneWidget); // the first mission
    expect(find.byKey(const Key('level-2')), findsNothing); // one level only
    expect(find.byKey(const Key('game-find')), findsOneWidget);
    expect(find.byKey(const Key('game-sound')), findsNothing);
    expect(p.unlocked(2), isFalse);
    await tester.tap(find.byKey(const Key('back-to-books')));
    await _settle(tester);
    await tester.pump(const Duration(milliseconds: 400));

    await tester.scrollUntilVisible(find.byKey(const Key('book-colors')), 300,
        scrollable: find.byType(Scrollable).first);
    await _openBook(tester, 'colors');
    expect(find.text('Discover red'), findsOneWidget);
    expect(find.text('Shades'), findsOneWidget); // level 2: light, normal and dark
    await tester.tap(find.byKey(const Key('game-mix')));
    await _settle(tester);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byKey(const Key('pot-red')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('pot-yellow')));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Red and yellow make orange!'), findsOneWidget);
  });

  testWidgets('the Algeria book: treasures, details and a Find game', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final p = await _progress(tester, {'name': 'Yahia', 'met': ['dz_flag']});
    await tester.pumpWidget(AnimalBookApp(progress: p));
    await _settle(tester);

    await tester.scrollUntilVisible(find.byKey(const Key('book-algeria')), 300, scrollable: find.byType(Scrollable).first);
    expect(find.text('1 of 12 treasures'), findsWidgets);
    await _openBook(tester, 'algeria');
    expect(find.text('Discover Maqam Echahid'), findsOneWidget); // the flag is met: next is the memorial
    expect(find.text('Details'), findsOneWidget); // level 2
    expect(find.byKey(const Key('game-find')), findsOneWidget);
    expect(find.text('Find the treasure'), findsOneWidget);
  });

  testWidgets('animals: category tags on the card and the Sort game', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final p = await _progress(tester, {'name': 'Yahia', 'met': ['horse']});
    await tester.pumpWidget(AnimalBookApp(progress: p));
    await _settle(tester);
    await _openBook(tester, 'animals');

    await tester.tap(find.text('Horse'));
    await _settle(tester);
    expect(find.text('Lives in: Farm'), findsOneWidget);
    expect(find.text('Farm animal'), findsOneWidget);
    expect(find.text('Eats plants'), findsOneWidget);
    await tester.tapAt(const Offset(200, 40)); // close the sheet
    await _settle(tester);

    await tester.tap(find.byKey(const Key('game-sort')));
    await _settle(tester);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('sort-question')), findsOneWidget);
    expect(find.byKey(const Key('sort-farm')), findsOneWidget); // the first question: where does it live?
  });

  testWidgets('Shapes and Numbers books open on their first page', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 3200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final p = await _progress(tester, {'name': 'Yahia'});
    await tester.pumpWidget(AnimalBookApp(progress: p));
    await _settle(tester);

    expect(find.text('0 of 10 shapes'), findsWidgets);
    await tester.scrollUntilVisible(find.byKey(const Key('book-shapes')), 300, scrollable: find.byType(Scrollable).first);
    await _openBook(tester, 'shapes');
    expect(find.text('Learn the circle'), findsOneWidget);
    expect(find.text('Find the shape'), findsOneWidget);
    await tester.tap(find.byKey(const Key('back-to-books')));
    await _settle(tester);
    await tester.pump(const Duration(milliseconds: 400));

    await tester.scrollUntilVisible(find.byKey(const Key('book-numbers')), 300, scrollable: find.byType(Scrollable).first);
    await _openBook(tester, 'numbers');
    expect(find.text('Learn 1 · One'), findsOneWidget);
    expect(find.text('Find the number'), findsOneWidget);
  });
}

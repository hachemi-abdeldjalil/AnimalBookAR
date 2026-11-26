import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'animals.dart';
import 'books.dart';
import 'l10n.dart';

/// The three levels: 1 meet every animal, 2 find every body part,
/// 3 answer [quizGoal] quiz questions per animal. A level unlocks when the
/// one before is done. Stars: one per animal met, part found, quiz answer,
/// right food, memory game won and sound-quiz answer.
const quizGoal = 3;

/// What the home screen tells the child to do next.
class Mission {
  const Mission({required this.level, required this.animal, this.part});
  final int level; // 1..3, or 4 when everything is done
  final Animal? animal;
  final BodyPart? part;
  bool get quiz => level == 3;
}

/// One child's progress. Also the shape synced to the cloud
/// (users/{uid}/children/{id}); [merge] combines two copies without losing
/// anything (sets are joined, counters take the larger value).
class ChildData {
  ChildData({
    required this.id,
    required this.name,
    Set<String>? met,
    Set<String>? parts,
    Map<String, int>? quiz,
    Set<String>? food,
    this.memoryWins = 0,
    this.soundCorrect = 0,
    this.playSeconds = 0,
    this.updatedAt = 0,
  })  : met = met ?? {},
        parts = parts ?? {},
        quiz = quiz ?? {},
        food = food ?? {};

  final String id;
  String name;
  final Set<String> met;
  final Set<String> parts; // "fox:tail"
  final Map<String, int> quiz; // "fox" -> right answers (max quizGoal)
  final Set<String> food; // "fox:mouse"
  int memoryWins;
  int soundCorrect;
  int playSeconds;
  int updatedAt; // ms since epoch, for picking the newer name

  bool get isEmpty => met.isEmpty && parts.isEmpty && quiz.isEmpty && food.isEmpty && memoryWins == 0;

  Map<String, Object?> toJson() => {
        'name': name,
        'met': met.toList()..sort(),
        'parts': parts.toList()..sort(),
        'quiz': quiz,
        'food': food.toList()..sort(),
        'memoryWins': memoryWins,
        'soundCorrect': soundCorrect,
        'playSeconds': playSeconds,
        'updatedAt': updatedAt,
      };

  factory ChildData.fromJson(String id, Map<String, dynamic> j) => ChildData(
        id: id,
        name: (j['name'] as String?) ?? '',
        met: {for (final e in (j['met'] as List?) ?? const []) e as String},
        parts: {for (final e in (j['parts'] as List?) ?? const []) e as String},
        quiz: {for (final e in ((j['quiz'] as Map?) ?? const {}).entries) e.key as String: (e.value as num).toInt()},
        food: {for (final e in (j['food'] as List?) ?? const []) e as String},
        memoryWins: (j['memoryWins'] as num?)?.toInt() ?? 0,
        soundCorrect: (j['soundCorrect'] as num?)?.toInt() ?? 0,
        playSeconds: (j['playSeconds'] as num?)?.toInt() ?? 0,
        updatedAt: (j['updatedAt'] as num?)?.toInt() ?? 0,
      );

  /// Adds [other] into this one. Returns true if anything changed.
  bool merge(ChildData other) {
    final before = jsonEncode(toJson());
    met.addAll(other.met);
    parts.addAll(other.parts);
    food.addAll(other.food);
    for (final e in other.quiz.entries) {
      quiz[e.key] = max(quiz[e.key] ?? 0, e.value);
    }
    memoryWins = max(memoryWins, other.memoryWins);
    soundCorrect = max(soundCorrect, other.soundCorrect);
    playSeconds = max(playSeconds, other.playSeconds);
    if (other.updatedAt > updatedAt && other.name.isNotEmpty) name = other.name;
    updatedAt = max(updatedAt, other.updatedAt);
    return jsonEncode(toJson()) != before;
  }
}

/// The family on this phone: its children and the language. Everything is
/// saved on the phone (shared_preferences); with a parent account the cloud
/// sync (lib/cloud.dart) keeps it in step with other devices. The getters
/// below read the active child.
class Progress extends ChangeNotifier {
  Progress(SharedPreferences prefs, List<Animal> animals) : this.library(prefs, [Book.animalsOnly(animals)]);

  Progress.library(this._prefs, this.books) : lang = Lang.parse(_prefs.getString('lang')) {
    _bookId = _prefs.getString('book');
    _load();
  }

  static Future<Progress> load(List<Animal> animals) async => Progress(await SharedPreferences.getInstance(), animals);
  static Future<Progress> loadLibrary(List<Book> books) async =>
      Progress.library(await SharedPreferences.getInstance(), books);

  final SharedPreferences _prefs;

  /// The library and the open book: levels, missions and the map follow it.
  final List<Book> books;
  String? _bookId;
  Book get book => books.firstWhere((b) => b.id == _bookId, orElse: () => books.first);
  List<Animal> get animals => book.items;

  void openBook(String id) {
    _bookId = id;
    _prefs.setString('book', id);
    notifyListeners();
  }

  /// A book's level, mission and counts, for any book (not only the open one):
  /// the child's profile lists them all.
  (int done, int total) levelCountIn(Book b, int level) => switch (level) {
        1 => (metIn(b), b.items.length),
        2 => (partsIn(b), totalPartsIn(b)),
        _ => (quizIn(b), b.items.length * quizGoal),
      };
  bool levelDoneIn(Book b, int level) {
    final (done, total) = levelCountIn(b, level);
    return done >= total;
  }

  int currentLevelIn(Book b) =>
      [for (var l = 1; l <= b.levels; l++) l].firstWhere((l) => !levelDoneIn(b, l), orElse: () => 4);
  Mission missionIn(Book b) {
    final level = currentLevelIn(b);
    if (level == 4) return const Mission(level: 4, animal: null);
    bool done(Animal a) => switch (level) {
          1 => met(a.id),
          2 => partsFound(a) == a.parts.length,
          _ => quizScore(a.id) >= quizGoal,
        };
    final animal = b.items.firstWhere((a) => !done(a));
    final part = level == 2 ? animal.parts.firstWhere((p) => !partFound(animal.id, p.id)) : null;
    return Mission(level: level, animal: animal, part: part);
  }

  /// The child's picture: an item's sticker they chose (kept on this phone), or null for their initial.
  String? avatarOf(String childId) => _prefs.getString('avatar.$childId');
  void setAvatar(String childId, String? asset) {
    if (asset == null) {
      _prefs.remove('avatar.$childId');
    } else {
      _prefs.setString('avatar.$childId', asset);
    }
    notifyListeners();
  }

  /// Per-book numbers for the parents' page.
  int partsIn(Book b) => children.isEmpty
      ? 0
      : b.items.fold(0, (n, a) => n + a.parts.where((p) => child.parts.contains('${a.id}:${p.id}')).length);
  int totalPartsIn(Book b) => b.items.fold(0, (n, a) => n + a.parts.length);
  int quizIn(Book b) => children.isEmpty ? 0 : b.items.fold(0, (n, a) => n + (child.quiz[a.id] ?? 0));

  /// Everything met, across all the books.
  int get metAll => books.fold(0, (n, b) => n + metIn(b));

  /// Items met in a book, for the bookshelf.
  int metIn(Book b) => b.items.where((a) => met(a.id)).length;
  Lang lang;
  final List<ChildData> children = [];
  String? _activeId;

  /// Set by the cloud sync: called when a child's data changed on this phone.
  void Function(ChildData child)? onChildChanged;
  void Function(String childId)? onChildDeleted;

  /// The active child; an unnamed one is created the first time it's needed.
  ChildData get child {
    if (children.isEmpty) addChild('', silent: true);
    return children.firstWhere((c) => c.id == _activeId, orElse: () => children.first);
  }

  String get name => children.isEmpty ? '' : child.name;
  bool get hasProfile => children.isNotEmpty && name.trim().isNotEmpty;
  S get s => S(lang);

  // ---- reading (the active child) ----
  bool met(String animal) => child.met.contains(animal);
  bool partFound(String animal, String part) => child.parts.contains('$animal:$part');
  int partsFound(Animal a) => a.parts.where((p) => partFound(a.id, p.id)).length;
  int quizScore(String animal) => child.quiz[animal] ?? 0;
  bool fed(String animal, String food) => child.food.contains('$animal:$food');

  int get totalParts => animals.fold(0, (n, a) => n + a.parts.length);
  int get partsTotalFound => animals.fold(0, (n, a) => n + partsFound(a));
  int get metCount => animals.where((a) => met(a.id)).length;
  int get quizTotal => animals.fold(0, (n, a) => n + quizScore(a.id));
  int starsOf(ChildData c) =>
      c.met.length +
      c.parts.length +
      c.quiz.values.fold<int>(0, (n, v) => n + v) +
      c.food.length +
      c.memoryWins +
      c.soundCorrect;
  int get stars => children.isEmpty ? 0 : starsOf(child);

  /// Words learned: animal names met plus body parts found (each in 3 languages).
  int get wordsLearned => children.isEmpty ? 0 : child.met.length + child.parts.length;

  (int done, int total) levelCount(int level) => switch (level) {
        1 => (metCount, animals.length),
        2 => (partsTotalFound, totalParts),
        _ => (quizTotal, animals.length * quizGoal),
      };
  bool levelDone(int level) {
    final (done, total) = levelCount(level);
    return done >= total;
  }

  bool unlocked(int level) => level == 1 || (level <= book.levels && levelDone(level - 1));

  /// The book's levels: 1 (meet) for the letter books, else 3.
  List<int> get levels => [for (var l = 1; l <= book.levels; l++) l];

  /// The first level not finished yet; 4 when all are done.
  int get currentLevel => levels.firstWhere((l) => !levelDone(l), orElse: () => 4);

  /// Is this animal finished for this level?
  bool animalDone(Animal a, int level) => switch (level) {
        1 => met(a.id),
        2 => partsFound(a) == a.parts.length,
        _ => quizScore(a.id) >= quizGoal,
      };

  Mission get mission {
    final level = currentLevel;
    if (level == 4) return const Mission(level: 4, animal: null);
    final animal = animals.firstWhere((a) => !animalDone(a, level));
    final part = level == 2 ? animal.parts.firstWhere((p) => !partFound(animal.id, p.id)) : null;
    return Mission(level: level, animal: animal, part: part);
  }

  // ---- writing (called from the AR screen and games) ----
  /// Returns what the AR page shows: is it new, the stars, a newly unlocked level.
  Map<String, Object?> markMet(String animal) => _change(() => child.met.add(animal));
  Map<String, Object?> markPart(String animal, String part) => _change(() => child.parts.add('$animal:$part'));
  Map<String, Object?> markFood(String animal, String food) => _change(() => child.food.add('$animal:$food'));
  Map<String, Object?> markQuiz(String animal) => _change(() {
        final n = quizScore(animal);
        if (n >= quizGoal) return false;
        child.quiz[animal] = n + 1;
        return true;
      });
  Map<String, Object?> markSoundQuiz() => _change(() {
        child.soundCorrect++;
        return true;
      });
  Map<String, Object?> markMemoryWin() => _change(() {
        child.memoryWins++;
        return true;
      });

  void addPlayTime(Duration d) {
    if (children.isEmpty || d.inSeconds <= 0) return;
    child.playSeconds += d.inSeconds;
    _saveChild(child);
    notifyListeners();
  }

  Map<String, Object?> _change(bool Function() apply) {
    final levelBefore = currentLevel;
    final isNew = apply();
    if (isNew) {
      _saveChild(child);
      notifyListeners();
    }
    final levelAfter = currentLevel;
    return {
      'new': isNew,
      'stars': stars,
      'levelUp': levelAfter > levelBefore ? levelAfter : null, // 4 = everything done
    };
  }

  // ---- family ----
  /// First launch: the first child's name and the language.
  Future<void> setProfile({required String name, required Lang lang}) async {
    this.lang = lang;
    await _prefs.setString('lang', lang.name);
    if (children.isEmpty) {
      addChild(name);
    } else {
      renameChild(child.id, name);
    }
  }

  Future<void> setLang(Lang lang) async {
    this.lang = lang;
    await _prefs.setString('lang', lang.name);
    notifyListeners();
  }

  ChildData addChild(String name, {String? id, bool silent = false}) {
    final c = ChildData(id: id ?? _newId(), name: name.trim(), updatedAt: _now());
    children.add(c);
    _activeId = c.id;
    _saveChild(c);
    _saveFamily();
    if (!silent) notifyListeners();
    return c;
  }

  void switchChild(String id) {
    if (!children.any((c) => c.id == id)) return;
    _activeId = id;
    _saveFamily();
    notifyListeners();
  }

  void renameChild(String id, String name) {
    final c = children.firstWhere((c) => c.id == id);
    c.name = name.trim();
    c.updatedAt = _now();
    _saveChild(c);
    notifyListeners();
  }

  void deleteChild(String id) {
    if (children.length <= 1) return; // keep at least one
    children.removeWhere((c) => c.id == id);
    _prefs.remove('child.$id');
    if (_activeId == id) _activeId = children.first.id;
    _saveFamily();
    onChildDeleted?.call(id);
    notifyListeners();
  }

  void resetChild(String id) {
    final i = children.indexWhere((c) => c.id == id);
    if (i < 0) return;
    // Sync merges by union, so a reset stays local unless the cloud copy is replaced too.
    final c = ChildData(id: id, name: children[i].name, updatedAt: _now());
    children[i] = c;
    _saveChild(c, force: true);
    notifyListeners();
  }

  /// A child's data arrived from the cloud: merge it in (or add the child).
  void applyRemote(ChildData remote) {
    final i = children.indexWhere((c) => c.id == remote.id);
    if (i < 0) {
      children.add(remote);
      _activeId ??= remote.id;
      _saveChild(remote, notify: false);
      _saveFamily();
    } else if (children[i].merge(remote)) {
      _saveChild(children[i], notify: false);
    }
    notifyListeners();
  }

  /// After the first sync on a new phone: drop a local child that never
  /// played if the account already has children.
  void dropEmptyLocalChildren(Set<String> remoteIds) {
    final empty = children.where((c) => !remoteIds.contains(c.id) && c.isEmpty).toList();
    if (empty.length == children.length) return;
    for (final c in empty) {
      children.remove(c);
      _prefs.remove('child.${c.id}');
      if (_activeId == c.id) _activeId = children.first.id;
    }
    if (empty.isNotEmpty) {
      _saveFamily();
      notifyListeners();
    }
  }

  // ---- storage ----
  void _load() {
    final ids = _prefs.getStringList('children');
    if (ids == null) {
      _migrateSingleProfile();
    } else {
      for (final id in ids) {
        final raw = _prefs.getString('child.$id');
        if (raw != null) children.add(ChildData.fromJson(id, jsonDecode(raw) as Map<String, dynamic>));
      }
      _activeId = _prefs.getString('active');
    }
  }

  /// Version 1 kept one child under flat keys (name, met, parts, quiz, food).
  void _migrateSingleProfile() {
    final name = _prefs.getString('name');
    if (name == null || name.isEmpty) return;
    final c = ChildData(
      id: _newId(),
      name: name,
      met: (_prefs.getStringList('met') ?? const []).toSet(),
      parts: (_prefs.getStringList('parts') ?? const []).toSet(),
      food: (_prefs.getStringList('food') ?? const []).toSet(),
      quiz: {
        for (final e in _prefs.getStringList('quiz') ?? const <String>[])
          if (e.contains('=')) e.split('=').first: int.tryParse(e.split('=').last) ?? 0,
      },
      updatedAt: _now(),
    );
    children.add(c);
    _activeId = c.id;
    _saveChild(c, notify: false);
    _saveFamily();
    for (final k in ['name', 'met', 'parts', 'food', 'quiz']) {
      _prefs.remove(k);
    }
  }

  void _saveChild(ChildData c, {bool notify = true, bool force = false}) {
    c.updatedAt = max(c.updatedAt, _now());
    _prefs.setString('child.${c.id}', jsonEncode(c.toJson()));
    if (notify) onChildChanged?.call(c);
  }

  void _saveFamily() {
    _prefs.setStringList('children', [for (final c in children) c.id]);
    if (_activeId != null) _prefs.setString('active', _activeId!);
  }

  static int _now() => DateTime.now().millisecondsSinceEpoch;
  static String _newId() {
    final r = Random.secure();
    return List.generate(12, (_) => 'abcdefghijkmnpqrstuvwxyz23456789'[r.nextInt(32)]).join();
  }

  @visibleForTesting
  Future<void> resetAll() async {
    children.clear();
    _activeId = null;
    await _prefs.clear();
    notifyListeners();
  }
}

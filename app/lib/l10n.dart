import 'package:flutter/widgets.dart';

import 'animals.dart';

/// The app's languages. Animal and body-part names always come in all three.
enum Lang {
  en('EN', 'English'),
  fr('FR', 'Français'),
  ar('ع', 'العربية');

  const Lang(this.short, this.label);
  final String short;
  final String label;

  Locale get locale => Locale(name);
  bool get rtl => this == Lang.ar;

  static Lang parse(String? s) => Lang.values.firstWhere((l) => l.name == s, orElse: () => Lang.en);
}

/// UI text. Kept in one place so a translator can check it easily.
class S {
  const S(this.lang);
  final Lang lang;

  String _t(String en, String fr, String ar) => switch (lang) { Lang.en => en, Lang.fr => fr, Lang.ar => ar };

  String get appTitle => _t('Animal Book', 'Le livre des animaux', 'كتاب الحيوانات');
  String hello(String name) => _t('Hello, $name', 'Bonjour, $name', 'مرحبًا يا $name');
  String get explorer => _t('explorer', 'explorateur', 'مستكشف');
  String get nextMission => _t('Next mission', 'Prochaine mission', 'المهمة التالية');
  String get go => _t('Go', 'Go', 'هيا');
  String get scanBook => _t('Scan your book', 'Scanner ton livre', 'امسح كتابك');
  String get language => _t('Language', 'Langue', 'اللغة');
  String get zoo => _t('ZOO', 'ZOO', 'حديقة الحيوانات');

  String levelName(int level, {String kind = 'animals'}) => switch (level) {
        1 => _t('Meet', 'Découvrir', 'تعرّف'),
        2 => partsTitle(kind),
        _ => _t('Quiz', 'Quiz', 'اختبار'),
      };
  String levelTitle(int level) => _t('Level $level', 'Niveau $level', 'المستوى $level');
  String finishFirst(int level) =>
      _t('Finish level $level first', 'Termine d\'abord le niveau $level', 'أكمل المستوى $level أولًا');
  String levelProgress(int level, int done, int total, {String kind = 'animals'}) => switch (level) {
        1 => metOf(kind, done, total),
        2 => _t('$done of $total parts', '$done sur $total parties', '$done من $total أجزاء'),
        _ => _t('$done of $total answers', '$done sur $total réponses', '$done من $total إجابات'),
      };

  // Missions
  String meet(Animal a, {String kind = 'animals'}) => switch (kind) {
        'letters' => _t('Learn ${a.en}', 'Apprends ${a.fr}', 'تعلّم ${a.ar}'),
        'colors' => _t('Discover ${a.en.toLowerCase()}', 'Découvre ${a.frDef}', 'تعرّف على ${a.arDef}'),
        'heritage' => _t('Discover ${a.en}', 'Découvre ${a.frDef}', 'تعرّف على ${a.arDef}'),
        'shapes' => _t('Learn the ${a.en.toLowerCase()}', 'Apprends ${a.frDef}', 'تعلّم ${a.arDef}'),
        'numbers' => _t('Learn ${a.en}', 'Apprends ${a.fr}', 'تعلّم ${a.ar}'),
        _ => _t('Meet the ${a.en.toLowerCase()}', 'Découvre ${a.frDef}', 'تعرّف على ${a.arDef}'),
      };
  String findPart(Animal a, BodyPart p, {String kind = 'animals'}) => kind == 'heritage'
      ? _t('${a.en}: find the ${p.en.toLowerCase()}', 'Trouve ${p.frDef} ${a.frOf}', 'ابحث عن ${p.ar} في ${a.arDef}')
      : kind == 'colors'
          ? _t('Find ${p.en.toLowerCase()}', 'Trouve ${p.frDef}', 'ابحث عن ${p.ar}')
          : _t('Find the ${a.en.toLowerCase()}\'s ${p.en.toLowerCase()}', 'Trouve ${p.frDef} ${a.frOf}',
              'ابحث عن ${p.ar} ${a.arDef}');
  String partsTitle(String kind) => switch (kind) {
        'vehicles' => _t('Parts', 'Les pièces', 'الأجزاء'),
        'colors' => _t('Shades', 'Les nuances', 'الدرجات'),
        'heritage' => _t('Details', 'Les détails', 'التفاصيل'),
        _ => _t('Body parts', 'Le corps', 'أجزاء الجسم'),
      };
  String quizOf(Animal a) => _t('${a.en} quiz', 'Quiz ${a.frOf}', 'اختبار ${a.arDef}');
  String openPage(int page) =>
      _t('Open your book at page $page', 'Ouvre ton livre à la page $page', 'افتح كتابك على الصفحة $page');
  String get answer3 => _t('Answer 3 questions', 'Réponds à 3 questions', 'أجب عن 3 أسئلة');
  String get allDone => _t('You did it!', 'Bravo, tout est fini !', 'أحسنت! أكملت كل شيء');
  String get playAgain => _t('Play again any time', 'Rejoue quand tu veux', 'العب مرة أخرى متى شئت');

  // Animal sheet
  String get bodyParts => _t('Body parts', 'Les parties du corps', 'أجزاء الجسم');
  String found(int done, int total) => _t('$done of $total found', '$done sur $total trouvées', 'وجدت $done من $total');
  String page(int n) => _t('Page $n', 'Page $n', 'الصفحة $n');
  String get showPage => _t('Show page', 'Voir la page', 'عرض الصفحة');
  String get scan => _t('Scan', 'Scanner', 'امسح');
  String get startQuiz => _t('Start quiz', 'Faire le quiz', 'ابدأ الاختبار');
  String quizScore(int n) => _t('Quiz: $n of 3', 'Quiz : $n sur 3', 'الاختبار: $n من 3');
  String get notMet =>
      _t('Not met yet: scan its page', 'Pas encore découvert : scanne sa page', 'لم تتعرف عليه بعد: امسح صفحته');
  String get showPageHint => _t(
      'Point another phone with Animal Book AR at this page, or print the book.',
      'Pointe un autre téléphone avec Animal Book AR vers cette page, ou imprime le livre.',
      'وجّه هاتفًا آخر فيه التطبيق نحو هذه الصفحة، أو اطبع الكتاب.');

  // Welcome
  String get welcomeTitle => _t('Welcome!', 'Bienvenue !', 'مرحبًا بك!');
  String get welcomeSub => _t(
      'Books that come alive: animals, vehicles, letters and colours in 3D.',
      'Des livres qui prennent vie : animaux, véhicules, lettres et couleurs en 3D.',
      'كتب تنبض بالحياة: حيوانات ومركبات وحروف وألوان بالأبعاد الثلاثة.');
  String get nameNote => _t('Only a first name. It stays on this phone.',
      'Seulement un prénom. Il reste sur ce téléphone.', 'الاسم الأول فقط، ويبقى على هذا الهاتف.');
  String get parentsLater => _t(
      'Parents can sign in later, from the parents\' area, to sync between devices.',
      'Les parents pourront se connecter plus tard, dans l\'espace parents, pour synchroniser.',
      'يمكن للأولياء تسجيل الدخول لاحقًا من فضاء الأولياء للمزامنة بين الأجهزة.');
  String get continueLearning => _t('Continue', 'Continuer', 'تابع');
  String get statStars => _t('Stars', 'Étoiles', 'نجوم');
  String get statDiscovered => _t('Discovered', 'Découverts', 'اكتشفها');
  String get statMinutes => _t('Minutes played', 'Minutes de jeu', 'دقائق اللعب');
  String get overview => _t('Overview', 'Vue d\'ensemble', 'نظرة عامة');
  String get byBook => _t('Progress by book', 'Progression par livre', 'التقدّم حسب الكتاب');
  String get activity => _t('Activity', 'Activité', 'النشاط');
  String get settings => _t('Settings', 'Réglages', 'الإعدادات');
  String get appLanguage => _t('App language', 'Langue de l\'appli', 'لغة التطبيق');
  String get notSignedIn => _t('Not signed in · progress stays on this phone',
      'Non connecté · la progression reste sur ce téléphone', 'غير مسجّل · يبقى التقدّم على هذا الهاتف');
  String partsQuiz(int p, int pt, int q, int qt) =>
      _t('Parts $p/$pt · Quiz $q/$qt', 'Parties $p/$pt · Quiz $q/$qt', 'أجزاء $p/$pt · اختبار $q/$qt');
  String get gateTitle => _t('Grown-ups only', 'Réservé aux adultes', 'للكبار فقط');
  String get chooseLanguage => _t('Choose your language', 'Choisis ta langue', 'اختر لغتك');
  String get yourName => _t('What\'s your name?', 'Comment t\'appelles-tu ?', 'ما اسمك؟');
  String get nameHint => _t('Your first name', 'Ton prénom', 'اسمك');
  String get letsGo => _t('Let\'s go', 'C\'est parti', 'هيا بنا');

  // AR screen
  String get needCamera => _t('Animal Book AR needs the camera to see the book.',
      'Animal Book AR a besoin de la caméra pour voir le livre.', 'يحتاج التطبيق إلى الكاميرا لرؤية الكتاب.');
  String get tryAgain => _t('Try again', 'Réessayer', 'حاول مرة أخرى');
  String get openSettings => _t('Open settings', 'Ouvrir les réglages', 'فتح الإعدادات');
  String get back => _t('Back', 'Retour', 'رجوع');

  // Parents' page
  String get parents => _t('Parents', 'Parents', 'الأولياء');
  String get forParents => _t('For parents', 'Pour les parents', 'للأولياء');
  String gateQuestion(int a, int b) =>
      _t('Grown-ups only: $a + $b = ?', 'Réservé aux adultes : $a + $b = ?', 'للكبار فقط: $a + $b = ؟');
  String get account => _t('Account', 'Compte', 'الحساب');
  String get syncPitch => _t(
      'Sign in to keep progress safe and use it on several phones or tablets.',
      'Connectez-vous pour sauvegarder la progression et l\'utiliser sur plusieurs appareils.',
      'سجّل الدخول لحفظ التقدّم واستخدامه على عدة أجهزة.');
  String get continueGoogle => _t('Continue with Google', 'Continuer avec Google', 'المتابعة باستخدام Google');
  String get useEmail => _t('Use an email', 'Utiliser un e-mail', 'استخدام بريد إلكتروني');
  String get email => _t('Email', 'E-mail', 'البريد الإلكتروني');
  String get password =>
      _t('Password (6+ characters)', 'Mot de passe (6 caractères min.)', 'كلمة المرور (6 أحرف على الأقل)');
  String get signIn => _t('Sign in', 'Se connecter', 'تسجيل الدخول');
  String get createAccount => _t('Create account', 'Créer un compte', 'إنشاء حساب');
  String get forgotPassword => _t('Forgot password?', 'Mot de passe oublié ?', 'نسيت كلمة المرور؟');
  String get resetSent => _t('Check your email to reset the password.',
      'Vérifiez vos e-mails pour réinitialiser le mot de passe.', 'تفقّد بريدك لإعادة تعيين كلمة المرور.');
  String signedInAs(String who) => _t('Signed in as $who', 'Connecté : $who', 'تم تسجيل الدخول: $who');
  String get synced => _t('Progress is synced', 'Progression synchronisée', 'تمت مزامنة التقدّم');
  String get syncingNow => _t('Syncing…', 'Synchronisation…', 'جارٍ المزامنة…');
  String get signOut => _t('Sign out', 'Se déconnecter', 'تسجيل الخروج');
  String get cloudOff => _t(
      'Accounts are not available right now (no connection).',
      'Les comptes ne sont pas disponibles pour le moment (pas de connexion).',
      'الحسابات غير متاحة حاليًا (لا يوجد اتصال).');
  String authError(String code) => switch (code) {
        'invalid-email' =>
          _t('That email address is not valid.', 'Cette adresse e-mail n\'est pas valide.', 'عنوان البريد غير صالح.'),
        'user-not-found' ||
        'wrong-password' ||
        'invalid-credential' =>
          _t('Wrong email or password.', 'E-mail ou mot de passe incorrect.', 'البريد أو كلمة المرور غير صحيحة.'),
        'email-already-in-use' => _t('An account already uses this email. Sign in instead.',
            'Un compte utilise déjà cet e-mail. Connectez-vous.', 'هذا البريد مستخدم. سجّل الدخول بدلًا من ذلك.'),
        'weak-password' =>
          _t('Choose a longer password.', 'Choisissez un mot de passe plus long.', 'اختر كلمة مرور أطول.'),
        'network-request-failed' =>
          _t('No internet connection.', 'Pas de connexion Internet.', 'لا يوجد اتصال بالإنترنت.'),
        _ => _t('That didn\'t work. Try again.', 'Ça n\'a pas marché. Réessayez.', 'لم ينجح ذلك. حاول مرة أخرى.'),
      };
  String get children => _t('Children', 'Enfants', 'الأطفال');
  String get addChild => _t('Add a child', 'Ajouter un enfant', 'إضافة طفل');
  String get rename => _t('Rename', 'Renommer', 'إعادة التسمية');
  String get resetProgress => _t('Start over', 'Recommencer', 'البدء من جديد');
  String get delete => _t('Delete', 'Supprimer', 'حذف');
  String get cancel => _t('Cancel', 'Annuler', 'إلغاء');
  String get save => _t('Save', 'Enregistrer', 'حفظ');
  String confirmDelete(String name) =>
      _t('Delete $name and all their progress?', 'Supprimer $name et toute sa progression ?', 'حذف $name وكل تقدّمه؟');
  String confirmReset(String name) => _t('Erase all of $name\'s progress on this phone?',
      'Effacer toute la progression de $name sur ce téléphone ?', 'مسح كل تقدّم $name على هذا الهاتف؟');
  String progressOf(String name) => _t('$name\'s progress', 'Progression de $name', 'تقدّم $name');
  String get statAnimals => _t('Animals met', 'Animaux découverts', 'حيوانات تعرّف عليها');
  String get statParts => _t('Body parts found', 'Parties du corps trouvées', 'أجزاء جسم وجدها');
  String get statQuiz => _t('Quiz answers', 'Réponses au quiz', 'إجابات الاختبار');
  String get statWords => _t('Words learned (×3 languages)', 'Mots appris (×3 langues)', 'كلمات تعلّمها (×3 لغات)');
  String get statFood => _t('Foods given', 'Aliments donnés', 'أطعمة قدّمها');
  String get statGames => _t('Games won', 'Jeux gagnés', 'ألعاب فاز بها');
  String get statTime => _t('Time in the camera', 'Temps avec la caméra', 'الوقت مع الكاميرا');
  String minutes(int m) => _t('$m min', '$m min', '$m دقيقة');

  // Bookshelf
  String get yourBooks => _t('Your books', 'Tes livres', 'كتبك');
  String get comingSoon => _t('Coming soon', 'Bientôt', 'قريبًا');
  String get lettersBook => _t('Letters', 'Les lettres', 'الحروف');
  String get heritageBook => _t('Algeria', 'L\'Algérie', 'الجزائر');
  String metOf(String kind, int done, int total) => switch (kind) {
        'vehicles' => _t('$done of $total vehicles', '$done sur $total véhicules', '$done من $total مركبات'),
        'letters' => _t('$done of $total letters', '$done sur $total lettres', '$done من $total حروف'),
        'colors' => _t('$done of $total colours', '$done sur $total couleurs', '$done من $total ألوان'),
        'heritage' => _t('$done of $total treasures', '$done sur $total trésors', '$done من $total كنوز'),
        'shapes' => _t('$done of $total shapes', '$done sur $total formes', '$done من $total أشكال'),
        'numbers' => _t('$done of $total numbers', '$done sur $total nombres', '$done من $total أعداد'),
        _ => _t('$done of $total animals', '$done sur $total animaux', '$done من $total حيوانات'),
      };
  String statMet(String kind) => switch (kind) {
        'vehicles' => statVehicles,
        'letters' => _t('Letters learned', 'Lettres apprises', 'حروف تعلّمها'),
        'colors' => _t('Colours met', 'Couleurs découvertes', 'ألوان تعرّف عليها'),
        'heritage' => _t('Treasures discovered', 'Trésors découverts', 'كنوز اكتشفها'),
        'shapes' => _t('Shapes learned', 'Formes apprises', 'أشكال تعلّمها'),
        'numbers' => _t('Numbers learned', 'Nombres appris', 'أعداد تعلّمها'),
        _ => statAnimals,
      };
  String findGame(String kind) => switch (kind) {
        'colors' => _t('Find the colour', 'Trouve la couleur', 'ابحث عن اللون'),
        'heritage' => _t('Find the treasure', 'Trouve le trésor', 'ابحث عن الكنز'),
        'shapes' => _t('Find the shape', 'Trouve la forme', 'ابحث عن الشكل'),
        'numbers' => _t('Find the number', 'Trouve le nombre', 'ابحث عن العدد'),
        _ => _t('Find the letter', 'Trouve la lettre', 'ابحث عن الحرف'),
      };
  String get findHint =>
      _t('Listen, then scan the right page', 'Écoute, puis scanne la bonne page', 'استمع ثم امسح الصفحة الصحيحة');
  // The child's own page
  String get myPage => _t('My page', 'Ma page', 'صفحتي');
  String get whatIDid => _t('What I did', "Ce que j'ai fait", 'ما أنجزته');
  String get whatNext => _t("What's next", 'À faire ensuite', 'ما سأفعله بعد ذلك');
  String get myBadges => _t('My medals', 'Mes médailles', 'ميدالياتي');
  String get myPicture => _t('My picture', 'Mon image', 'صورتي');
  String get myName => _t('My name', 'Mon prénom', 'اسمي');
  String get finishedBook => _t('Finished!', 'Terminé !', 'أكملته!');
  String get letsPlay => _t('Play', 'Jouer', 'العب');
  String get initialPicture => _t('My letter', 'Mon initiale', 'حرفي');
  String levelOf(int level, int total) =>
      _t('Level $level of $total', 'Niveau $level sur $total', 'المستوى $level من $total');

  // What each level asks
  String itemsNoun(String kind) => switch (kind) {
        'vehicles' => _t('vehicles', 'véhicules', 'المركبات'),
        'letters' => _t('letters', 'lettres', 'الحروف'),
        'colors' => _t('colours', 'couleurs', 'الألوان'),
        'heritage' => _t('treasures', 'trésors', 'الكنوز'),
        'shapes' => _t('shapes', 'formes', 'الأشكال'),
        'numbers' => _t('numbers', 'nombres', 'الأعداد'),
        _ => _t('animals', 'animaux', 'الحيوانات'),
      };
  String levelGoal(int level, String kind, int total) => switch (level) {
        1 => _t(
            'Scan each page of your book to meet all $total ${itemsNoun(kind)}.',
            'Scanne chaque page de ton livre pour découvrir les $total ${itemsNoun(kind)}.',
            'امسح كل صفحة من كتابك لتتعرّف على كل ${itemsNoun(kind)} ($total).'),
        2 => _t(
            'Aim the ◎ at each one to find all the ${partsTitle(kind).toLowerCase()}.',
            'Vise ◎ chaque partie pour trouver tout : ${partsTitle(kind).toLowerCase()}.',
            'صوّب ◎ نحو كل واحد لتجد كل ${partsTitle(kind)}.'),
        _ => _t(
            'Answer 3 questions for each one: find the part I name.',
            'Réponds à 3 questions pour chacun : trouve la partie que je nomme.',
            'أجب عن 3 أسئلة لكل واحد: اعثر على الجزء الذي أسمّيه.'),
      };
  String nextLevel(int level, String name) => _t(
      'Next: level $level, $name. It opens when this level is done.',
      'Ensuite : niveau $level, $name. Il s\'ouvre quand ce niveau est fini.',
      'التالي: المستوى $level، $name. يُفتح عندما تُكمل هذا المستوى.');
  String partsLocked(String kind) => _t(
      '${partsTitle(kind)}: open at level 2', '${partsTitle(kind)} : au niveau 2', '${partsTitle(kind)}: في المستوى 2');
  String levelStep(int level) => _t('Step $level', 'Étape $level', 'الخطوة $level');

  // Animal categories
  String category(String id) => switch (id) {
        'farm' => _t('Farm animal', 'Animal de la ferme', 'حيوان المزرعة'),
        'pet' => _t('Pet', 'Animal domestique', 'حيوان أليف'),
        'wild' => _t('Wild animal', 'Animal sauvage', 'حيوان بري'),
        'herbivore' => _t('Eats plants', 'Mange des plantes', 'آكل الأعشاب'),
        'carnivore' => _t('Eats meat', 'Mange de la viande', 'آكل اللحوم'),
        'omnivore' => _t('Eats everything', 'Mange de tout', 'يأكل كل شيء'),
        _ => id,
      };
  String habitatName(String id) => switch (id) {
        'farm' => _t('Farm', 'Ferme', 'المزرعة'),
        'home' => _t('Home', 'Maison', 'البيت'),
        'forest' => _t('Forest', 'Forêt', 'الغابة'),
        'savannah' => _t('Savannah', 'Savane', 'السافانا'),
        'desert' => _t('Desert', 'Désert', 'الصحراء'),
        'wetland' => _t('Lake & marsh', 'Lac et marais', 'البحيرة'),
        _ => id,
      };
  String get livesIn => _t('Lives in', 'Vit dans', 'يعيش في');
  String get sortGame => _t('Sort the animals', 'Classe les animaux', 'صنّف الحيوانات');
  String get sortHint =>
      _t('Farm or wild? Plants or meat?', 'Ferme ou sauvage ? Plantes ou viande ?', 'مزرعة أم بري؟ أعشاب أم لحوم؟');
  String get sortWhere => _t('Where does it live?', 'Où vit-il ?', 'أين يعيش؟');
  String get sortEats => _t('What does it eat?', 'Que mange-t-il ?', 'ماذا يأكل؟');
  String sortRight(String a, String c) => _t('Yes! The $a: $c.', 'Oui ! $a : $c.', 'نعم! $a: $c.');
  String get sortWrong =>
      _t('Not quite, look again!', 'Pas tout à fait, regarde encore !', 'ليس تمامًا، انظر مرة أخرى!');
  String sortDone(int right, int total) =>
      _t('$right of $total right!', '$right sur $total justes !', '$right من $total صحيحة!');
  String get mixGame => _t('Mix colours', 'Mélange les couleurs', 'امزج الألوان');
  String get mixHint =>
      _t('Two paints make a new colour', 'Deux peintures font une couleur', 'لونان يصنعان لونًا جديدًا');
  String get mixPick => _t('Pick two paints', 'Choisis deux peintures', 'اختر لونين');
  String mixResult(String a, String b, String c) => _t('$a and $b make $c!', '$a et $b font $c !', '$a و$b يصنعان $c!');
  String get mixAgain => _t('Mix again', 'Encore', 'امزج مرة أخرى');
  String get town => _t('TOWN', 'VILLE', 'المدينة');
  String get statVehicles => _t('Vehicles met', 'Véhicules découverts', 'مركبات تعرّف عليها');
  String get helpsGame => _t('Who helps?', 'Qui aide ?', 'من يساعد؟');
  String get helpsHint => _t('Find who does the job', 'Trouve qui fait ce travail', 'اعثر على من يقوم بالعمل');
  String get booksTitle => _t('Library', 'Bibliothèque', 'المكتبة');

  // Games
  String get games => _t('Games', 'Jeux', 'ألعاب');
  String get memoryGame => _t('Memory', 'Mémoire', 'الذاكرة');
  String memoryHint({String kind = 'animals'}) => switch (kind) {
        'vehicles' =>
          _t('Match each vehicle to its name', 'Associe chaque véhicule à son nom', 'طابق كل مركبة مع اسمها'),
        'letters' => _t('Match each letter to its word', 'Associe chaque lettre à son mot', 'طابق كل حرف مع كلمته'),
        'colors' => _t('Match each colour to its name', 'Associe chaque couleur à son nom', 'طابق كل لون مع اسمه'),
        'heritage' => _t('Match each picture to its name', 'Associe chaque image à son nom', 'طابق كل صورة مع اسمها'),
        'shapes' => _t('Match each shape to its name', 'Associe chaque forme à son nom', 'طابق كل شكل مع اسمه'),
        'numbers' => _t('Match each number to its name', 'Associe chaque nombre à son nom', 'طابق كل عدد مع اسمه'),
        _ => _t('Match each animal to its name', 'Associe chaque animal à son nom', 'طابق كل حيوان مع اسمه'),
      };
  String get soundQuiz => _t('Sound quiz', 'Quiz des sons', 'اختبار الأصوات');
  String get soundQuizHint => _t('Who makes this sound?', 'Qui fait ce bruit ?', 'من يصدر هذا الصوت؟');
  String movesWin(int moves) => _t('Bravo! You found all the pairs in $moves moves.',
      'Bravo ! Tu as trouvé toutes les paires en $moves coups.', 'أحسنت! وجدت كل الأزواج في $moves محاولة.');
  String get playAgainBtn => _t('Play again', 'Rejouer', 'العب مجددًا');
  String get namesIn => _t('Names in', 'Noms en', 'الأسماء بـ');
}

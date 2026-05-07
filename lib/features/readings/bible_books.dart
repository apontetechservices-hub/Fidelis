/// Bible reference parser and book metadata.
/// Supports Douay-Rheims (DR) and RSVCE lookups.
class BibleBooks {
  /// Map of book abbreviation → full name (Douay-Rheims naming)
  static const Map<String, String> drNames = {
    'Gen': 'Genesis', 'Exod': 'Exodus', 'Lev': 'Leviticus', 'Num': 'Numbers',
    'Deut': 'Deuteronomy', 'Josh': 'Josue', 'Judg': 'Judges', 'Ruth': 'Ruth',
    '1Sam': '1 Kings', '2Sam': '2 Kings', '1Kgs': '3 Kings', '2Kgs': '4 Kings',
    '1Chr': '1 Paralipomenon', '2Chr': '2 Paralipomenon',
    'Ezra': '1 Esdras', 'Neh': '2 Esdras', 'Tob': 'Tobias', 'Jdt': 'Judith',
    'Est': 'Esther', '1Macc': '1 Machabees', '2Macc': '2 Machabees',
    'Job': 'Job', 'Ps': 'Psalms', 'Prov': 'Proverbs', 'Eccl': 'Ecclesiasticus',
    'Song': 'Canticle of Canticles', 'Wis': 'Wisdom',
    'Sir': 'Ecclesiasticus', 'Isa': 'Isaias', 'Jer': 'Jeremias',
    'Lam': 'Lamentations', 'Bar': 'Baruch', 'Ezek': 'Ezechiel',
    'Dan': 'Daniel', 'Hos': 'Osee', 'Joel': 'Joel', 'Amos': 'Amos',
    'Obad': 'Abdias', 'Jon': 'Jonas', 'Mic': 'Micheas', 'Nah': 'Nahum',
    'Hab': 'Habacuc', 'Zeph': 'Sophonias', 'Hag': 'Aggeus', 'Zech': 'Zacharias',
    'Mal': 'Malachias',
    'Matt': 'St. Matthew', 'Mark': 'St. Mark', 'Luke': 'St. Luke',
    'John': 'St. John', 'Acts': 'Acts of the Apostles',
    'Rom': 'Romans', '1Cor': '1 Corinthians', '2Cor': '2 Corinthians',
    'Gal': 'Galatians', 'Eph': 'Ephesians', 'Phil': 'Philippians',
    'Col': 'Colossians', '1Thess': '1 Thessalonians', '2Thess': '2 Thessalonians',
    '1Tim': '1 Timothy', '2Tim': '2 Timothy', 'Tit': 'Titus', 'Phlm': 'Philemon',
    'Heb': 'Hebrews', 'James': 'James', '1Pet': '1 St. Peter', '2Pet': '2 St. Peter',
    '1John': '1 St. John', '2John': '2 St. John', '3John': '3 St. John',
    'Jude': 'Jude', 'Rev': 'Apocalypse',
  };

  /// Map of book abbreviation → RSVCE name
  static const Map<String, String> rsvceNames = {
    'Gen': 'Genesis', 'Exod': 'Exodus', 'Lev': 'Leviticus', 'Num': 'Numbers',
    'Deut': 'Deuteronomy', 'Josh': 'Joshua', 'Judg': 'Judges', 'Ruth': 'Ruth',
    '1Sam': '1 Samuel', '2Sam': '2 Samuel', '1Kgs': '1 Kings', '2Kgs': '2 Kings',
    '1Chr': '1 Chronicles', '2Chr': '2 Chronicles',
    'Ezra': 'Ezra', 'Neh': 'Nehemiah', 'Tob': 'Tobit', 'Jdt': 'Judith',
    'Est': 'Esther', '1Macc': '1 Maccabees', '2Macc': '2 Maccabees',
    'Job': 'Job', 'Ps': 'Psalms', 'Prov': 'Proverbs', 'Eccl': 'Ecclesiastes',
    'Song': 'Song of Solomon', 'Wis': 'Wisdom',
    'Sir': 'Sirach', 'Isa': 'Isaiah', 'Jer': 'Jeremiah',
    'Lam': 'Lamentations', 'Bar': 'Baruch', 'Ezek': 'Ezekiel',
    'Dan': 'Daniel', 'Hos': 'Hosea', 'Joel': 'Joel', 'Amos': 'Amos',
    'Obad': 'Obadiah', 'Jon': 'Jonah', 'Mic': 'Micah', 'Nah': 'Nahum',
    'Hab': 'Habakkuk', 'Zeph': 'Zephaniah', 'Hag': 'Haggai', 'Zech': 'Zechariah',
    'Mal': 'Malachi',
    'Matt': 'Matthew', 'Mark': 'Mark', 'Luke': 'Luke',
    'John': 'John', 'Acts': 'Acts',
    'Rom': 'Romans', '1Cor': '1 Corinthians', '2Cor': '2 Corinthians',
    'Gal': 'Galatians', 'Eph': 'Ephesians', 'Phil': 'Philippians',
    'Col': 'Colossians', '1Thess': '1 Thessalonians', '2Thess': '2 Thessalonians',
    '1Tim': '1 Timothy', '2Tim': '2 Timothy', 'Tit': 'Titus', 'Phlm': 'Philemon',
    'Heb': 'Hebrews', 'James': 'James', '1Pet': '1 Peter', '2Pet': '2 Peter',
    '1John': '1 John', '2John': '2 John', '3John': '3 John',
    'Jude': 'Jude', 'Rev': 'Revelation',
  };

  /// Get book name for a given version
  static String getName(String abbr, String version) {
    final map = version == 'rsvce' ? rsvceNames : drNames;
    return map[abbr] ?? abbr;
  }

  /// Parse a scripture reference like "1 John 5:4-10" into components
  static ScriptureRef? parse(String text) {
    final regex = RegExp(r'(\d?\s?\w+)\s+(\d+):(\d+)(?:-(\d+))?');
    final match = regex.firstMatch(text.trim());
    if (match == null) return null;
    return ScriptureRef(
      book: match[1]!.trim(),
      chapter: int.parse(match[2]!),
      verseStart: int.parse(match[3]!),
      verseEnd: match[4] != null ? int.parse(match[4]!) : null,
    );
  }
}

class ScriptureRef {
  final String book;
  final int chapter;
  final int verseStart;
  final int? verseEnd;

  ScriptureRef({
    required this.book,
    required this.chapter,
    required this.verseStart,
    this.verseEnd,
  });

  @override
  String toString() => '$book $chapter:$verseStart${verseEnd != null ? '-$verseEnd' : ''}';

  String formatted(String version) {
    final name = BibleBooks.getName(book, version);
    return '$name $chapter:$verseStart${verseEnd != null ? '-$verseEnd' : ''}';
  }
}
import 'package:flutter/material.dart';
import '../rosary/rosary_prayers.dart';
import '../../config/app_strings.dart';
import '../prayers/prayer_translations.dart';

/// Step types for chaplet prayer screens
enum ChapletStepType {
  signOfCross,
  creed,
  ourFather,
  hailMary,
  gloryBe,
  customPrayer,
  meditation,
  opening,
  closing,
  fatimaPrayer,
}

/// A single step in a chaplet prayer sequence
class ChapletPrayerStep {
  final ChapletStepType type;
  final String label;
  final String prayerText;
  final int? decadeIndex;
  final int? totalDecades;
  final int? beadIndex;       // e.g., Hail Mary 3 of 10
  final int? totalBeads;
  final int? repeatIndex;     // e.g., Holy God 2 of 3
  final int? totalRepeats;

  const ChapletPrayerStep({
    required this.type,
    required this.label,
    required this.prayerText,
    this.decadeIndex,
    this.totalDecades,
    this.beadIndex,
    this.totalBeads,
    this.repeatIndex,
    this.totalRepeats,
  });
}

/// Chaplet identifier
enum ChapletId {
  divineMercy,
  sevenSorrows,
  stMichael,
  stJude,
  sacredHeart,
  holySpirit,
  holySpirit7Beads,
}

/// Metadata for each chaplet
class ChapletMeta {
  final ChapletId id;
  final String name;
  final String shortDesc;
  final String emoji;
  final Color accentColor;

  const ChapletMeta({
    required this.id,
    required this.name,
    required this.shortDesc,
    required this.emoji,
    required this.accentColor,
  });
}

const chapletList = [
  ChapletMeta(
    id: ChapletId.divineMercy,
    name: 'Divine Mercy Chaplet',
    shortDesc: 'For the sake of His sorrowful Passion, have mercy on us and on the whole world.',
    emoji: '🙏',
    accentColor: Color(0xFFE57373),
  ),
  ChapletMeta(
    id: ChapletId.sevenSorrows,
    name: 'Seven Sorrows Rosary',
    shortDesc: 'Meditate on the seven sorrows of the Blessed Virgin Mary.',
    emoji: '💜',
    accentColor: Color(0xFF7E57C2),
  ),
  ChapletMeta(
    id: ChapletId.stMichael,
    name: 'St. Michael Chaplet',
    shortDesc: 'Honoring the nine choirs of angels through St. Michael the Archangel.',
    emoji: '⚔️',
    accentColor: Color(0xFF42A5F5),
  ),
  ChapletMeta(
    id: ChapletId.stJude,
    name: 'St. Jude Chaplet',
    shortDesc: 'Pray with the patron saint of hopeless and desperate cases.',
    emoji: '✝️',
    accentColor: Color(0xFF66BB6A),
  ),
  ChapletMeta(
    id: ChapletId.sacredHeart,
    name: 'Chaplet of the Sacred Heart',
    shortDesc: 'Devotion to the Sacred Heart of Jesus, meditating on His love.',
    emoji: '❤️‍🔥',
    accentColor: Color(0xFFEF5350),
  ),
  ChapletMeta(
    id: ChapletId.holySpirit,
    name: 'Holy Spirit Chaplet',
    shortDesc: 'Meditating on the seven gifts of the Holy Spirit.',
    emoji: '🔥',
    accentColor: Color(0xFFFF7043),
  ),
  ChapletMeta(
    id: ChapletId.holySpirit7Beads,
    name: 'Holy Spirit Chaplet (7 Beads)',
    shortDesc: 'A shorter chaplet honoring the seven gifts of the Holy Spirit.',
    emoji: '🕊️',
    accentColor: Color(0xFFFFA726),
  ),
];

// ─── Prayer texts (shared) ──────────────────────────────────────

const _signOfTheCross = 'In the name of the Father, and of the Son, and of the Holy Spirit. Amen.';
const _apostlesCreed = 'I believe in God, the Father Almighty, Creator of heaven and earth; and in Jesus Christ, His only Son, our Lord; Who was conceived by the Holy Spirit, born of the Virgin Mary, suffered under Pontius Pilate, was crucified, died, and was buried. He descended into hell; the third day He rose again from the dead. He ascended into Heaven, and is seated at the right hand of God, the Father Almighty; from thence He shall come to judge the living and the dead. I believe in the Holy Spirit, the Holy Catholic Church, the communion of Saints, the forgiveness of sins, the resurrection of the body, and life everlasting. Amen.';
const _ourFather = 'Our Father, Who art in Heaven, hallowed be Thy name; Thy kingdom come; Thy will be done on earth as it is in Heaven. Give us this day our daily bread; and forgive us our trespasses as we forgive those who trespass against us; and lead us not into temptation, but deliver us from evil. Amen.';
const _hailMary = 'Hail Mary, full of grace, the Lord is with thee. Blessed art thou amongst women, and blessed is the fruit of thy womb, Jesus. Holy Mary, Mother of God, pray for us sinners, now and at the hour of our death. Amen.';
const _gloryBe = 'Glory be to the Father, and to the Son, and to the Holy Spirit. As it was in the beginning, is now, and ever shall be, world without end. Amen.';
const _eternalFatherEn = 'Eternal Father, I offer You the Body and Blood, Soul and Divinity of Your dearly beloved Son, Our Lord Jesus Christ, in atonement for our sins and those of the whole world.';
const _eternalFatherEs = 'Padre Eterno, te ofrezco el Cuerpo y la Sangre, el Alma y la Divinidad de tu amadísimo Hijo, Nuestro Señor Jesucristo, en reparación por nuestros pecados y los del mundo entero.';
const _sorrowfulPassionEn = 'For the sake of His sorrowful Passion, have mercy on us and on the whole world.';
const _sorrowfulPassionEs = 'Por Su dolorosa Pasión, ten misericordia de nosotros y del mundo entero.';
const _holyGodEn = 'Holy God, Holy Mighty One, Holy Immortal One, have mercy on us and on the whole world.';
const _holyGodEs = 'Santo Dios, Santo Fuerte, Santo Inmortal, ten misericordia de nosotros y del mundo entero.';
const _closingEn = 'Eternal God, in whom mercy is endless and the treasury of compassion inexhaustible, look kindly upon us and increase Your mercy in us, that in difficult moments we might not despair nor become despondent, but with great confidence submit ourselves to Your holy will, which is Love and Mercy itself. Amen.';
const _closingEs = 'Dios Eterno, en quien la misericordia es infinita y el tesoro de compasión inagotable, míranos con bondad y aumenta en nosotros Tu misericordia, para que en los momentos difíciles no nos desesperemos ni nos desalentemos, sino con gran confianza nos sometamos a Tu santa voluntad, que es Amor y Misericordia misma. Amén.';
// ─── Divine Mercy Chaplet ───────────────────────────────────────

List<ChapletPrayerStep> buildDivineMercySteps({String language = 'en'}) {
  final steps = <ChapletPrayerStep>[];
  const totalDecades = 5;
  final es = language == 'es';
  String T(String key) => AppStrings.tFor(key, language);

  steps.add(ChapletPrayerStep(type: ChapletStepType.signOfCross, label: T('lbl_sign_of_cross'), prayerText: RosaryPrayers.get('sign_of_the_cross', language)));
  steps.add(ChapletPrayerStep(type: ChapletStepType.creed, label: T('lbl_creed'), prayerText: RosaryPrayers.get('apostles_creed', language)));
  steps.add(ChapletPrayerStep(type: ChapletStepType.ourFather, label: T('lbl_our_father'), prayerText: RosaryPrayers.get('our_father', language)));

  for (int i = 1; i <= 3; i++) {
    steps.add(ChapletPrayerStep(
      type: ChapletStepType.hailMary,
      label: T('lbl_hail_mary').replaceAll('{{n}}', '$i').replaceAll('{{m}}', '3'),
      prayerText: RosaryPrayers.get('hail_mary', language),
      beadIndex: i,
      totalBeads: 3,
    ));
  }

  for (int d = 1; d <= totalDecades; d++) {
    steps.add(ChapletPrayerStep(
      type: ChapletStepType.customPrayer,
      label: T('lbl_eternal_father').replaceAll('{{n}}', '$d'),
      prayerText: es ? _eternalFatherEs : _eternalFatherEn,
      decadeIndex: d,
      totalDecades: totalDecades,
    ));

    for (int h = 1; h <= 10; h++) {
      steps.add(ChapletPrayerStep(
        type: ChapletStepType.hailMary,
        label: T('lbl_sorrowful_passion').replaceAll('{{n}}', '$h').replaceAll('{{d}}', '$d'),
        prayerText: es ? _sorrowfulPassionEs : _sorrowfulPassionEn,
        beadIndex: h,
        totalBeads: 10,
        decadeIndex: d,
        totalDecades: totalDecades,
      ));
    }
  }

  for (int i = 1; i <= 3; i++) {
    steps.add(ChapletPrayerStep(
      type: ChapletStepType.customPrayer,
      label: T('lbl_holy_god').replaceAll('{{n}}', '$i'),
      prayerText: es ? _holyGodEs : _holyGodEn,
      repeatIndex: i,
      totalRepeats: 3,
    ));
  }

  steps.add(ChapletPrayerStep(
    type: ChapletStepType.closing,
    label: T('lbl_concluding'),
    prayerText: es ? _closingEs : _closingEn,
    // (the Eternal God mercy text moved below into consts) and the treasury of compassion inexhaustible, look kindly upon us and increase Your mercy in us, that in difficult moments we might not despair nor become despondent, but with great confidence submit ourselves to Your holy will, which is Love and Mercy itself. Amen.',
  ));

  steps.add(const ChapletPrayerStep(type: ChapletStepType.signOfCross, label: 'Sign of the Cross', prayerText: _signOfTheCross));

  return steps;
}

// ─── Seven Sorrows Rosary ────────────────────────────────────────

const _sevenSorrows = [
  SorrowsData('The Prophecy of Simeon', 'Luke 2:34-35', 'And Simeon blessed them and said to Mary his mother, "Behold, this child is set for the fall and rising of many in Israel, and for a sign that is spoken against (and a sword will pierce through your own soul also), that thoughts out of many hearts may be revealed."'),
  SorrowsData('The Flight into Egypt', 'Matthew 2:13-14', 'Now when they had departed, behold, an angel of the Lord appeared to Joseph in a dream and said, "Rise, take the child and his mother, and flee to Egypt, and remain there till I tell you; for Herod is about to search for the child, to destroy him." And he rose and took the child and his mother by night, and departed to Egypt.'),
  SorrowsData('The Loss of the Child Jesus in the Temple', 'Luke 2:44-46', 'But supposing him to be in the company they went a day\'s journey, and they sought him among their kinsfolk and acquaintances; and when they did not find him, they returned to Jerusalem, seeking him. After three days they found him in the temple, sitting among the teachers, listening to them and asking them questions.'),
  SorrowsData('Mary Meets Jesus Carrying the Cross', 'Luke 23:27-28', 'And there followed him a great multitude of the people, and of women who bewailed and lamented him. But Jesus turning to them said, "Daughters of Jerusalem, do not weep for me, but weep for yourselves and for your children."'),
  SorrowsData('The Crucifixion and Death of Jesus', 'John 19:25-27', 'But standing by the cross of Jesus were his mother, and his mother\'s sister, Mary the wife of Clopas, and Mary Magdalene. When Jesus saw his mother, and the disciple whom he loved standing near, he said to his mother, "Woman, behold, your son!" Then he said to the disciple, "Behold, your mother!" And from that hour the disciple took her to his own home.'),
  SorrowsData('Jesus Is Taken Down from the Cross', 'Mark 15:43-46', 'Joseph of Arimathea, a respected member of the council, who was also himself looking for the kingdom of God, took courage and went to Pilate, and asked for the body of Jesus. And Pilate wondered if he were already dead; and summoning the centurion, he asked him whether he was already dead. And when he learned from the centurion that he was dead, he granted the body to Joseph.'),
  SorrowsData('The Burial of Jesus', 'John 19:41-42', 'Now in the place where he was crucified there was a garden, and in the garden a new tomb where no one had ever been laid. So because of the Jewish day of Preparation, as the tomb was close at hand, they laid Jesus there.' ),
];

const _sevenSorrowsEs = [
  SorrowsData('La Profecía de Simeón', 'Lucas 2:34-35', 'Cuando Simeón bendecía a los padres del niño, dijo a María su Madre: «Este niño está puesto para caída y para levantamiento de muchos en Israel, y como señal que será contradecida, y una espada atravesará tu propia alma, para que queden al descubierto los pensamientos de muchos corazones».'),
  SorrowsData('La Huida a Egipto', 'Mateo 2:13-14', 'Cuando se marcharon, el ángel del Señor se apareció en sueños a José y le dijo: «Levántate, toma al niño y a su madre y huye a Egipto y quédate allí hasta que yo te lo diga, porque Herodes quiere matar al niño». Y se levantó y tomó al niño y a su madre y se fue a Egipto por la noche.'),
  SorrowsData('La Pérdida del Niño Jesús en el Templo', 'Lucas 2:44-46', 'Creyéndolo en la caravana, caminaron un día, y lo buscaban entre los parientes y conocidos; al no encontrarlo, volvieron a Jerusalén buscándolo. Al tercer día lo hallaron en el Templo, sentado en medio de los maestros, escuchándolos y haciéndoles preguntas.'),
  SorrowsData('María encuentra a Jesús cargando la cruz', 'Lucas 23:27-28', 'Y lo seguía una gran multitud del pueblo y de mujeres que se lamentaban y se hacían llanto por Él. Jesús, volviéndose a ellas, les dijo: «Hijas de Jerusalén, no lloren por mí, sino por vosotras y por vuestros hijos».'),
  SorrowsData('La Crucifixión y Muerte de Jesús', 'Juan 19:25-27', 'Junto a la cruz de Jesús estaban su Madre, la hermana de su Madre, María la de Cleofás, y María Magdalena. Jesús, viendo a su Madre y junto a ella al discípulo a quien amaba, dijo: «Mujer, he ahí a tu hijo». Después dijo al discípulo: «He ahí a tu Madre». Y desde aquella hora el discípulo la recibió en su casa.'),
  SorrowsData('Jesús es bajado de la cruz', 'Marcos 15:43-46', 'José de Arimatea, miembro distinguido del consejo, que esperaba también el reino de Dios, se atrevió a presentarse ante Pilato y pedir el cuerpo de Jesús. Pilato se extrañó de que ya hubiera muerto; y llamando al centurión, le preguntó si había muerto ya. E informado por el centurión, concedió el cuerpo a José.'),
  SorrowsData('El Entierro de Jesús', 'Juan 19:41-42', 'En el lugar donde crucificaron a Jesús había un huerto, y en el huerto un sepulcro nuevo en el que nadie había sido sepultado aún. Así pues, por ser la preparación de los judíos, puesto que el sepulcro estaba cerca, pusieron allí a Jesús.'),
];

class SorrowsData {
  final String title;
  final String reference;
  final String verse;
  const SorrowsData(this.title, this.reference, this.verse);

  // index position within its list, used to fetch the Spanish twin
  int _indexIn(List<SorrowsData> list) {
    for (var i = 0; i < list.length; i++) {
      if (list[i].title == title) return i;
    }
    return -1;
  }

  SorrowsData? _esTwin() {
    final idx = _indexIn(_sevenSorrows);
    return idx >= 0 && idx < _sevenSorrowsEs.length ? _sevenSorrowsEs[idx] : null;
  }

  String titleFor(String lang) {
    if (lang == 'es') return _esTwin()?.title ?? title;
    return title;
  }

  String referenceFor(String lang) {
    if (lang == 'es') return _esTwin()?.reference ?? reference;
    return reference;
  }

  String verseFor(String lang) {
    if (lang == 'es') return _esTwin()?.verse ?? verse;
    return verse;
  }
}

List<ChapletPrayerStep> buildSevenSorrowsSteps({String language = 'en'}) {
  final es = language == 'es';
  final lang = language;
  String T(String key) => AppStrings.tFor(key, language);
  final steps = <ChapletPrayerStep>[];
  const totalDecades = 7;

  steps.add(ChapletPrayerStep(type: ChapletStepType.signOfCross, label: T('lbl_sign_of_cross'), prayerText: RosaryPrayers.get('sign_of_the_cross', language)));

  steps.add(ChapletPrayerStep(
    type: ChapletStepType.opening,
    label: T('opening_prayer'),
    prayerText: es
        ? 'Oh Dios, ven en mi auxilio. Se\u00f1or, apres\u00farate a socorrerme. Gloria al Padre, y al Hijo, y al Esp\u00edritu Santo. Como era en el principio, ahora y siempre, y por los siglos de los siglos. Am\u00e9n.'
        : 'O God, come to my assistance. O Lord, make haste to help me. Glory be to the Father, and to the Son, and to the Holy Spirit. As it was in the beginning, is now, and ever shall be, world without end. Amen.',
  ));

  for (int d = 1; d <= totalDecades; d++) {
    final sorrow = (es ? _sevenSorrowsEs : _sevenSorrows)[d - 1];

    // Announce the sorrow
    steps.add(ChapletPrayerStep(
      type: ChapletStepType.meditation,
      label: '$d. ${sorrow.titleFor(language)}',
      prayerText: '${sorrow.referenceFor(language)}\n\n${sorrow.verseFor(language)}',
      decadeIndex: d,
      totalDecades: totalDecades,
    ));

    // Our Father
    steps.add(ChapletPrayerStep(
      type: ChapletStepType.ourFather,
      label: '${T('lbl_our_father')} — ${sorrow.titleFor(language)}',
      prayerText: RosaryPrayers.get('our_father', language),
      decadeIndex: d,
      totalDecades: totalDecades,
    ));

    // 7 Hail Marys
    for (int h = 1; h <= 7; h++) {
      steps.add(ChapletPrayerStep(
        type: ChapletStepType.hailMary,
        label: '${T('lbl_hail_mary').replaceAll('{{n}}', '$h').replaceAll('{{m}}', '7')} — ${sorrow.titleFor(language)}',
        prayerText: RosaryPrayers.get('hail_mary', language),
        beadIndex: h,
        totalBeads: 7,
        decadeIndex: d,
        totalDecades: totalDecades,
      ));
    }

    // Glory Be
    steps.add(ChapletPrayerStep(
      type: ChapletStepType.gloryBe,
      label: '${T('lbl_glory_be')} — ${sorrow.titleFor(language)}',
      prayerText: RosaryPrayers.get('glory_be', language),
      decadeIndex: d,
      totalDecades: totalDecades,
    ));
  }

  // 3 Hail Marys in honor of Mary's tears
  for (int i = 1; i <= 3; i++) {
    steps.add(ChapletPrayerStep(
      type: ChapletStepType.hailMary,
      label: '${T('lbl_hail_mary').replaceAll('{{n}}', '$i').replaceAll('{{m}}', '3')} — ${T('tears_honor')}',
      prayerText: RosaryPrayers.get('hail_mary', language),
      beadIndex: i,
      totalBeads: 3,
    ));
  }

  // Hail Holy Queen
  steps.add(ChapletPrayerStep(
    type: ChapletStepType.customPrayer,
    label: T('lbl_hail_holy_queen'),
    prayerText: RosaryPrayers.get('hail_holy_queen', language),
  ));

  steps.add(ChapletPrayerStep(
    type: ChapletStepType.closing,
    label: T('lbl_concluding'),
    prayerText: es
        ? 'Ruega por nosotros, Santa Madre de Dios, para que seamos dignos de alcanzar las promesas de Cristo. Oh Dios, en la Pasi\u00f3n de tu Se\u00f1or Jesucristo, seg\u00fan la profec\u00eda de Sime\u00f3n, una espada de dolor atraves\u00f3 el alma de la gloriosa Virgen Madre Mar\u00eda; conc\u00e9denos misericordiosamente que los que veneramos sus dolores obtengamos el feliz efecto de su Pasi\u00f3n. Por Cristo nuestro Se\u00f1or. Am\u00e9n.'
        : 'Pray for us, O Holy Mother of God, that we may be made worthy of the promises of Christ. O God, at the passion of our Lord Jesus Christ, according to Simeon\'s prophecy, a sword of sorrow pierced the soul of the glorious Virgin and Mother Mary; mercifully grant that we who venerate her sorrows may obtain the happy effect of His passion. Through Christ our Lord. Amen.',
  ));

  steps.add(ChapletPrayerStep(type: ChapletStepType.signOfCross, label: T('lbl_sign_of_cross'), prayerText: RosaryPrayers.get('sign_of_the_cross', language)));

  return steps;
}

// ─── St. Michael Chaplet ─────────────────────────────────────────

const _angelChoirs = [
  'Angels',
  'Archangels',
  'Principalities',
  'Powers',
  'Virtues',
  'Dominations',
  'Thrones',
  'Cherubim',
  'Seraphim',
];

const _angelChoirsEs = [
  'Ángeles',
  'Arcángeles',
  'Principalidades',
  'Potestades',
  'Virtudes',
  'Dominaciones',
  'Tronos',
  'Querubines',
  'Serafines',
];

List<ChapletPrayerStep> buildStMichaelSteps({String language = 'en'}) {
  final steps = <ChapletPrayerStep>[];
  const totalSalutations = 9;
  final es = language == 'es';
  String T(String key) => AppStrings.tFor(key, language);

  steps.add(ChapletPrayerStep(type: ChapletStepType.signOfCross, label: T('lbl_sign_of_cross'), prayerText: RosaryPrayers.get('sign_of_the_cross', language)));

  steps.add(ChapletPrayerStep(
    type: ChapletStepType.opening,
    label: T('act_of_contr_title'),
    prayerText: es
        ? (PrayerTranslations.spanish['Act of Contrition'] ?? 'O my God, I am heartily sorry for having offended Thee.')
        : 'O my God, I am heartily sorry for having offended Thee, and I detest all my sins because of Thy just punishments, but most of all because they offend Thee, my God, Who art all-good and deserving of all my love. I firmly resolve, with the help of Thy grace, to sin no more and to avoid the near occasions of sin. Amen.',
  ));

  for (int s = 1; s <= totalSalutations; s++) {
    final choir = (es ? _angelChoirsEs : _angelChoirs)[s - 1];

    // Salutation
    steps.add(ChapletPrayerStep(
      type: ChapletStepType.meditation,
      label: '${T('lbl_salutation').replaceAll('{{n}}', '$s')} — $choir',
      prayerText: es
        ? 'Por la intercesi\u00f3n de San Miguel y del coro celestial de los $choir, conc\u00e9danos el Se\u00f1or la gracia de perseverar en la fe y de vencer las tentaciones del enemigo.'
        : 'By the intercession of St. Michael and the celestial choir of $choir, may the Lord grant us the grace to persevere in the faith and to overcome the temptations of the enemy.',
      decadeIndex: s,
      totalDecades: totalSalutations,
    ));

    // Our Father
    steps.add(ChapletPrayerStep(
      type: ChapletStepType.ourFather,
      label: '${T('lbl_our_father')} — $choir',
      prayerText: RosaryPrayers.get('our_father', language),
      decadeIndex: s,
      totalDecades: totalSalutations,
    ));

    // 3 Hail Marys
    for (int h = 1; h <= 3; h++) {
      steps.add(ChapletPrayerStep(
        type: ChapletStepType.hailMary,
        label: '${T('lbl_hail_mary').replaceAll('{{n}}', '$h').replaceAll('{{m}}', '3')} — $choir',
        prayerText: RosaryPrayers.get('hail_mary', language),
        beadIndex: h,
        totalBeads: 3,
        decadeIndex: s,
        totalDecades: totalSalutations,
      ));
    }

    // Glory Be
    steps.add(ChapletPrayerStep(
      type: ChapletStepType.gloryBe,
      label: '${T('lbl_glory_be')} — $choir',
      prayerText: RosaryPrayers.get('glory_be', language),
      decadeIndex: s,
      totalDecades: totalSalutations,
    ));
  }

  // 4 Our Fathers (for the Archangels: Michael, Gabriel, Raphael, Guardian Angel)
  const archangelNames = ['St. Michael', 'St. Gabriel', 'St. Raphael', 'Our Guardian Angel'];
  const _archangelNamesEs = ['San Miguel', 'San Gabriel', 'San Rafael', 'Nuestro Ángel de la Guarda'];
  for (int i = 0; i < 4; i++) {
    steps.add(ChapletPrayerStep(
      type: ChapletStepType.ourFather,
      label: '${T('lbl_our_father')} — ${(es ? _archangelNamesEs : archangelNames)[i]}',
      prayerText: _ourFather,
    ));
  }

  // Closing prayer to St. Michael
  steps.add(ChapletPrayerStep(
    type: ChapletStepType.closing,
    label: T('lbl_prayer_st_michael'),
    prayerText: es ? (PrayerTranslations.spanish['Prayer to St. Michael the Archangel'] ?? '') : 'Saint Michael the Archangel, defend us in battle; be our protection against the wickedness and snares of the devil. May God rebuke him, we humbly pray; and do thou, O Prince of the heavenly host, by the power of God, cast into hell Satan and all the evil spirits who prowl about the world seeking the ruin of souls. Amen.',
  ));

  steps.add(ChapletPrayerStep(type: ChapletStepType.signOfCross, label: T('lbl_sign_of_cross'), prayerText: RosaryPrayers.get('sign_of_the_cross', language)));

  return steps;
}

// ─── St. Jude Chaplet ────────────────────────────────────────────

List<ChapletPrayerStep> buildStJudeSteps({String language = 'en'}) {
  final es = language == 'es';
  String T(String key) => AppStrings.tFor(key, language);
  final steps = <ChapletPrayerStep>[];
  const totalDecades = 5;

  steps.add(ChapletPrayerStep(type: ChapletStepType.signOfCross, label: T('lbl_sign_of_cross'), prayerText: RosaryPrayers.get('sign_of_the_cross', language)));
  steps.add(ChapletPrayerStep(type: ChapletStepType.creed, label: T('lbl_creed'), prayerText: RosaryPrayers.get('apostles_creed', language)));
  steps.add(ChapletPrayerStep(type: ChapletStepType.ourFather, label: T('lbl_our_father'), prayerText: RosaryPrayers.get('our_father', language)));

  // 3 Hail Marys
  for (int i = 1; i <= 3; i++) {
    steps.add(ChapletPrayerStep(
      type: ChapletStepType.hailMary,
      label: T('lbl_hail_mary').replaceAll('{{n}}', '$i').replaceAll('{{m}}', '3'),
      prayerText: RosaryPrayers.get('hail_mary', language),
      beadIndex: i,
      totalBeads: 3,
    ));
  }

  steps.add(ChapletPrayerStep(type: ChapletStepType.gloryBe, label: T('lbl_glory_be'), prayerText: RosaryPrayers.get('glory_be', language)));

  // 5 Decades
  final meditations = (es
      ? ['San Judas, siervo fiel de Dios', 'San Judas, ap\u00f3stol de Cristo', 'San Judas, ayuda en los casos desesperados', 'San Judas, patr\u00f3n de lo imposible', 'San Judas, intercesor de los desesperados']
      : ['St. Jude, faithful servant of God', 'St. Jude, apostle of Christ', 'St. Jude, helper in desperate cases', 'St. Jude, patron of the impossible', 'St. Jude, intercessor for the hopeless']);

  for (int d = 1; d <= totalDecades; d++) {
    steps.add(ChapletPrayerStep(
      type: ChapletStepType.meditation,
      label: '${T('lbl_decade').replaceAll('{{n}}', '$d')} — ${meditations[d - 1]}',
      prayerText: meditations[d - 1],
      decadeIndex: d,
      totalDecades: totalDecades,
    ));

    // Our Father
    steps.add(ChapletPrayerStep(
      type: ChapletStepType.ourFather,
      label: '${T('lbl_our_father')} — ${T('lbl_decade').replaceAll('{{n}}', '$d')}',
      prayerText: RosaryPrayers.get('our_father', language),
      decadeIndex: d,
      totalDecades: totalDecades,
    ));

    // 10 Hail Marys with "St. Jude, pray for us"
    for (int h = 1; h <= 10; h++) {
      steps.add(ChapletPrayerStep(
        type: ChapletStepType.hailMary,
        label: '${T('lbl_hail_mary').replaceAll('{{n}}', '$h').replaceAll('{{m}}', '10')} — ${T('lbl_decade').replaceAll('{{n}}', '$d')}',
        prayerText: '${RosaryPrayers.get('hail_mary', language)}\n\n${es ? 'San Judas Tadeo, ap\u00f3stol y m\u00e1rtir, ruega por nosotros.' : 'St. Jude, apostle and martyr, pray for us.'}',
        beadIndex: h,
        totalBeads: 10,
        decadeIndex: d,
        totalDecades: totalDecades,
      ));
    }

    // Glory Be
    steps.add(ChapletPrayerStep(
      type: ChapletStepType.gloryBe,
      label: '${T('lbl_glory_be')} — ${T('lbl_decade').replaceAll('{{n}}', '$d')}',
      prayerText: RosaryPrayers.get('glory_be', language),
      decadeIndex: d,
      totalDecades: totalDecades,
    ));
  }

  // Closing prayer to St. Jude
  steps.add(ChapletPrayerStep(
    type: ChapletStepType.closing,
    label: T('lbl_prayer_st_jude'),
    prayerText: es
        ? 'Oh sant\u00edsimo Ap\u00f3stol San Judas Tadeo, fiel siervo y amigo de Jes\u00fas, la Iglesia te honra e invoca universalmente como patrono de los casos desesperados y de las cosas dadas por perdidas. Ruega por m\u00ed, que soy tan miserable. Imploro que uses del privilegio especial que se te ha concedido, de llevar ayuda visible y pronta cuando casi se desesperaba de ella. Acude a mi auxilio en esta gran necesidad, para que reciba el consuelo y socorro del Cielo en todas mis necesidades, tribulaciones y sufrimientos, particularmente [menciona tu petici\u00f3n], y que pueda alabar a Dios contigo y con todos los elegidos por toda la eternidad. Te prometo, bienaventurado San Judas, recordar siempre este gran favor, y no cesar\u00e9 jam\u00e1s de honrarte como mi patr\u00f3n especial y poderoso, ni de hacer todo lo que pueda para fomentar la devoci\u00f3n a ti. Am\u00e9n.'
        : 'O most holy Apostle, St. Jude, faithful servant and friend of Jesus, the Church honors and invokes thee universally, as the patron of hopeless cases, and of things despaired of. Pray for me, who am so miserable. Make use, I implore thee, of that particular privilege accorded to thee, to bring visible and speedy help where help was almost despaired of. Come to my assistance in this great need, that I may receive the consolation and succor of Heaven in all my necessities, tribulations, and sufferings, particularly [mention your request], and that I may praise God with thee and all the elect throughout all eternity. I promise thee, O blessed Jude, to be ever mindful of this great favor, and I will never cease to honor thee as my special and powerful patron, and to do all in my power to encourage devotion to thee. Amen.',
  ));

  steps.add(const ChapletPrayerStep(type: ChapletStepType.signOfCross, label: 'Sign of the Cross', prayerText: _signOfTheCross));

  return steps;
}

// ─── Chaplet of the Sacred Heart ─────────────────────────────────

const _sacredHeartMeditations = [
  'The Love of the Sacred Heart for us in the Blessed Sacrament',
  'The Humility of the Sacred Heart',
  'The Mercy of the Sacred Heart',
  'The Zeal of the Sacred Heart for the Salvation of Souls',
  'The Patience and Mildness of the Sacred Heart',
];

List<ChapletPrayerStep> buildSacredHeartSteps({String language = 'en'}) {
  final es = language == 'es';
  String T(String key) => AppStrings.tFor(key, language);
  final steps = <ChapletPrayerStep>[];
  const totalDecades = 5;
  final esMeditations = es
      ? ['El Amor del Sagrado Coraz\u00f3n por nosotros en el Sant\u00edsimo Sacramento', 'La Humildad del Sagrado Coraz\u00f3n', 'La Misericordia del Sagrado Coraz\u00f3n', 'El Celo del Sagrado Coraz\u00f3n por la salvaci\u00f3n de las almas', 'La Paciencia y Mansedumbre del Sagrado Coraz\u00f3n']
      : _sacredHeartMeditations;

  steps.add(ChapletPrayerStep(type: ChapletStepType.signOfCross, label: T('lbl_sign_of_cross'), prayerText: RosaryPrayers.get('sign_of_the_cross', language)));

  steps.add(ChapletPrayerStep(
    type: ChapletStepType.opening,
    label: T('act_of_consec_title'),
    prayerText: es
        ? 'Oh Sagrado Coraz\u00f3n de Jes\u00fas, me consagro a Ti y me entrego por entero al amor de tu Coraz\u00f3n ardiente. Te adoro en el Sant\u00edsimo Sacramento y quiero reparar todos los ultrajes que recibes de las almas ingratas. Am\u00e9n.'
        : 'O Sacred Heart of Jesus, I consecrate myself to Thee, and I give myself entirely to the love of Thy burning Heart. I adore Thee in the Most Blessed Sacrament, and I desire to make reparation for all the outrages which Thou receivest from ungrateful souls. Amen.',
  ));

  steps.add(ChapletPrayerStep(type: ChapletStepType.ourFather, label: T('lbl_our_father'), prayerText: RosaryPrayers.get('our_father', language)));

  for (int i = 1; i <= 3; i++) {
    steps.add(ChapletPrayerStep(
      type: ChapletStepType.hailMary,
      label: T('lbl_hail_mary').replaceAll('{{n}}', '$i').replaceAll('{{m}}', '3'),
      prayerText: RosaryPrayers.get('hail_mary', language),
      beadIndex: i,
      totalBeads: 3,
    ));
  }

  steps.add(ChapletPrayerStep(type: ChapletStepType.gloryBe, label: T('lbl_glory_be'), prayerText: RosaryPrayers.get('glory_be', language)));

  for (int d = 1; d <= totalDecades; d++) {
    steps.add(ChapletPrayerStep(
      type: ChapletStepType.meditation,
      label: '${T('lbl_decade').replaceAll('{{n}}', '$d')} — ${esMeditations[d - 1]}',
      prayerText: esMeditations[d - 1],
      decadeIndex: d,
      totalDecades: totalDecades,
    ));

    steps.add(ChapletPrayerStep(
      type: ChapletStepType.ourFather,
      label: '${T('lbl_our_father')} — ${T('lbl_decade').replaceAll('{{n}}', '$d')}',
      prayerText: RosaryPrayers.get('our_father', language),
      decadeIndex: d,
      totalDecades: totalDecades,
    ));

    for (int h = 1; h <= 10; h++) {
      steps.add(ChapletPrayerStep(
        type: ChapletStepType.hailMary,
        label: '${T('lbl_hail_mary').replaceAll('{{n}}', '$h').replaceAll('{{m}}', '10')} — ${T('lbl_decade').replaceAll('{{n}}', '$d')}',
        prayerText: RosaryPrayers.get('hail_mary', language),
        beadIndex: h,
        totalBeads: 10,
        decadeIndex: d,
        totalDecades: totalDecades,
      ));
    }

    steps.add(ChapletPrayerStep(
      type: ChapletStepType.gloryBe,
      label: '${T('lbl_glory_be')} — ${T('lbl_decade').replaceAll('{{n}}', '$d')}',
      prayerText: RosaryPrayers.get('glory_be', language),
      decadeIndex: d,
      totalDecades: totalDecades,
    ));

    steps.add(ChapletPrayerStep(
      type: ChapletStepType.customPrayer,
      label: T('lbl_ejaculatory').replaceAll('{{n}}', '$d'),
      prayerText: es
          ? 'Jes\u00fas, manso y humilde de coraz\u00f3n, haz mi coraz\u00f3n semejante al tuyo.'
          : 'Jesus, meek and humble of heart, make my heart like unto Thine.',
      decadeIndex: d,
      totalDecades: totalDecades,
    ));
  }

  steps.add(ChapletPrayerStep(
    type: ChapletStepType.closing,
    label: T('lbl_concluding'),
    prayerText: es
        ? 'Oh Divino Coraz\u00f3n de Jes\u00fas, te ofrezco todo el amor, la gratitud y la reparaci\u00f3n que los corazones de todos los redimidos pueden ofrecerte. Uno esta ofrenda al amor del Sagrado Coraz\u00f3n de Jes\u00fas, que jam\u00e1s se agota. Que el Sagrado Coraz\u00f3n de Jes\u00fas sea amado en todas partes. Am\u00e9n.'
        : 'O Divine Heart of Jesus, I offer Thee all the love, gratitude, and reparation which the hearts of all the redeemed can possibly offer Thee. I unite this offering to the love of the Sacred Heart of Jesus, which is never exhausted. May the most Sacred Heart of Jesus be loved everywhere. Amen.',
  ));

  steps.add(ChapletPrayerStep(type: ChapletStepType.signOfCross, label: T('lbl_sign_of_cross'), prayerText: RosaryPrayers.get('sign_of_the_cross', language)));

  return steps;
}

// ─── Holy Spirit Chaplet (7 Decades) ─────────────────────────────

const _holySpiritGifts = [
  'The Gift of Wisdom',
  'The Gift of Understanding',
  'The Gift of Counsel',
  'The Gift of Fortitude',
  'The Gift of Knowledge',
  'The Gift of Piety',
  'The Gift of the Fear of the Lord',
];

const _holySpiritGiftDescs = [
  'That we may esteem the things of heaven above the things of earth.',
  'That we may understand the mysteries of our holy faith.',
  'That we may be directed by the Holy Spirit in all our actions.',
  'That we may overcome all difficulties in the service of God.',
  'That we may know God and ourselves, and grow in holiness.',
  'That we may find the service of God sweet and lovable.',
  'That we may be filled with a filial fear of offending God.',
];

List<ChapletPrayerStep> buildHolySpiritSteps({String language = 'en'}) {
  final es = language == 'es';
  String T(String key) => AppStrings.tFor(key, language);
  final esGifts = es
      ? ['El Don de la Sabidur\u00eda', 'El Don del Entendimiento', 'El Don del Consejo', 'El Don de la Fortaleza', 'El Don de la Ciencia', 'El Don de la Piedad', 'El Don del Temor de Dios']
      : _holySpiritGifts;
  final esDescs = es
      ? ['Para estimar las cosas del cielo sobre las de la tierra.', 'Para entender los misterios de nuestra santa fe.', 'Para que el Esp\u00edritu Santo dirija todas nuestras acciones.', 'Para vencer todas las dificultades en el servicio de Dios.', 'Para conocer a Dios y a nosotros mismos, y crecer en santidad.', 'Para que el servicio de Dios nos resulte dulce y amable.', 'Para estar llenos del temor filial de ofender a Dios.']
      : _holySpiritGiftDescs;
  final steps = <ChapletPrayerStep>[];
  const totalDecades = 7;

  steps.add(ChapletPrayerStep(type: ChapletStepType.signOfCross, label: T('lbl_sign_of_cross'), prayerText: RosaryPrayers.get('sign_of_the_cross', language)));

  steps.add(ChapletPrayerStep(
    type: ChapletStepType.opening,
    label: T('lbl_come_holy_spirit'),
    prayerText: es
        ? 'Ven Esp\u00edritu Santo, llena los corazones de tus fieles y enciende en ellos el fuego de tu amor. Env\u00eda tu Esp\u00edritu, y ser\u00e1n creados, y renovar\u00e1s la faz de la tierra. Oh Dios, que por la luz del Esp\u00edritu Santo instr\u00faiste los corazones de los fieles, conc\u00e9denos que por ese mismo Esp\u00edritu seamos siempre verdaderamente sabios y gocemos de sus consolaciones. Por Cristo nuestro Se\u00f1or. Am\u00e9n.'
        : 'Come, O Holy Spirit, fill the hearts of Thy faithful, and kindle in them the fire of Thy love. Send forth Thy Spirit, and they shall be created; and Thou shalt renew the face of the earth. O God, Who by the light of the Holy Spirit didst instruct the hearts of the faithful, grant that by the same Holy Spirit we may be truly wise, and ever enjoy His consolations. Through Christ our Lord. Amen.',
  ));

  // Our Father and Glory Be before the decades
  steps.add(ChapletPrayerStep(type: ChapletStepType.ourFather, label: T('lbl_our_father'), prayerText: RosaryPrayers.get('our_father', language)));
  steps.add(ChapletPrayerStep(type: ChapletStepType.gloryBe, label: T('lbl_glory_be'), prayerText: RosaryPrayers.get('glory_be', language)));

  for (int d = 1; d <= totalDecades; d++) {
    steps.add(ChapletPrayerStep(
      type: ChapletStepType.meditation,
      label: '${T('lbl_decade').replaceAll('{{n}}', '$d')} — ${esGifts[d - 1]}',
      prayerText: '${esGifts[d - 1]}\n\n${esDescs[d - 1]}',
      decadeIndex: d,
      totalDecades: totalDecades,
    ));

    // Our Father
    steps.add(ChapletPrayerStep(
      type: ChapletStepType.ourFather,
      label: '${T('lbl_our_father')} — ${esGifts[d - 1]}',
      prayerText: RosaryPrayers.get('our_father', language),
      decadeIndex: d,
      totalDecades: totalDecades,
    ));

    // 7 Hail Marys (for 7 gifts)
    for (int h = 1; h <= 7; h++) {
      steps.add(ChapletPrayerStep(
        type: ChapletStepType.hailMary,
        label: '${T('lbl_hail_mary').replaceAll('{{n}}', '$h').replaceAll('{{m}}', '7')} — ${esGifts[d - 1]}',
        prayerText: RosaryPrayers.get('hail_mary', language),
        beadIndex: h,
        totalBeads: 7,
        decadeIndex: d,
        totalDecades: totalDecades,
      ));
    }

    // Glory Be
    steps.add(ChapletPrayerStep(
      type: ChapletStepType.gloryBe,
      label: '${T('lbl_glory_be')} — ${esGifts[d - 1]}',
      prayerText: RosaryPrayers.get('glory_be', language),
      decadeIndex: d,
      totalDecades: totalDecades,
    ));
  }

  steps.add(ChapletPrayerStep(
    type: ChapletStepType.closing,
    label: T('lbl_concluding'),
    prayerText: es
        ? 'Oh Dios, que por la luz del Esp\u00edritu Santo instr\u00faiste los corazones de los fieles, conc\u00e9denos que por ese mismo Esp\u00edritu seamos siempre verdaderamente sabios y gocemos de sus consolaciones. Por Cristo nuestro Se\u00f1or. Am\u00e9n. Ven Esp\u00edritu Santo, llena los corazones de tus fieles y enciende en ellos el fuego de tu amor. Am\u00e9n.'
        : 'O God, Who by the light of the Holy Spirit didst instruct the hearts of the faithful, grant that by the same Holy Spirit we may be truly wise, and ever enjoy His consolations. Through Christ our Lord. Amen. Come, Holy Spirit, fill the hearts of Thy faithful and kindle in them the fire of Thy love. Amen.',
  ));

  steps.add(ChapletPrayerStep(type: ChapletStepType.signOfCross, label: T('lbl_sign_of_cross'), prayerText: RosaryPrayers.get('sign_of_the_cross', language)));

  return steps;
}

// ─── Holy Spirit Chaplet (7 Beads) ──────────────────────────────

List<ChapletPrayerStep> buildHolySpirit7BeadsSteps({String language = 'en'}) {
  final es = language == 'es';
  String T(String key) => AppStrings.tFor(key, language);
  final esGifts = es
      ? ['El Don de la Sabidur\u00eda', 'El Don del Entendimiento', 'El Don del Consejo', 'El Don de la Fortaleza', 'El Don de la Ciencia', 'El Don de la Piedad', 'El Don del Temor de Dios']
      : _holySpiritGifts;
  final esDescs = es
      ? ['Para estimar las cosas del cielo sobre las de la tierra.', 'Para entender los misterios de nuestra santa fe.', 'Para que el Esp\u00edritu Santo dirija todas nuestras acciones.', 'Para vencer todas las dificultades en el servicio de Dios.', 'Para conocer a Dios y a nosotros mismos, y crecer en santidad.', 'Para que el servicio de Dios nos resulte dulce y amable.', 'Para estar llenos del temor filial de ofender a Dios.']
      : _holySpiritGiftDescs;
  final steps = <ChapletPrayerStep>[];

  steps.add(ChapletPrayerStep(type: ChapletStepType.signOfCross, label: T('lbl_sign_of_cross'), prayerText: RosaryPrayers.get('sign_of_the_cross', language)));

  steps.add(ChapletPrayerStep(
    type: ChapletStepType.opening,
    label: T('lbl_come_holy_spirit'),
    prayerText: es
        ? 'Ven Esp\u00edritu Santo, llena los corazones de tus fieles y enciende en ellos el fuego de tu amor. Env\u00eda tu Esp\u00edritu, y ser\u00e1n creados, y renovar\u00e1s la faz de la tierra. Am\u00e9n.'
        : 'Come, O Holy Spirit, fill the hearts of Thy faithful, and kindle in them the fire of Thy love. Send forth Thy Spirit, and they shall be created; and Thou shalt renew the face of the earth. Amen.',
  ));

  // Act of Consecration
  steps.add(ChapletPrayerStep(
    type: ChapletStepType.opening,
    label: T('act_of_consec_title'),
    prayerText: es
        ? 'Oh Esp\u00edritu Santo, me consagro a Ti. Ven, toma posesi\u00f3n de mi alma y haz de ella tu templo y tu morada. Llena mi coraz\u00f3n con tu amor, mi mente con tu luz y mi voluntad con tu tuerza. Am\u00e9n. ESFIX'
        : 'O Holy Spirit, I consecrate myself to Thee. Come and take possession of my soul, and make of it Thy temple and Thy dwelling. Fill my heart with Thy love, my mind with Thy light, and my will with Thy strength. Amen.',
  ));

  // 7 beads — one for each gift
  for (int i = 0; i < 7; i++) {
    steps.add(ChapletPrayerStep(
      type: ChapletStepType.meditation,
      label: esGifts[i],
      prayerText: '${esGifts[i]}\n\n${esDescs[i]}',
      decadeIndex: i + 1,
      totalDecades: 7,
    ));

    steps.add(ChapletPrayerStep(
      type: ChapletStepType.ourFather,
      label: '${T('lbl_our_father')} — ${esGifts[i]}',
      prayerText: RosaryPrayers.get('our_father', language),
      decadeIndex: i + 1,
      totalDecades: 7,
    ));

    steps.add(ChapletPrayerStep(
      type: ChapletStepType.gloryBe,
      label: '${T('lbl_glory_be')} — ${esGifts[i]}',
      prayerText: RosaryPrayers.get('glory_be', language),
      decadeIndex: i + 1,
      totalDecades: 7,
    ));
  }

  steps.add(ChapletPrayerStep(
    type: ChapletStepType.closing,
    label: T('lbl_concluding'),
    prayerText: es
        ? 'Oh Dios, que por la luz del Esp\u00edritu Santo instr\u00faiste los corazones de los fieles, conc\u00e9denos que por ese mismo Esp\u00edritu seamos siempre verdaderamente sabios y gocemos de sus consolaciones. Por Cristo nuestro Se\u00f1or. Am\u00e9n. Ven Esp\u00edritu Santo, llena los corazones de tus fieles y enciende en ellos el fuego de tu amor. Am\u00e9n.'
        : 'O God, Who by the light of the Holy Spirit didst instruct the hearts of the faithful, grant that by the same Holy Spirit we may be truly wise, and ever enjoy His consolations. Through Christ our Lord. Amen. Come, Holy Spirit, fill the hearts of Thy faithful and kindle in them the fire of Thy love. Amen.',
  ));

  steps.add(ChapletPrayerStep(type: ChapletStepType.signOfCross, label: T('lbl_sign_of_cross'), prayerText: RosaryPrayers.get('sign_of_the_cross', language)));

  return steps;
}

// ─── Builder function ────────────────────────────────────────────

List<ChapletPrayerStep> buildChapletSteps(ChapletId id, {String language = 'en'}) {
  switch (id) {
    case ChapletId.divineMercy:
      return buildDivineMercySteps(language: language);
    case ChapletId.sevenSorrows:
      return buildSevenSorrowsSteps(language: language);
    case ChapletId.stMichael:
      return buildStMichaelSteps(language: language);
    case ChapletId.stJude:
      return buildStJudeSteps(language: language);
    case ChapletId.sacredHeart:
      return buildSacredHeartSteps(language: language);
    case ChapletId.holySpirit:
      return buildHolySpiritSteps(language: language);
    case ChapletId.holySpirit7Beads:
      return buildHolySpirit7BeadsSteps(language: language);
  }
}

ChapletMeta getChapletMeta(ChapletId id) {
  return chapletList.firstWhere((m) => m.id == id);
}
import 'package:flutter/material.dart';

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
// ─── Divine Mercy Chaplet ───────────────────────────────────────

List<ChapletPrayerStep> buildDivineMercySteps() {
  final steps = <ChapletPrayerStep>[];
  const totalDecades = 5;

  steps.add(const ChapletPrayerStep(type: ChapletStepType.signOfCross, label: 'Sign of the Cross', prayerText: _signOfTheCross));
  steps.add(const ChapletPrayerStep(type: ChapletStepType.creed, label: 'Apostles\' Creed', prayerText: _apostlesCreed));
  steps.add(const ChapletPrayerStep(type: ChapletStepType.ourFather, label: 'Our Father', prayerText: _ourFather));

  for (int i = 1; i <= 3; i++) {
    steps.add(ChapletPrayerStep(
      type: ChapletStepType.hailMary,
      label: 'Hail Mary ($i of 3)',
      prayerText: _hailMary,
      beadIndex: i,
      totalBeads: 3,
    ));
  }

  for (int d = 1; d <= totalDecades; d++) {
    steps.add(ChapletPrayerStep(
      type: ChapletStepType.customPrayer,
      label: 'Eternal Father (Decade $d)',
      prayerText: 'Eternal Father, I offer You the Body and Blood, Soul and Divinity of Your dearly beloved Son, Our Lord Jesus Christ, in atonement for our sins and those of the whole world.',
      decadeIndex: d,
      totalDecades: totalDecades,
    ));

    for (int h = 1; h <= 10; h++) {
      steps.add(ChapletPrayerStep(
        type: ChapletStepType.hailMary,
        label: 'Sorrowful Passion ($h of 10) — Decade $d',
        prayerText: 'For the sake of His sorrowful Passion, have mercy on us and on the whole world.',
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
      label: 'Holy God ($i of 3)',
      prayerText: 'Holy God, Holy Mighty One, Holy Immortal One, have mercy on us and on the whole world.',
      repeatIndex: i,
      totalRepeats: 3,
    ));
  }

  steps.add(const ChapletPrayerStep(
    type: ChapletStepType.closing,
    label: 'Closing Prayer',
    prayerText: 'Eternal God, in whom mercy is endless and the treasury of compassion inexhaustible, look kindly upon us and increase Your mercy in us, that in difficult moments we might not despair nor become despondent, but with great confidence submit ourselves to Your holy will, which is Love and Mercy itself. Amen.',
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

class SorrowsData {
  final String title;
  final String reference;
  final String verse;
  const SorrowsData(this.title, this.reference, this.verse);
}

List<ChapletPrayerStep> buildSevenSorrowsSteps() {
  final steps = <ChapletPrayerStep>[];
  const totalDecades = 7;

  steps.add(const ChapletPrayerStep(type: ChapletStepType.signOfCross, label: 'Sign of the Cross', prayerText: _signOfTheCross));

  steps.add(const ChapletPrayerStep(
    type: ChapletStepType.opening,
    label: 'Opening Prayer',
    prayerText: 'O God, come to my assistance. O Lord, make haste to help me. Glory be to the Father, and to the Son, and to the Holy Spirit. As it was in the beginning, is now, and ever shall be, world without end. Amen.',
  ));

  for (int d = 1; d <= totalDecades; d++) {
    final sorrow = _sevenSorrows[d - 1];

    // Announce the sorrow
    steps.add(ChapletPrayerStep(
      type: ChapletStepType.meditation,
      label: '$d. ${sorrow.title}',
      prayerText: '${sorrow.reference}\n\n${sorrow.verse}',
      decadeIndex: d,
      totalDecades: totalDecades,
    ));

    // Our Father
    steps.add(ChapletPrayerStep(
      type: ChapletStepType.ourFather,
      label: 'Our Father — ${sorrow.title}',
      prayerText: _ourFather,
      decadeIndex: d,
      totalDecades: totalDecades,
    ));

    // 7 Hail Marys
    for (int h = 1; h <= 7; h++) {
      steps.add(ChapletPrayerStep(
        type: ChapletStepType.hailMary,
        label: 'Hail Mary ($h of 7) — ${sorrow.title}',
        prayerText: _hailMary,
        beadIndex: h,
        totalBeads: 7,
        decadeIndex: d,
        totalDecades: totalDecades,
      ));
    }

    // Glory Be
    steps.add(ChapletPrayerStep(
      type: ChapletStepType.gloryBe,
      label: 'Glory Be — ${sorrow.title}',
      prayerText: _gloryBe,
      decadeIndex: d,
      totalDecades: totalDecades,
    ));
  }

  // 3 Hail Marys in honor of Mary's tears
  for (int i = 1; i <= 3; i++) {
    steps.add(ChapletPrayerStep(
      type: ChapletStepType.hailMary,
      label: 'Hail Mary ($i of 3) — In Honor of Mary\'s Tears',
      prayerText: _hailMary,
      beadIndex: i,
      totalBeads: 3,
    ));
  }

  // Hail Holy Queen
  steps.add(const ChapletPrayerStep(
    type: ChapletStepType.customPrayer,
    label: 'Hail Holy Queen',
    prayerText: 'Hail, Holy Queen, Mother of Mercy, our life, our sweetness, and our hope. To thee do we cry, poor banished children of Eve; to thee do we send up our sighs, mourning and weeping in this valley of tears. Turn then, most gracious Advocate, thine eyes of mercy toward us, and after this our exile, show unto us the blessed fruit of thy womb, Jesus. O clement, O loving, O sweet Virgin Mary!',
  ));

  steps.add(const ChapletPrayerStep(
    type: ChapletStepType.closing,
    label: 'Closing Prayer',
    prayerText: 'Pray for us, O Holy Mother of God, that we may be made worthy of the promises of Christ. O God, at the passion of our Lord Jesus Christ, according to Simeon\'s prophecy, a sword of sorrow pierced the soul of the glorious Virgin and Mother Mary; mercifully grant that we who venerate her sorrows may obtain the happy effect of His passion. Through Christ our Lord. Amen.',
  ));

  steps.add(const ChapletPrayerStep(type: ChapletStepType.signOfCross, label: 'Sign of the Cross', prayerText: _signOfTheCross));

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

List<ChapletPrayerStep> buildStMichaelSteps() {
  final steps = <ChapletPrayerStep>[];
  const totalSalutations = 9;

  steps.add(const ChapletPrayerStep(type: ChapletStepType.signOfCross, label: 'Sign of the Cross', prayerText: _signOfTheCross));

  steps.add(const ChapletPrayerStep(
    type: ChapletStepType.opening,
    label: 'Act of Contrition',
    prayerText: 'O my God, I am heartily sorry for having offended Thee, and I detest all my sins because of Thy just punishments, but most of all because they offend Thee, my God, Who art all-good and deserving of all my love. I firmly resolve, with the help of Thy grace, to sin no more and to avoid the near occasions of sin. Amen.',
  ));

  for (int s = 1; s <= totalSalutations; s++) {
    final choir = _angelChoirs[s - 1];

    // Salutation
    steps.add(ChapletPrayerStep(
      type: ChapletStepType.meditation,
      label: 'Salutation $s — $choir',
      prayerText: 'By the intercession of St. Michael and the celestial choir of $choir, may the Lord grant us the grace to persevere in the faith and to overcome the temptations of the enemy.',
      decadeIndex: s,
      totalDecades: totalSalutations,
    ));

    // Our Father
    steps.add(ChapletPrayerStep(
      type: ChapletStepType.ourFather,
      label: 'Our Father — $choir',
      prayerText: _ourFather,
      decadeIndex: s,
      totalDecades: totalSalutations,
    ));

    // 3 Hail Marys
    for (int h = 1; h <= 3; h++) {
      steps.add(ChapletPrayerStep(
        type: ChapletStepType.hailMary,
        label: 'Hail Mary ($h of 3) — $choir',
        prayerText: _hailMary,
        beadIndex: h,
        totalBeads: 3,
        decadeIndex: s,
        totalDecades: totalSalutations,
      ));
    }

    // Glory Be
    steps.add(ChapletPrayerStep(
      type: ChapletStepType.gloryBe,
      label: 'Glory Be — $choir',
      prayerText: _gloryBe,
      decadeIndex: s,
      totalDecades: totalSalutations,
    ));
  }

  // 4 Our Fathers (for the Archangels: Michael, Gabriel, Raphael, Guardian Angel)
  const archangelNames = ['St. Michael', 'St. Gabriel', 'St. Raphael', 'Our Guardian Angel'];
  for (int i = 0; i < 4; i++) {
    steps.add(ChapletPrayerStep(
      type: ChapletStepType.ourFather,
      label: 'Our Father — ${archangelNames[i]}',
      prayerText: _ourFather,
    ));
  }

  // Closing prayer to St. Michael
  steps.add(const ChapletPrayerStep(
    type: ChapletStepType.closing,
    label: 'Prayer to St. Michael',
    prayerText: 'Saint Michael the Archangel, defend us in battle; be our protection against the wickedness and snares of the devil. May God rebuke him, we humbly pray; and do thou, O Prince of the heavenly host, by the power of God, cast into hell Satan and all the evil spirits who prowl about the world seeking the ruin of souls. Amen.',
  ));

  steps.add(const ChapletPrayerStep(type: ChapletStepType.signOfCross, label: 'Sign of the Cross', prayerText: _signOfTheCross));

  return steps;
}

// ─── St. Jude Chaplet ────────────────────────────────────────────

List<ChapletPrayerStep> buildStJudeSteps() {
  final steps = <ChapletPrayerStep>[];
  const totalDecades = 5;

  steps.add(const ChapletPrayerStep(type: ChapletStepType.signOfCross, label: 'Sign of the Cross', prayerText: _signOfTheCross));
  steps.add(const ChapletPrayerStep(type: ChapletStepType.creed, label: 'Apostles\' Creed', prayerText: _apostlesCreed));
  steps.add(const ChapletPrayerStep(type: ChapletStepType.ourFather, label: 'Our Father', prayerText: _ourFather));

  // 3 Hail Marys
  for (int i = 1; i <= 3; i++) {
    steps.add(ChapletPrayerStep(
      type: ChapletStepType.hailMary,
      label: 'Hail Mary ($i of 3)',
      prayerText: _hailMary,
      beadIndex: i,
      totalBeads: 3,
    ));
  }

  steps.add(const ChapletPrayerStep(type: ChapletStepType.gloryBe, label: 'Glory Be', prayerText: _gloryBe));

  // 5 Decades
  const meditations = [
    'St. Jude, faithful servant of God',
    'St. Jude, apostle of Christ',
    'St. Jude, helper in desperate cases',
    'St. Jude, patron of the impossible',
    'St. Jude, intercessor for the hopeless',
  ];

  for (int d = 1; d <= totalDecades; d++) {
    steps.add(ChapletPrayerStep(
      type: ChapletStepType.meditation,
      label: 'Decade $d — ${meditations[d - 1]}',
      prayerText: meditations[d - 1],
      decadeIndex: d,
      totalDecades: totalDecades,
    ));

    // Our Father
    steps.add(ChapletPrayerStep(
      type: ChapletStepType.ourFather,
      label: 'Our Father — Decade $d',
      prayerText: _ourFather,
      decadeIndex: d,
      totalDecades: totalDecades,
    ));

    // 10 Hail Marys with "St. Jude, pray for us"
    for (int h = 1; h <= 10; h++) {
      steps.add(ChapletPrayerStep(
        type: ChapletStepType.hailMary,
        label: 'Hail Mary ($h of 10) — Decade $d',
        prayerText: '$_hailMary\n\nSt. Jude, apostle and martyr, pray for us.',
        beadIndex: h,
        totalBeads: 10,
        decadeIndex: d,
        totalDecades: totalDecades,
      ));
    }

    // Glory Be
    steps.add(ChapletPrayerStep(
      type: ChapletStepType.gloryBe,
      label: 'Glory Be — Decade $d',
      prayerText: _gloryBe,
      decadeIndex: d,
      totalDecades: totalDecades,
    ));
  }

  // Closing prayer to St. Jude
  steps.add(const ChapletPrayerStep(
    type: ChapletStepType.closing,
    label: 'Prayer to St. Jude',
    prayerText: 'O most holy Apostle, St. Jude, faithful servant and friend of Jesus, the Church honors and invokes thee universally, as the patron of hopeless cases, and of things despaired of. Pray for me, who am so miserable. Make use, I implore thee, of that particular privilege accorded to thee, to bring visible and speedy help where help was almost despaired of. Come to my assistance in this great need, that I may receive the consolation and succor of Heaven in all my necessities, tribulations, and sufferings, particularly [mention your request], and that I may praise God with thee and all the elect throughout all eternity. I promise thee, O blessed Jude, to be ever mindful of this great favor, and I will never cease to honor thee as my special and powerful patron, and to do all in my power to encourage devotion to thee. Amen.',
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

List<ChapletPrayerStep> buildSacredHeartSteps() {
  final steps = <ChapletPrayerStep>[];
  const totalDecades = 5;

  steps.add(const ChapletPrayerStep(type: ChapletStepType.signOfCross, label: 'Sign of the Cross', prayerText: _signOfTheCross));

  steps.add(const ChapletPrayerStep(
    type: ChapletStepType.opening,
    label: 'Act of Consecration',
    prayerText: 'O Sacred Heart of Jesus, I consecrate myself to Thee, and I give myself entirely to the love of Thy burning Heart. I adore Thee in the Most Blessed Sacrament, and I desire to make reparation for all the outrages which Thou receivest from ungrateful souls. Amen.',
  ));

  steps.add(const ChapletPrayerStep(type: ChapletStepType.ourFather, label: 'Our Father', prayerText: _ourFather));

  for (int i = 1; i <= 3; i++) {
    steps.add(ChapletPrayerStep(
      type: ChapletStepType.hailMary,
      label: 'Hail Mary ($i of 3)',
      prayerText: _hailMary,
      beadIndex: i,
      totalBeads: 3,
    ));
  }

  steps.add(const ChapletPrayerStep(type: ChapletStepType.gloryBe, label: 'Glory Be', prayerText: _gloryBe));

  for (int d = 1; d <= totalDecades; d++) {
    steps.add(ChapletPrayerStep(
      type: ChapletStepType.meditation,
      label: 'Decade $d — ${_sacredHeartMeditations[d - 1]}',
      prayerText: _sacredHeartMeditations[d - 1],
      decadeIndex: d,
      totalDecades: totalDecades,
    ));

    steps.add(ChapletPrayerStep(
      type: ChapletStepType.ourFather,
      label: 'Our Father — Decade $d',
      prayerText: _ourFather,
      decadeIndex: d,
      totalDecades: totalDecades,
    ));

    for (int h = 1; h <= 10; h++) {
      steps.add(ChapletPrayerStep(
        type: ChapletStepType.hailMary,
        label: 'Hail Mary ($h of 10) — Decade $d',
        prayerText: _hailMary,
        beadIndex: h,
        totalBeads: 10,
        decadeIndex: d,
        totalDecades: totalDecades,
      ));
    }

    steps.add(ChapletPrayerStep(
      type: ChapletStepType.gloryBe,
      label: 'Glory Be — Decade $d',
      prayerText: _gloryBe,
      decadeIndex: d,
      totalDecades: totalDecades,
    ));

    steps.add(ChapletPrayerStep(
      type: ChapletStepType.customPrayer,
      label: 'Ejaculatory Prayer — Decade $d',
      prayerText: 'Jesus, meek and humble of heart, make my heart like unto Thine.',
      decadeIndex: d,
      totalDecades: totalDecades,
    ));
  }

  steps.add(const ChapletPrayerStep(
    type: ChapletStepType.closing,
    label: 'Closing Prayer',
    prayerText: 'O Divine Heart of Jesus, I offer Thee all the love, gratitude, and reparation which the hearts of all the redeemed can possibly offer Thee. I unite this offering to the love of the Sacred Heart of Jesus, which is never exhausted. May the most Sacred Heart of Jesus be loved everywhere. Amen.',
  ));

  steps.add(const ChapletPrayerStep(type: ChapletStepType.signOfCross, label: 'Sign of the Cross', prayerText: _signOfTheCross));

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

List<ChapletPrayerStep> buildHolySpiritSteps() {
  final steps = <ChapletPrayerStep>[];
  const totalDecades = 7;

  steps.add(const ChapletPrayerStep(type: ChapletStepType.signOfCross, label: 'Sign of the Cross', prayerText: _signOfTheCross));

  steps.add(const ChapletPrayerStep(
    type: ChapletStepType.opening,
    label: 'Come, Holy Spirit',
    prayerText: 'Come, O Holy Spirit, fill the hearts of Thy faithful, and kindle in them the fire of Thy love. Send forth Thy Spirit, and they shall be created; and Thou shalt renew the face of the earth. O God, Who by the light of the Holy Spirit didst instruct the hearts of the faithful, grant that by the same Holy Spirit we may be truly wise, and ever enjoy His consolations. Through Christ our Lord. Amen.',
  ));

  // Our Father and Glory Be before the decades
  steps.add(const ChapletPrayerStep(type: ChapletStepType.ourFather, label: 'Our Father', prayerText: _ourFather));
  steps.add(const ChapletPrayerStep(type: ChapletStepType.gloryBe, label: 'Glory Be', prayerText: _gloryBe));

  for (int d = 1; d <= totalDecades; d++) {
    steps.add(ChapletPrayerStep(
      type: ChapletStepType.meditation,
      label: 'Decade $d — ${_holySpiritGifts[d - 1]}',
      prayerText: '${_holySpiritGifts[d - 1]}\n\n${_holySpiritGiftDescs[d - 1]}',
      decadeIndex: d,
      totalDecades: totalDecades,
    ));

    // Our Father
    steps.add(ChapletPrayerStep(
      type: ChapletStepType.ourFather,
      label: 'Our Father — ${_holySpiritGifts[d - 1]}',
      prayerText: _ourFather,
      decadeIndex: d,
      totalDecades: totalDecades,
    ));

    // 7 Hail Marys (for 7 gifts)
    for (int h = 1; h <= 7; h++) {
      steps.add(ChapletPrayerStep(
        type: ChapletStepType.hailMary,
        label: 'Hail Mary ($h of 7) — ${_holySpiritGifts[d - 1]}',
        prayerText: _hailMary,
        beadIndex: h,
        totalBeads: 7,
        decadeIndex: d,
        totalDecades: totalDecades,
      ));
    }

    // Glory Be
    steps.add(ChapletPrayerStep(
      type: ChapletStepType.gloryBe,
      label: 'Glory Be — ${_holySpiritGifts[d - 1]}',
      prayerText: _gloryBe,
      decadeIndex: d,
      totalDecades: totalDecades,
    ));
  }

  steps.add(const ChapletPrayerStep(
    type: ChapletStepType.closing,
    label: 'Closing Prayer',
    prayerText: 'O God, Who by the light of the Holy Spirit didst instruct the hearts of the faithful, grant that by the same Holy Spirit we may be truly wise, and ever enjoy His consolations. Through Christ our Lord. Amen. Come, Holy Spirit, fill the hearts of Thy faithful and kindle in them the fire of Thy love. Amen.',
  ));

  steps.add(const ChapletPrayerStep(type: ChapletStepType.signOfCross, label: 'Sign of the Cross', prayerText: _signOfTheCross));

  return steps;
}

// ─── Holy Spirit Chaplet (7 Beads) ──────────────────────────────

List<ChapletPrayerStep> buildHolySpirit7BeadsSteps() {
  final steps = <ChapletPrayerStep>[];

  steps.add(const ChapletPrayerStep(type: ChapletStepType.signOfCross, label: 'Sign of the Cross', prayerText: _signOfTheCross));

  steps.add(const ChapletPrayerStep(
    type: ChapletStepType.opening,
    label: 'Come, Holy Spirit',
    prayerText: 'Come, O Holy Spirit, fill the hearts of Thy faithful, and kindle in them the fire of Thy love. Send forth Thy Spirit, and they shall be created; and Thou shalt renew the face of the earth. Amen.',
  ));

  // Act of Consecration
  steps.add(const ChapletPrayerStep(
    type: ChapletStepType.opening,
    label: 'Act of Consecration',
    prayerText: 'O Holy Spirit, I consecrate myself to Thee. Come and take possession of my soul, and make of it Thy temple and Thy dwelling. Fill my heart with Thy love, my mind with Thy light, and my will with Thy strength. Amen.',
  ));

  // 7 beads — one for each gift
  for (int i = 0; i < 7; i++) {
    steps.add(ChapletPrayerStep(
      type: ChapletStepType.meditation,
      label: _holySpiritGifts[i],
      prayerText: '${_holySpiritGifts[i]}\n\n${_holySpiritGiftDescs[i]}',
      decadeIndex: i + 1,
      totalDecades: 7,
    ));

    steps.add(ChapletPrayerStep(
      type: ChapletStepType.ourFather,
      label: 'Our Father — ${_holySpiritGifts[i]}',
      prayerText: _ourFather,
      decadeIndex: i + 1,
      totalDecades: 7,
    ));

    steps.add(ChapletPrayerStep(
      type: ChapletStepType.gloryBe,
      label: 'Glory Be — ${_holySpiritGifts[i]}',
      prayerText: _gloryBe,
      decadeIndex: i + 1,
      totalDecades: 7,
    ));
  }

  steps.add(const ChapletPrayerStep(
    type: ChapletStepType.closing,
    label: 'Closing Prayer',
    prayerText: 'O God, Who by the light of the Holy Spirit didst instruct the hearts of the faithful, grant that by the same Holy Spirit we may be truly wise, and ever enjoy His consolations. Through Christ our Lord. Amen. Come, Holy Spirit, fill the hearts of Thy faithful and kindle in them the fire of Thy love. Amen.',
  ));

  steps.add(const ChapletPrayerStep(type: ChapletStepType.signOfCross, label: 'Sign of the Cross', prayerText: _signOfTheCross));

  return steps;
}

// ─── Builder function ────────────────────────────────────────────

List<ChapletPrayerStep> buildChapletSteps(ChapletId id) {
  switch (id) {
    case ChapletId.divineMercy:
      return buildDivineMercySteps();
    case ChapletId.sevenSorrows:
      return buildSevenSorrowsSteps();
    case ChapletId.stMichael:
      return buildStMichaelSteps();
    case ChapletId.stJude:
      return buildStJudeSteps();
    case ChapletId.sacredHeart:
      return buildSacredHeartSteps();
    case ChapletId.holySpirit:
      return buildHolySpiritSteps();
    case ChapletId.holySpirit7Beads:
      return buildHolySpirit7BeadsSteps();
  }
}

ChapletMeta getChapletMeta(ChapletId id) {
  return chapletList.firstWhere((m) => m.id == id);
}
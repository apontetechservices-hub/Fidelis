/// Stations of the Cross — prayer content data
///
/// Two methods:
/// 1. St. Francis of Assisi (standard, most common)
/// 2. Traditional (with Stabat Mater, pre-1955 form)

// ============================================================
// Station titles (shared by both methods)
// ============================================================

class StationInfo {
  final int number;
  final String title;
  final String titleLa; // Latin title
  final String meditation; // Short meditation prompt

  const StationInfo({
    required this.number,
    required this.title,
    required this.titleLa,
    required this.meditation,
  });
}

const List<StationInfo> stationInfo = [
  StationInfo(
    number: 1,
    title: 'Jesus is Condemned to Death',
    titleLa: 'Iesus ad mortem damnatur',
    meditation: 'Jesus stands silent before Pilate. He accepts the unjust sentence for our sake.',
  ),
  StationInfo(
    number: 2,
    title: 'Jesus Carries His Cross',
    titleLa: 'Iesus crucem suam baiulat',
    meditation: 'Jesus takes up the heavy Cross. He carries the weight of our sins.',
  ),
  StationInfo(
    number: 3,
    title: 'Jesus Falls the First Time',
    titleLa: 'Iesus primum cadit',
    meditation: 'Jesus falls under the weight of the Cross. He rises again for us.',
  ),
  StationInfo(
    number: 4,
    title: 'Jesus Meets His Mother',
    titleLa: 'Iesus Matrem suam occurrit',
    meditation: 'Mary meets her Son on the way of sorrow. Their hearts are pierced with grief.',
  ),
  StationInfo(
    number: 5,
    title: 'Simon of Cyrene Helps Jesus',
    titleLa: 'Simon Cyrenaeus Iesu adjuvat',
    meditation: 'Simon is forced to help carry the Cross. We too are called to bear one another\'s burdens.',
  ),
  StationInfo(
    number: 6,
    title: 'Veronica Wipes the Face of Jesus',
    titleLa: 'Veronica faciem Iesu terget',
    meditation: 'Veronica steps forward with courage and compassion. She is rewarded with His holy image.',
  ),
  StationInfo(
    number: 7,
    title: 'Jesus Falls the Second Time',
    titleLa: 'Iesus secundo cadit',
    meditation: 'Jesus falls again, exhausted. He rises once more, sustained by love.',
  ),
  StationInfo(
    number: 8,
    title: 'Jesus Meets the Women of Jerusalem',
    titleLa: 'Iesus mulieres Hierosolymitanas occurrit',
    meditation: 'Jesus comforts the weeping women. He turns their grief toward repentance.',
  ),
  StationInfo(
    number: 9,
    title: 'Jesus Falls the Third Time',
    titleLa: 'Iesus tertio cadit',
    meditation: 'Jesus falls a third time, nearly spent. Yet He will not give up.',
  ),
  StationInfo(
    number: 10,
    title: 'Jesus is Stripped of His Garments',
    titleLa: 'Iesus vestimentis spoliatur',
    meditation: 'Jesus is stripped and exposed. He endures this humiliation for our sake.',
  ),
  StationInfo(
    number: 11,
    title: 'Jesus is Nailed to the Cross',
    titleLa: 'Iesus cruci affigitur',
    meditation: 'The nails pierce His hands and feet. Every blow is borne in love.',
  ),
  StationInfo(
    number: 12,
    title: 'Jesus Dies on the Cross',
    titleLa: 'Iesus in cruce moritur',
    meditation: 'Jesus breathes His last. The Son of God gives His life for the world.',
  ),
  StationInfo(
    number: 13,
    title: 'Jesus is Taken Down from the Cross',
    titleLa: 'Iesus de cruce deponitur',
    meditation: 'Mary receives the lifeless body of her Son. Her sorrow is beyond words.',
  ),
  StationInfo(
    number: 14,
    title: 'Jesus is Laid in the Tomb',
    titleLa: 'Iesus in sepulcro ponitur',
    meditation: 'Jesus is laid to rest. The stone is rolled shut. Holy Saturday begins.',
  ),
];

// ============================================================
// Method: St. Francis of Assisi
// ============================================================

class StFrancisStation {
  final int stationNumber;
  final String leader; // V.
  final String response; // R.
  final String prayer;
  final String closingPrayer;

  const StFrancisStation({
    required this.stationNumber,
    required this.leader,
    required this.response,
    required this.prayer,
    required this.closingPrayer,
  });
}

const String stFrancisIntro = '''
We adore Thee, O Christ, and we bless Thee.
Because by Thy holy Cross Thou hast redeemed the world.''';

const List<StFrancisStation> stFrancisStations = [
  StFrancisStation(
    stationNumber: 1,
    leader: 'V. We adore Thee, O Christ, and we bless Thee.',
    response: 'R. Because by Thy holy Cross Thou hast redeemed the world.',
    prayer: 'Consider how Jesus, after having been scourged and crowned with thorns, was unjustly condemned by Pilate to die on the Cross. My Jesus, the world still condemns Thee. I am sorry for having offended Thee. I love Thee with my whole heart.',
    closingPrayer: 'I love Thee, my Jesus, with my whole heart; I am sorry for having offended Thee. I will never offend Thee again. Amen.',
  ),
  StFrancisStation(
    stationNumber: 2,
    leader: 'V. We adore Thee, O Christ, and we bless Thee.',
    response: 'R. Because by Thy holy Cross Thou hast redeemed the world.',
    prayer: 'Consider Jesus as He walked with the heavy Cross on His shoulders, thinking of us and offering to His Father the death He was about to suffer. My Jesus, I take up my cross and follow Thee.',
    closingPrayer: 'I love Thee, my Jesus, with my whole heart; I am sorry for having offended Thee. I will never offend Thee again. Amen.',
  ),
  StFrancisStation(
    stationNumber: 3,
    leader: 'V. We adore Thee, O Christ, and we bless Thee.',
    response: 'R. Because by Thy holy Cross Thou hast redeemed the world.',
    prayer: 'Consider the first fall of Jesus under the Cross. The weight was so great that He fell to the ground. My Jesus, I fall often, but with Thy grace I will rise again.',
    closingPrayer: 'I love Thee, my Jesus, with my whole heart; I am sorry for having offended Thee. I will never offend Thee again. Amen.',
  ),
  StFrancisStation(
    stationNumber: 4,
    leader: 'V. We adore Thee, O Christ, and we bless Thee.',
    response: 'R. Because by Thy holy Cross Thou hast redeemed the world.',
    prayer: 'Consider the meeting of Jesus and Mary. What a bitter grief it was for Mary to see her divine Son suffering! My Jesus, by this sorrow, give me the grace of a true devotion to Thy holy Mother.',
    closingPrayer: 'I love Thee, my Jesus, with my whole heart; I am sorry for having offended Thee. I will never offend Thee again. Amen.',
  ),
  StFrancisStation(
    stationNumber: 5,
    leader: 'V. We adore Thee, O Christ, and we bless Thee.',
    response: 'R. Because by Thy holy Cross Thou hast redeemed the world.',
    prayer: 'Consider how Simon was forced to help Jesus carry the Cross. My Jesus, Simon was compelled to help Thee; may I willingly take up my cross and follow Thee.',
    closingPrayer: 'I love Thee, my Jesus, with my whole heart; I am sorry for having offended Thee. I will never offend Thee again. Amen.',
  ),
  StFrancisStation(
    stationNumber: 6,
    leader: 'V. We adore Thee, O Christ, and we bless Thee.',
    response: 'R. Because by Thy holy Cross Thou hast redeemed the world.',
    prayer: 'Consider the compassion of Veronica, who wiped the face of Jesus with her veil. My Jesus, may I, like Veronica, be devoted to Thee and bear Thy image in my soul.',
    closingPrayer: 'I love Thee, my Jesus, with my whole heart; I am sorry for having offended Thee. I will never offend Thee again. Amen.',
  ),
  StFrancisStation(
    stationNumber: 7,
    leader: 'V. We adore Thee, O Christ, and we bless Thee.',
    response: 'R. Because by Thy holy Cross Thou hast redeemed the world.',
    prayer: 'Consider the second fall of Jesus under the Cross. The soldiers roughly dragged Him to His feet. My Jesus, I too have fallen again. Give me strength to rise and follow Thee.',
    closingPrayer: 'I love Thee, my Jesus, with my whole heart; I am sorry for having offended Thee. I will never offend Thee again. Amen.',
  ),
  StFrancisStation(
    stationNumber: 8,
    leader: 'V. We adore Thee, O Christ, and we bless Thee.',
    response: 'R. Because by Thy holy Cross Thou hast redeemed the world.',
    prayer: 'Consider how Jesus met the women of Jerusalem, who wept for Him. He told them not to weep for Him but for their sins. My Jesus, grant me the grace of true compunction.',
    closingPrayer: 'I love Thee, my Jesus, with my whole heart; I am sorry for having offended Thee. I will never offend Thee again. Amen.',
  ),
  StFrancisStation(
    stationNumber: 9,
    leader: 'V. We adore Thee, O Christ, and we bless Thee.',
    response: 'R. Because by Thy holy Cross Thou hast redeemed the world.',
    prayer: 'Consider the third fall of Jesus. He fell a third time, exhausted and in agony. My Jesus, when I am near despair, give me the grace to rise again.',
    closingPrayer: 'I love Thee, my Jesus, with my whole heart; I am sorry for having offended Thee. I will never offend Thee again. Amen.',
  ),
  StFrancisStation(
    stationNumber: 10,
    leader: 'V. We adore Thee, O Christ, and we bless Thee.',
    response: 'R. Because by Thy holy Cross Thou hast redeemed the world.',
    prayer: 'Consider how Jesus was stripped of His garments. They took even His clothing, leaving Him in shame and pain. My Jesus, strip me of my attachments and clothe me in Thy grace.',
    closingPrayer: 'I love Thee, my Jesus, with my whole heart; I am sorry for having offended Thee. I will never offend Thee again. Amen.',
  ),
  StFrancisStation(
    stationNumber: 11,
    leader: 'V. We adore Thee, O Christ, and we bless Thee.',
    response: 'R. Because by Thy holy Cross Thou hast redeemed the world.',
    prayer: 'Consider how Jesus was nailed to the Cross. Each nail pierced His sacred flesh. My Jesus, nail my heart to Thee, that I may never leave Thee.',
    closingPrayer: 'I love Thee, my Jesus, with my whole heart; I am sorry for having offended Thee. I will never offend Thee again. Amen.',
  ),
  StFrancisStation(
    stationNumber: 12,
    leader: 'V. We adore Thee, O Christ, and we bless Thee.',
    response: 'R. Because by Thy holy Cross Thou hast redeemed the world.',
    prayer: 'Consider how Jesus hung on the Cross for three hours, suffering agony before His death. My Jesus, by Thy three hours of agony, have mercy on us.',
    closingPrayer: 'I love Thee, my Jesus, with my whole heart; I am sorry for having offended Thee. I will never offend Thee again. Amen.',
  ),
  StFrancisStation(
    stationNumber: 13,
    leader: 'V. We adore Thee, O Christ, and we bless Thee.',
    response: 'R. Because by Thy holy Cross Thou hast redeemed the world.',
    prayer: 'Consider how the body of Jesus was taken down from the Cross and placed in the arms of His Mother. My Jesus, by the sorrow of Mary, grant me the grace of a holy death.',
    closingPrayer: 'I love Thee, my Jesus, with my whole heart; I am sorry for having offended Thee. I will never offend Thee again. Amen.',
  ),
  StFrancisStation(
    stationNumber: 14,
    leader: 'V. We adore Thee, O Christ, and we bless Thee.',
    response: 'R. Because by Thy holy Cross Thou hast redeemed the world.',
    prayer: 'Consider how the body of Jesus was laid in the tomb. His enemies thought they had conquered, but He would rise in glory. My Jesus, I await Thy Resurrection with hope.',
    closingPrayer: 'I love Thee, my Jesus, with my whole heart; I am sorry for having offended Thee. I will never offend Thee again. Amen.',
  ),
];

const String stFrancisClosing = '''
O God, who by the Precious Blood of Thy only-begotten Son
didst sanctify the standard of the Cross,
grant, we beseech Thee, that they who rejoice
in honoring that same holy Cross
may also everywhere rejoice in Thy protection.
Through the same Christ our Lord. Amen.

May the souls of the faithful departed, through the mercy of God, rest in peace. Amen.''';

// ============================================================
// Method: Traditional (with Stabat Mater)
// ============================================================

class TraditionalStation {
  final int stationNumber;
  final String leader; // V.
  final String response; // R.
  final String prayer;
  final String stabatMaterVerse; // One verse of Stabat Mater per station

  const TraditionalStation({
    required this.stationNumber,
    required this.leader,
    required this.response,
    required this.prayer,
    required this.stabatMaterVerse,
  });
}

const String traditionalIntro = '''
V. We adore Thee, O Christ, and we bless Thee.
R. Because by Thy holy Cross Thou hast redeemed the world.

O Lord Jesus Christ, we come before Thee to walk the Way of the Cross.
Grant that by Thy grace we may contemplate Thy sacred Passion
and be worthy to share in the fruits of Thy redemption.''';

const List<TraditionalStation> traditionalStations = [
  TraditionalStation(
    stationNumber: 1,
    leader: 'V. We adore Thee, O Christ, and we bless Thee.',
    response: 'R. Because by Thy holy Cross Thou hast redeemed the world.',
    prayer: 'Almighty and everlasting God, who didst will that Thy Son should suffer for us, grant that we may bear our cross after Him and so share in His glory. Through the same Christ our Lord. Amen.',
    stabatMaterVerse: 'Stabat Mater dolorosa,\nJuxta crucem lacrimosa,\nDum pendebat Filius.',
  ),
  TraditionalStation(
    stationNumber: 2,
    leader: 'V. We adore Thee, O Christ, and we bless Thee.',
    response: 'R. Because by Thy holy Cross Thou hast redeemed the world.',
    prayer: 'Lord Jesus, who didst carry the heavy Cross for our salvation, grant us strength to carry our crosses with patience and love. Who livest and reignest forever. Amen.',
    stabatMaterVerse: 'Cuius animam gementem,\nContristatam et dolentem,\nPertransivit gladius.',
  ),
  TraditionalStation(
    stationNumber: 3,
    leader: 'V. We adore Thee, O Christ, and we bless Thee.',
    response: 'R. Because by Thy holy Cross Thou hast redeemed the world.',
    prayer: 'Lord Jesus, who didst fall under the Cross and rise again, raise us when we fall through sin, and strengthen us against temptation. Who livest and reignest forever. Amen.',
    stabatMaterVerse: 'O quam tristis et afflicta\nFuit illa benedicta\nMater Unigeniti!',
  ),
  TraditionalStation(
    stationNumber: 4,
    leader: 'V. We adore Thee, O Christ, and we bless Thee.',
    response: 'R. Because by Thy holy Cross Thou hast redeemed the world.',
    prayer: 'Lord Jesus, who didst meet Thy sorrowful Mother on the way of the Cross, grant that we may have true devotion to her who stood by Thee in Thy agony. Who livest and reignest forever. Amen.',
    stabatMaterVerse: 'Quae maerebat et dolebat,\nPia Mater, cum videbat\nNati poenas incliti.',
  ),
  TraditionalStation(
    stationNumber: 5,
    leader: 'V. We adore Thee, O Christ, and we bless Thee.',
    response: 'R. Because by Thy holy Cross Thou hast redeemed the world.',
    prayer: 'Lord Jesus, who didst accept the help of Simon, teach us to assist one another in bearing our burdens and to serve Thee in our neighbor. Who livest and reignest forever. Amen.',
    stabatMaterVerse: 'Quis est homo qui non fleret,\nMatrem Christi si videret\nIn tanto supplicio?',
  ),
  TraditionalStation(
    stationNumber: 6,
    leader: 'V. We adore Thee, O Christ, and we bless Thee.',
    response: 'R. Because by Thy holy Cross Thou hast redeemed the world.',
    prayer: 'Lord Jesus, who didst leave the imprint of Thy face on Veronica\'s veil, imprint Thy image on our hearts, that we may never lose Thee. Who livest and reignest forever. Amen.',
    stabatMaterVerse: 'Quis non posset contristari,\nChristi Matrem contemplari\nDolentem cum Filio?',
  ),
  TraditionalStation(
    stationNumber: 7,
    leader: 'V. We adore Thee, O Christ, and we bless Thee.',
    response: 'R. Because by Thy holy Cross Thou hast redeemed the world.',
    prayer: 'Lord Jesus, who didst fall again under the Cross, grant us the grace of perseverance, that we may never despair but always rise again through Thy mercy. Who livest and reignest forever. Amen.',
    stabatMaterVerse: 'Pro peccatis suae gentis,\nIesum vidit in tormentis,\nEt flagillis saeviter.',
  ),
  TraditionalStation(
    stationNumber: 8,
    leader: 'V. We adore Thee, O Christ, and we bless Thee.',
    response: 'R. Because by Thy holy Cross Thou hast redeemed the world.',
    prayer: 'Lord Jesus, who didst console the weeping women, grant us tears of true repentance and a contrite heart. Who livest and reignest forever. Amen.',
    stabatMaterVerse: 'Vidit Iesum suum dulcem\nExspirantem, quem dabat,\nDum emisit spiritum.',
  ),
  TraditionalStation(
    stationNumber: 9,
    leader: 'V. We adore Thee, O Christ, and we bless Thee.',
    response: 'R. Because by Thy holy Cross Thou hast redeemed the world.',
    prayer: 'Lord Jesus, who didst fall a third time, utterly exhausted, give us grace to rise from our falls and persevere in following Thee to the end. Who livest and reignest forever. Amen.',
    stabatMaterVerse: 'Eia, Mater, fons amoris,\nMe sentire vim doloris\nFac, ut tecum lugeam.',
  ),
  TraditionalStation(
    stationNumber: 10,
    leader: 'V. We adore Thee, O Christ, and we bless Thee.',
    response: 'R. Because by Thy holy Cross Thou hast redeemed the world.',
    prayer: 'Lord Jesus, who wast stripped of Thy garments, strip us of all attachment to sin and clothe us in Thy righteousness. Who livest and reignest forever. Amen.',
    stabatMaterVerse: 'Fac, ut ardeat cor meum\nIn amando Christum Deum,\nUt sibi complaceam.',
  ),
  TraditionalStation(
    stationNumber: 11,
    leader: 'V. We adore Thee, O Christ, and we bless Thee.',
    response: 'R. Because by Thy holy Cross Thou hast redeemed the world.',
    prayer: 'Lord Jesus, who wast nailed to the Cross for our sins, nail our hearts to Thee with the nails of Thy love. Who livest and reignest forever. Amen.',
    stabatMaterVerse: 'Sancta Mater, istud agas,\nCrucifixi fige plagas\nCordi meo valide.',
  ),
  TraditionalStation(
    stationNumber: 12,
    leader: 'V. We adore Thee, O Christ, and we bless Thee.',
    response: 'R. Because by Thy holy Cross Thou hast redeemed the world.',
    prayer: 'Lord Jesus, who didst die upon the Cross for our salvation, grant that we may die to sin and live for Thee. Who livest and reignest forever. Amen.',
    stabatMaterVerse: 'Tui Nati vulnerati,\nTam dignati pro me pati,\nPoenas mecum divide.',
  ),
  TraditionalStation(
    stationNumber: 13,
    leader: 'V. We adore Thee, O Christ, and we bless Thee.',
    response: 'R. Because by Thy holy Cross Thou hast redeemed the world.',
    prayer: 'Lord Jesus, whose body was taken down and laid in the arms of Thy Mother, grant us the grace of a holy death and the consolation of Thy presence at our last hour. Who livest and reignest forever. Amen.',
    stabatMaterVerse: 'Fac me tecum pie flere,\nCrucifixo condolere,\nDonec ego vixero.',
  ),
  TraditionalStation(
    stationNumber: 14,
    leader: 'V. We adore Thee, O Christ, and we bless Thee.',
    response: 'R. Because by Thy holy Cross Thou hast redeemed the world.',
    prayer: 'Lord Jesus, who wast laid in the tomb, grant that we may await the Resurrection with living faith and hope in Thee. Who livest and reignest forever. Amen.',
    stabatMaterVerse: 'Iuxta Crucem tecum stare,\nEt me tibi sociare\nIn planctu desidero.',
  ),
];

const String traditionalClosing = '''
V. Christ became obedient for us unto death.
R. Even the death of the Cross.

V. We pray Thee, O Lord, that we who have walked the Way of the Cross may be worthy to share in the glory of Thy Resurrection.
R. Amen.

May the souls of the faithful departed, through the mercy of God, rest in peace. Amen.''';

// Full Stabat Mater hymn (all verses, Latin + English)
const String stabatMaterFullLatin = '''Stabat Mater dolorosa,
Juxta crucem lacrimosa,
Dum pendebat Filius.

Cuius animam gementem,
Contristatam et dolentem,
Pertransivit gladius.

O quam tristis et afflicta
Fuit illa benedicta
Mater Unigeniti!

Quae maerebat et dolebat,
Pia Mater, cum videbat
Nati poenas incliti.

Quis est homo qui non fleret,
Matrem Christi si videret
In tanto supplicio?

Quis non posset contristari,
Christi Matrem contemplari
Dolentem cum Filio?

Pro peccatis suae gentis
Iesum vidit in tormentis
Et flagillis saeviter.

Vidit Iesum suum dulcem
Exspirantem, quem dabat
Dum emisit spiritum.

Eia, Mater, fons amoris,
Me sentire vim doloris
Fac, ut tecum lugeam.

Fac, ut ardeat cor meum
In amando Christum Deum,
Ut sibi complaceam.

Sancta Mater, istud agas,
Crucifixi fige plagas
Cordi meo valide.

Tui Nati vulnerati,
Tam dignati pro me pati,
Poenas mecum divide.

Fac me tecum pie flere,
Crucifixo condolere,
Donec ego vixero.

Iuxta Crucem tecum stare,
Et me tibi sociare
In planctu desidero.

Virgo virorum praeclara,
Mihi iam non sis amara,
Fac me tecum plangere.

Fac, ut portem Christi mortem,
Passionis fac consortem,
Et plagas recolere.

Fac me plagis vulnerari,
Cruce hoc inebriari,
Ob amorem Filii.

Inflammatus et accensus
Per te, Virgo, sim defensus
In die iudicii.

Fac me cruce custodiri,
Morte Christi praemuniri,
Confoveri gratia.

Quando corpus morietur,
Fac ut animae donetur
Paradisi gloria. Amen.''';

const String stabatMaterFullEnglish = '''At the Cross her station keeping,
Stood the mournful Mother weeping,
Close to Jesus at the last.

Through her heart, His sorrow sharing,
All His bitter anguish bearing,
Now at length the sword has passed.

O how sad and sore distressed
Was that Mother highly blessed
Of the sole-begotten One!

Christ above in torment hangs;
She beneath beholds the pangs
Of her dying, glorious Son.

Is there one who would not weep,
Whelmed in miseries so deep
Christ's dear Mother to behold?

Can the human heart refrain
From partaking in her pain,
In that Mother's pain untold?

Bruised, derided, cursed, defiled,
She beheld her tender Child
All with bloody scourges rent.

For the sins of His own nation,
She saw Jesus' tribulation,
Till His Spirit forth He sent.

Fount of love, O Mother, make me
Feel the depth of sorrow's aching;
Make me share thy sorrow's weight.

Make my heart to burn with love,
Christ my God, to please above,
Who for me such pain endured.

Holy Mother, thus ordain me;
Deep within my heart sustain me
Wounds of Jesus crucified.

Of His wounded Soul divided,
Who for me so long has sighed,
Share the bitter pain with me.

Make me truly, truly mourn thee,
With the Crucified adore thee,
While my life endures on earth.

By the Cross with thee to stay,
There with thee to weep and pray,
This of thee I ask to give.

Virgin, fairest of all virgins,
Be not now with me a stranger;
Let me share thy grief divine.

Let me bear Christ's dying pangs,
Make me partner in His anguish,
And His wounds keep in my soul.

Wound me with His sacred wounds,
Let His Cross inebriate me,
For the love of God's own Son.

Burnished by the fire of love,
By thy grace, O Virgin, shield me
On the judgment's final day.

Guard me by the Cross's shelter,
Arm me with Christ's death to save me,
Nourish me with grace divine.

When this body yields to death,
Grant to my poor soul that breath
Of paradise may be mine. Amen.''';

/// Our Father, Hail Mary, Glory Be (used between stations in both methods)
const String ourFather = 'Our Father, who art in heaven, hallowed be Thy name. Thy kingdom come, Thy will be done, on earth as it is in heaven. Give us this day our daily bread, and forgive us our trespasses, as we forgive those who trespass against us. And lead us not into temptation, but deliver us from evil. Amen.';

const String hailMary = 'Hail Mary, full of grace, the Lord is with thee. Blessed art thou among women, and blessed is the fruit of thy womb, Jesus. Holy Mary, Mother of God, pray for us sinners, now and at the hour of our death. Amen.';

const String gloryBe = 'Glory be to the Father, and to the Son, and to the Holy Spirit. As it was in the beginning, is now, and ever shall be, world without end. Amen.';
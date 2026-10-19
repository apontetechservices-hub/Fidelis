import 'package:flutter/material.dart';

/// Catechetical reference lists — 'A Summary of Catholic Doctrine' transcribed
/// verbatim from the owner's traditional missal (pages 25-28, 2026-10-19).
/// Spanish follows the traditional Catholic forms, parallel to the missal's
/// structure; the Daily Meditation Spanish rendering is flagged for review.
class DoctrineTopic {
  final String id;
  final String title;
  final String titleEs;
  final IconData icon;
  final List<String> items;
  final List<String> itemsEs;

  const DoctrineTopic({
    required this.id,
    required this.title,
    required this.titleEs,
    required this.icon,
    required this.items,
    required this.itemsEs,
  });

  String titleFor(String lang) => lang == 'es' ? titleEs : title;
  List<String> itemsFor(String lang) => lang == 'es' ? itemsEs : items;
}

const List<DoctrineTopic> doctrineTopics = [
  DoctrineTopic(
    id: 'ten_commandments',
    title: 'The Ten Commandments of God',
    titleEs: 'Los Diez Mandamientos de Dios',
    icon: Icons.gavel,
    items: [
      '1.) I am the Lord thy God, Who brought thee out of the land of Egypt, and out of the house of bondage. Thou shalt not have strange Gods before Me. Thou shalt not make to thyself a graven thing, nor the likeness of anything that is in heaven above, or in the earth beneath, nor of those things that are in the waters under the earth. Thou shalt not adore them nor serve them: I am the Lord thy God, mighty, jealous, visiting the iniquity of the fathers upon their children unto the third and fourth generation of them that hate Me; and showing mercy unto thousands to them that love Me, and keep My commandments.',
      '2.) Thou shalt not take the name of the Lord thy God in vain; for the Lord will not hold him guiltless that shall take the name of the Lord his God in vain.',
      '3.) Remember that thou keep holy the Sabbath day. Six days shalt thou labor, and shalt do all thy works; but on the seventh day is the Sabbath of the Lord thy God; thou shalt do no work on it, thou, nor thy son, nor thy daughter, nor thy manservant, nor thy maidservant, nor thy beast, nor the stranger that is within thy gates. For in six days the Lord made heaven and earth, and the sea, and all things that are in them, and rested on the seventh day, therefore the Lord blessed the seventh day and sanctified it.',
      '4.) Honor thy father and thy mother, that thou mayest be long-lived upon the land which the Lord thy God will give thee.',
      '5.) Thou shalt not kill.',
      '6.) Thou shalt not commit adultery.',
      '7.) Thou shalt not steal.',
      '8.) Thou shalt not bear false witness against thy neighbor.',
      '9.) Thou shalt not covet thy neighbor\'s wife.',
      '10.) Thou shalt not covet thy neighbor\'s house, nor his servant, nor his ox, nor his ass, nor anything that is his.',
    ],
    itemsEs: [
      '1.) Yo soy el Señor tu Dios, que te saqué de la tierra de Egipto, de la casa de servidumbre. No tendrás dioses ajenos delante de mí. No te harás imagen esculpida, ni semejanza de cosa alguna que esté arriba en el cielo, o abajo en la tierra, o en las aguas debajo de la tierra. No las adorarás ni las servirás: yo soy el Señor tu Dios, fuerte, celoso, que castigo la iniquidad de los padres en los hijos hasta la tercera y cuarta generación de los que me aborrecen, y hago misericordia en millares a los que me aman y guardan mis mandamientos.',
      '2.) No tomarás el nombre del Señor tu Dios en vano; porque el Señor no dejará sin castigo al que tomare su nombre en vano.',
      '3.) Acuérdate de santificar el día del sábado. Seis días trabajarás y harás todas tus obras; mas el séptimo día es sábado del Señor tu Dios; no harás en él trabajo alguno, ni tú, ni tu hijo, ni tu hija, ni tu siervo, ni tu criada, ni tu bestia, ni el forastero que está dentro de tus puertas. Porque en seis días hizo el Señor el cielo y la tierra, y el mar, y todas las cosas que hay en ellos, y reposó en el séptimo día; por eso el Señor bendijo el día del sábado y lo santificó.',
      '4.) Honra a tu padre y a tu madre, para que se te prolonguen los días sobre la tierra que el Señor tu Dios te va a dar.',
      '5.) No matarás.',
      '6.) No cometerás adulterio.',
      '7.) No hurtarás.',
      '8.) No dirás falso testimonio contra tu prójimo.',
      '9.) No codiciarás la mujer de tu prójimo.',
      '10.) No codiciarás la casa de tu prójimo, ni su siervo, ni su buey, ni su asno, ni cosa alguna de él.',
    ],
  ),
  DoctrineTopic(
    id: 'six_precepts',
    title: 'The Six Precepts of the Church',
    titleEs: 'Los Seis Preceptos de la Iglesia',
    icon: Icons.rule,
    items: [
      '1.) To hear Mass on Sundays and holydays of obligation.',
      '2.) To fast and abstain on the days commanded.',
      '3.) To confess our sins at least once a year.',
      '4.) To receive the Blessed Eucharist at Easter or within the time appointed.',
      '5.) To contribute to the support of our Pastors.',
      '6.) Not to solemnize marriage at the forbidden times; nor to marry persons within the forbidden degrees of kindred, or otherwise prohibited by the Church, nor secretly.',
    ],
    itemsEs: [
      '1.) Oír Misa todos los domingos y fiestas de guardar.',
      '2.) Ayunar y abstenerse en los días mandados.',
      '3.) Confesarse al menos una vez al año.',
      '4.) Recibir la Sagrada Eucaristía por Pascua, o dentro del tiempo señalado.',
      '5.) Contribuir al sostenimiento de nuestros Pastores.',
      '6.) No casarse en tiempos prohibidos; ni con personas dentro de los grados prohibidos de parentesco, o de otro modo prohibidas por la Iglesia, ni en secreto.',
    ],
  ),
  DoctrineTopic(
    id: 'seven_sacraments',
    title: 'The Seven Sacraments',
    titleEs: 'Los Siete Sacramentos',
    icon: Icons.church,
    items: [
      'Baptism, Confirmation, Holy Eucharist, Penance, Extreme Unction, Holy Orders, Matrimony.',
    ],
    itemsEs: [
      'Bautismo, Confirmación, Sagrada Eucaristía, Penitencia, Extremaunción, Orden Sacerdotal, Matrimonio.',
    ],
  ),
  DoctrineTopic(
    id: 'theological_virtues',
    title: 'The Three Theological Virtues',
    titleEs: 'Las Tres Virtudes Teologales',
    icon: Icons.favorite,
    items: [
      'Faith, Hope, and Charity.',
    ],
    itemsEs: [
      'Fe, Esperanza y Caridad.',
    ],
  ),
  DoctrineTopic(
    id: 'cardinal_virtues',
    title: 'The Four Cardinal Virtues',
    titleEs: 'Las Cuatro Virtudes Cardinales',
    icon: Icons.balance,
    items: [
      'Prudence, Justice, Fortitude, and Temperance.',
    ],
    itemsEs: [
      'Prudencia, Justicia, Fortaleza y Templanza.',
    ],
  ),
  DoctrineTopic(
    id: 'seven_gifts',
    title: 'The Seven Gifts of the Holy Ghost',
    titleEs: 'Los Siete Dones del Espíritu Santo',
    icon: Icons.auto_awesome,
    items: [
      'Wisdom, Understanding, Counsel, Fortitude, Knowledge, Piety, and the Fear of the Lord.',
    ],
    itemsEs: [
      'Sabiduría, Entendimiento, Consejo, Fortaleza, Ciencia, Piedad y Temor de Dios.',
    ],
  ),
  DoctrineTopic(
    id: 'twelve_fruits',
    title: 'The Twelve Fruits of the Holy Ghost',
    titleEs: 'Los Doce Frutos del Espíritu Santo',
    icon: Icons.eco,
    items: [
      'Charity, Joy, Peace, Patience, Longanimity, Goodness, Benignity, Mildness, Fidelity, Modesty, Continence, and Chastity.',
    ],
    itemsEs: [
      'Caridad, Gozo, Paz, Paciencia, Longanimidad, Bondad, Benignidad, Mansedumbre, Fidelidad, Modestia, Continencia y Castidad.',
    ],
  ),
  DoctrineTopic(
    id: 'spiritual_works',
    title: 'The Spiritual Works of Mercy',
    titleEs: 'Las Obras Espirituales de Misericordia',
    icon: Icons.volunteer_activism,
    items: [
      'To give counsel to the doubtful.—To instruct the ignorant.—To admonish sinners.—To comfort the afflicted.—To forgive offenses.—To bear patiently the troublesome.—To pray for the living and the dead.',
    ],
    itemsEs: [
      'Aconsejar al dubitativo.—Enseñar al ignorante.—Corregir al pecador.—Consolar al afligido.—Perdonar las ofensas.—Sufrir con paciencia las flaquezas del prójimo.—Rogar a Dios por los vivos y los difuntos.',
    ],
  ),
  DoctrineTopic(
    id: 'corporal_works',
    title: 'The Corporal Works of Mercy',
    titleEs: 'Las Obras Corporales de Misericordia',
    icon: Icons.restaurant,
    items: [
      'To feed the hungry.—To give drink to the thirsty.—To clothe the naked.—To shelter the needy.—To visit the sick.—To visit the imprisoned.—To bury the dead.',
    ],
    itemsEs: [
      'Dar de comer al hambriento.—Dar de beber al sediento.—Vestir al desnudo.—Dar albergue al necesitado.—Visitar a los enfermos.—Visitar a los cautivos.—Enterrar a los muertos.',
    ],
  ),
  DoctrineTopic(
    id: 'beatitudes',
    title: 'The Eight Beatitudes',
    titleEs: 'Las Ocho Bienaventuranzas',
    icon: Icons.wb_sunny,
    items: [
      '1.) Blessed are the poor in spirit; for theirs is the kingdom of heaven.',
      '2.) Blessed are the meek; for they shall possess the land.',
      '3.) Blessed are they that mourn; for they shall be comforted.',
      '4.) Blessed are they that hunger and thirst after justice; for they shall be filled.',
      '5.) Blessed are the merciful; for they shall obtain mercy.',
      '6.) Blessed are the clean of heart; for they shall see God.',
      '7.) Blessed are the peacemakers; for they shall be called the children of God.',
      '8.) Blessed are they that suffer persecution for justice\' sake; for theirs is the kingdom of heaven.',
    ],
    itemsEs: [
      '1.) Bienaventurados los pobres de espíritu; porque de ellos es el reino de los cielos.',
      '2.) Bienaventurados los mansos; porque ellos poseerán la tierra.',
      '3.) Bienaventurados los que lloran; porque ellos serán consolados.',
      '4.) Bienaventurados los que tienen hambre y sed de justicia; porque ellos serán saciados.',
      '5.) Bienaventurados los misericordiosos; porque ellos alcanzarán misericordia.',
      '6.) Bienaventurados los limpios de corazón; porque ellos verán a Dios.',
      '7.) Bienaventurados los pacificadores; porque ellos serán llamados hijos de Dios.',
      '8.) Bienaventurados los que padecen persecución por la justicia; porque de ellos es el reino de los cielos.',
    ],
  ),
  DoctrineTopic(
    id: 'deadly_sins',
    title: 'The Seven Deadly Sins',
    titleEs: 'Los Siete Pecados Capitales',
    icon: Icons.warning,
    items: [
      'Pride.—Covetousness.—Lust.—Anger.—Gluttony.—Envy.—Sloth.',
    ],
    itemsEs: [
      'Soberbia.—Avaricia.—Lujuria.—Ira.—Gula.—Envidia.—Pereza.',
    ],
  ),
  DoctrineTopic(
    id: 'contrary_virtues',
    title: 'Contrary Virtues',
    titleEs: 'Las Virtudes Contrarias',
    icon: Icons.shield,
    items: [
      'Humility.—Liberality.—Chastity.—Meekness.—Temperance.—Brotherly Love.—Diligence.',
    ],
    itemsEs: [
      'Humildad.—Liberalidad.—Castidad.—Mansedumbre.—Templanza.—Amor Fraterno.—Diligencia.',
    ],
  ),
  DoctrineTopic(
    id: 'sins_holy_ghost',
    title: 'Sins against the Holy Ghost',
    titleEs: 'Los Pecados contra el Espíritu Santo',
    icon: Icons.block,
    items: [
      'Presumption upon God\'s mercy.—Despair.—Impugning the known truth.—Envy of another\'s spiritual good.—Obstinacy in sin.—Final impenitence.',
    ],
    itemsEs: [
      'Presunción de la misericordia de Dios.—Desesperación.—Impugnar la verdad conocida.—Envidiar a otro su bien espiritual.—Obstinación en el pecado.—Impenitencia final.',
    ],
  ),
  DoctrineTopic(
    id: 'sins_crying_heaven',
    title: 'Sins Crying to Heaven for Vengeance',
    titleEs: 'Los Pecados que Claman al Cielo por Venganza',
    icon: Icons.report,
    items: [
      'Willful murder.—The sin of Sodom.—Oppression of the poor.—Defrauding laborers of their wages.',
    ],
    itemsEs: [
      'El homicidio voluntario.—El pecado de Sodoma.—La opresión de los pobres.—Defraudar el jornal a los jornaleros.',
    ],
  ),
  DoctrineTopic(
    id: 'nine_ways_accessory',
    title: 'Nine Ways of Being Accessory to Another\'s Sin',
    titleEs: 'Las Nueve Maneras de Ser Cómplice del Pecado Ajeno',
    icon: Icons.group,
    items: [
      'By counsel.—By command.—By consent.—By provocation.—By praise or flattery.—By concealment.—By partaking.—By silence.—By defense of the ill done.',
    ],
    itemsEs: [
      'Consejando el pecado.—Mandándolo.—Consintiéndolo.—Provocándolo.—Alabándolo o adulando.—Encubriéndolo.—Participando en él.—Callando.—Defendiendo el mal hecho.',
    ],
  ),
  DoctrineTopic(
    id: 'good_works',
    title: 'Three Eminently Good Works',
    titleEs: 'Las Tres Obras Eminentes de Bondad',
    icon: Icons.self_improvement,
    items: [
      'Alms-deeds, or works of mercy, Prayer, and Fasting.',
    ],
    itemsEs: [
      'Las limosnas u obras de misericordia, la Oración y el Ayuno.',
    ],
  ),
  DoctrineTopic(
    id: 'evangelical_counsels',
    title: 'Three Evangelical Counsels',
    titleEs: 'Los Tres Consejos Evangélicos',
    icon: Icons.star,
    items: [
      'Voluntary Poverty, Chastity, and Obedience.',
    ],
    itemsEs: [
      'Pobreza Voluntaria, Castidad y Obediencia.',
    ],
  ),
  DoctrineTopic(
    id: 'daily_meditation',
    title: 'Subjects for Daily Meditation',
    titleEs: 'Temas de Meditación Diaria',
    icon: Icons.psychology,
    items: [
      'Remember, Christian soul, that thou hast this day, and every day of thy life:',
      'God to glorify, — Eternity to prepare for,',
      'Jesus to imitate, — Time to profit by,',
      'The Angels and Saints to invoke, — Neighbors to edify,',
      'A soul to save, — The world to despise,',
      'A body to mortify, — Devils to combat,',
      'Sins to expiate, — Passions to subdue,',
      'Virtues to acquire, — Death perhaps to suffer,',
      'Hell to avoid, — And Judgment to undergo.',
      'Heaven to gain,',
    ],
    itemsEs: [
      'Recuerda, alma cristiana, que tienes este día, y cada día de tu vida:',
      'A Dios, para glorificarle, — La eternidad, para prepararte,',
      'A Jesús, para imitarle, — El tiempo, para aprovecharle,',
      'Los Ángeles y Santos, para invocarlos, — Al prójimo, para edificarle,',
      'Un alma, para salvarla, — El mundo, para despreciarle,',
      'Un cuerpo, para mortificarle, — A los demonios, para combatirlos,',
      'Los pecados, para expiarlos, — Las pasiones, para sujetarlas,',
      'Las virtudes, para adquirirlas, — La muerte, quizás para padecerla,',
      'El infierno, para evitarle, — Y el Juicio, para pasar por él.',
      'El cielo, para ganarlo,',
    ],
  ),
];
import 'package:flutter/material.dart';
import '../../config/theme.dart';

class Novena {
  final String id;
  final String title;
  final String subtitle;
  final String saintOrFeast;
  final IconData icon;
  final Color color;
  final String startDateNote;
  final List<String> dayPrayers;


  List<String> dayPrayersFor(String lang) {
    if (lang == 'es') return _dayPrayersEs[id] ?? dayPrayers;
    return dayPrayers;
  }


  String titleFor(String lang) {
    if (lang == 'es') return _novenasEs[id]?['title'] ?? title;
    return title;
  }

  String subtitleFor(String lang) {
    if (lang == 'es') return _novenasEs[id]?['subtitle'] ?? subtitle;
    return subtitle;
  }

  String saintOrFeastFor(String lang) {
    if (lang == 'es') return _novenasEs[id]?['saint'] ?? saintOrFeast;
    return saintOrFeast;
  }

  String startDateNoteFor(String lang) {
    if (lang == 'es') return _novenasEs[id]?['note'] ?? startDateNote;
    return startDateNote;
  }

  const Novena({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.saintOrFeast,
    required this.icon,
    required this.color,
    required this.startDateNote,
    required this.dayPrayers,
  });
}

/// Spanish day-prayers per novena (id -> entries), shown when Español is active.
/// Day 1-9 entries mirror the English `dayPrayers` lists 1:1.
const Map<String, List<String>> _dayPrayersEs = {
  'divine_mercy': [
  'Día 1 — Toda la humanidad, especialmente los pecadores:\n"Hoy tráeme a toda la humanidad y, en especial, a todos los pecadores, y sumérgelos en el océano de Mi misericordia."\n\nReza: un Padre Nuestro, un Dios te salve María, un Gloria y luego la Coronilla de la Divina Misericordia.',
  'Día 2 — Sacerdotes y religiosos:\n"Hoy tráeme las almas de los sacerdotes y religiosos, y sumérgelas en Mi insondable misericordia."\n\nReza: un Padre Nuestro, un Dios te salve María, un Gloria y luego la Coronilla de la Divina Misericordia.',
  'Día 3 — Todas las almas devotas y fieles:\n"Hoy tráeme todas las almas devotas y fieles, y sumérgelas en el océano de Mi misericordia."\n\nReza: un Padre Nuestro, un Dios te salve María, un Gloria y luego la Coronilla de la Divina Misericordia.',
  'Día 4 — Los que no conocen a Cristo:\n"Hoy tráeme a los paganos y a los que no me conocen."\n\nReza: un Padre Nuestro, un Dios te salve María, un Gloria y luego la Coronilla de la Divina Misericordia.',
  'Día 5 — Herejes y cismáticos:\n"Hoy tráeme las almas de los herejes y cismáticos, y sumérgelas en el océano de Mi misericordia."\n\nReza: un Padre Nuestro, un Dios te salve María, un Gloria y luego la Coronilla de la Divina Misericordia.',
  'Día 6 — Los mansos y humildes, especialmente los niños:\n"Hoy tráeme a los mansos y humildes y las almas de los niños pequeños."\n\nReza: un Padre Nuestro, un Dios te salve María, un Gloria y luego la Coronilla de la Divina Misericordia.',
  'Día 7 — Los que honran y glorifican Mi misericordia:\n"Hoy tráeme las almas que glorifican Mi misericordia de manera especial y más profunda."\n\nReza: un Padre Nuestro, un Dios te salve María, un Gloria y luego la Coronilla de la Divina Misericordia.',
  'Día 8 — Las almas del Purgatorio:\n"Hoy tráeme las almas que están en la prisión del Purgatorio, y sumérgelas en las profundidades de Mi misericordia."\n\nReza: un Padre Nuestro, un Dios te salve María, un Gloria y luego la Coronilla de la Divina Misericordia.',
  'Día 9 — Las almas tibias:\n"Hoy tráeme las almas tibias. Que estas almas se sumerjan en el abismo de Mi misericordia, que es la herida más dolorosa de Mi Corazón."\n\nReza: un Padre Nuestro, un Dios te salve María, un Gloria y luego la Coronilla de la Divina Misericordia.',
  ],
  'st_jude': [
  'Día 1: Santísimo Apóstol San Judas Tadeo, fiel servidor y amigo de Jesús, la Iglesia te honra e invoca como patrono de los casos desesperados. Ruega para que yo reciba la gracia de Dios. Padre Nuestro, Dios te salve María, Gloria.',
  'Día 2: San Judas, apóstol de la esperanza, intercede por mí en mis necesidades. Obtén para mí la gracia de confiar en la providencia de Dios. Padre Nuestro, Dios te salve María, Gloria.',
  'Día 3: Glorioso San Judas, ayúdame en mi petición presente y urgente. Que se haga la voluntad de Dios en todas las cosas. Padre Nuestro, Dios te salve María, Gloria.',
  'Día 4: San Judas, que sufriste el martirio por la fe, ruega para que yo tenga valor en mis pruebas. Padre Nuestro, Dios te salve María, Gloria.',
  'Día 5: Bienaventurado San Judas, que trabajaste entre los perdidos, ruega por mí cuando me sienta abandonado. Padre Nuestro, Dios te salve María, Gloria.',
  'Día 6: San Judas, fiel testigo de Cristo, fortalece mi fe en tiempos de duda. Padre Nuestro, Dios te salve María, Gloria.',
  'Día 7: Querido San Judas, amigo de Jesús, obtén para mí el favor que busco si es la voluntad de Dios. Padre Nuestro, Dios te salve María, Gloria.',
  'Día 8: San Judas, patrono de los desesperados, llena mi corazón de esperanza y confianza en Dios. Padre Nuestro, Dios te salve María, Gloria.',
  'Día 9: Santísimo San Judas, doy gracias a Dios por las gracias obtenidas mediante tu intercesión. Que yo alabe siempre al Señor. Padre Nuestro, Dios te salve María, Gloria.',
  ],
  'miraculous_medal': [
  'Día 1: Oh Virgen Inmaculada, Madre de Nuestro Señor Jesucristo y Madre nuestra, venimos a ti con confianza. Obtén para nosotros las gracias que más necesitamos. Padre Nuestro, Dios te salve María, Gloria.',
  'Día 2: Oh María, concebida sin pecado, ruega por nosotros que acudimos a ti. Concedenos la gracia de una oración ferviente. Padre Nuestro, Dios te salve María, Gloria.',
  'Día 3: Oh Bienaventurada Virgen, refugio de los pecadores, intercede por nosotros para obtener verdadera contrición de nuestros pecados. Padre Nuestro, Dios te salve María, Gloria.',
  'Día 4: Oh Madre de la Misericordia, por tu Medalla Milagrosa, concede que perseveremos en las buenas obras. Padre Nuestro, Dios te salve María, Gloria.',
  'Día 5: Oh María Inmaculada, obtén para nosotros una fe viva, una esperanza firme y una caridad ardiente. Padre Nuestro, Dios te salve María, Gloria.',
  'Día 6: Oh Reina del Cielo, por tu poderosa intercesión, concede la gracia de vivir vidas santas. Padre Nuestro, Dios te salve María, Gloria.',
  'Día 7: Oh María, consuelo de los afligidos, lleva nuestras súplicas al trono de Dios. Padre Nuestro, Dios te salve María, Gloria.',
  'Día 8: Oh Virgen poderosa, obtén para nosotros la gracia de resistir la tentación y evitar el pecado. Padre Nuestro, Dios te salve María, Gloria.',
  'Día 9: Oh Inmaculada Concepción, ponemos tus pies nuestras súplicas y confiamos en tu cuidado maternal. Padre Nuestro, Dios te salve María, Gloria.',
  ],
  'sacred_heart': [
  'Día 1: Oh Divino Corazón de Jesús, ardiendo en amor por nosotros, inflama mi corazón de amor por Ti. Padre Nuestro, Dios te salve María, Gloria.',
  'Día 2: Oh Sagrado Corazón, fuente de toda consolación, consuélame en mis pruebas. Padre Nuestro, Dios te salve María, Gloria.',
  'Día 3: Oh Corazón de Jesús, manso y humilde, enséñame a ser manso y humilde de corazón. Padre Nuestro, Dios te salve María, Gloria.',
  'Día 4: Oh Sagrado Corazón, refugio de los pecadores, ten misericordia de mí. Padre Nuestro, Dios te salve María, Gloria.',
  'Día 5: Oh Corazón de Jesús, lleno de bondad, concédeme la gracia de la verdadera contrición. Padre Nuestro, Dios te salve María, Gloria.',
  'Día 6: Oh Sagrado Corazón, tesoro de todas las gracias, enriquece mi alma con tus dones. Padre Nuestro, Dios te salve María, Gloria.',
  'Día 7: Oh Corazón de Jesús, Rey y centro de todos los corazones, reina en mi corazón. Padre Nuestro, Dios te salve María, Gloria.',
  'Día 8: Oh Sagrado Corazón, paciente y misericordiosísimo, perdona mis pecados. Padre Nuestro, Dios te salve María, Gloria.',
  'Día 9: Oh Divino Corazón, me consagro a Ti. Reina en mí para siempre. Padre Nuestro, Dios te salve María, Gloria.',
  ],
  'st_therese': [
  'Día 1: Oh Pequeña Flor de Jesús, que prometiste dejar caer una lluvia de rosas, obtén para mí la gracia de una confianza infantil en Dios. Padre Nuestro, Dios te salve María, Gloria.',
  'Día 2: Oh Santa Teresita, que caminaste el Caminito, enséñame a hacer las cosas pequeñas con gran amor. Padre Nuestro, Dios te salve María, Gloria.',
  'Día 3: Oh Pequeña Flor, que encontraste el cielo en el sufrimiento, ayúdame a llevar mis cruces con alegría. Padre Nuestro, Dios te salve María, Gloria.',
  'Día 4: Oh Santa Teresita, que amaste el Santo Rostro de Jesús, obtén para mí la verdadera devoción a Cristo. Padre Nuestro, Dios te salve María, Gloria.',
  'Día 5: Oh Pequeña Flor, doctora de la Iglesia, obtén para mí sabiduría y entendimiento. Padre Nuestro, Dios te salve María, Gloria.',
  'Día 6: Oh Santa Teresita, patrona de las misiones, ayúdame a difundir el Evangelio con mi ejemplo. Padre Nuestro, Dios te salve María, Gloria.',
  'Día 7: Oh Pequeña Flor, que confíaste plenamente en Dios, aumenta mi fe y mi esperanza. Padre Nuestro, Dios te salve María, Gloria.',
  'Día 8: Oh Santa Teresita, que oraste desde tu claustro por todo el mundo, intercede por mis intenciones. Padre Nuestro, Dios te salve María, Gloria.',
  'Día 9: Oh Pequeña Flor, doy gracias a Dios por las bendiciones obtenidas por tu intercesión. Que yo ame a Dios más cada día. Padre Nuestro, Dios te salve María, Gloria.',
  ],
  'holy_spirit': [
  'Día 1 — Caridad: Ven, Espíritu Santo, y llena mi corazón del fuego de la divina caridad. Padre Nuestro, Dios te salve María, Gloria + "Ven Espíritu Santo, llena los corazones de tus fieles y enciende en ellos el fuego de tu amor."',
  'Día 2 — Gozo: Ven, Espíritu Santo, y concédeme la gracia del gozo espiritual. Padre Nuestro, Dios te salve María, Gloria.',
  'Día 3 — Paz: Ven, Espíritu Santo, y concédeme la paz interior. Padre Nuestro, Dios te salve María, Gloria.',
  'Día 4 — Paciencia: Ven, Espíritu Santo, y concédeme la virtud de la paciencia. Padre Nuestro, Dios te salve María, Gloria.',
  'Día 5 — Generosidad: Ven, Espíritu Santo, y hazme generoso en servir a Dios. Padre Nuestro, Dios te salve María, Gloria.',
  'Día 6 — Bondad: Ven, Espíritu Santo, y llena mi alma de tu bondad. Padre Nuestro, Dios te salve María, Gloria.',
  'Día 7 — Mansedumbre: Ven, Espíritu Santo, y hazme manso y suave como Cristo. Padre Nuestro, Dios te salve María, Gloria.',
  'Día 8 — Fidelidad: Ven, Espíritu Santo, y hazme fiel a mis deberes. Padre Nuestro, Dios te salve María, Gloria.',
  'Día 9 — Templanza: Ven, Espíritu Santo, y concédeme la gracia del dominio de mí mismo. Padre Nuestro, Dios te salve María, Gloria.',
  ],
  'immaculate_conception': [
  'Día 1: Oh María Inmaculada, concebida sin pecado original, ruega por nosotros. Obtén para mí la gracia de la pureza de corazón. Padre Nuestro, Dios te salve María, Gloria.',
  'Día 2: Oh María, inmaculada desde el primer instante de tu concepción, ayúdame a evitar todo pecado. Padre Nuestro, Dios te salve María, Gloria.',
  'Día 3: Oh Virgen Inmaculada, tú que aplastaste la cabeza de la serpiente, protégeme de los ataques del demonio. Padre Nuestro, Dios te salve María, Gloria.',
  'Día 4: Oh María, llena de gracia, obtén para mí el aumento de gracia en mi alma. Padre Nuestro, Dios te salve María, Gloria.',
  'Día 5: Oh Madre Inmaculada, gloria del género humano, ayúdame a vivir una vida santa. Padre Nuestro, Dios te salve María, Gloria.',
  'Día 6: Oh Bienaventurada Virgen, elegida por Dios desde toda la eternidad, obtén para mí la gracia de la perseverancia. Padre Nuestro, Dios te salve María, Gloria.',
  'Día 7: Oh Inmaculada Concepción, santuario del Espíritu Santo, llena mi corazón de amor divino. Padre Nuestro, Dios te salve María, Gloria.',
  'Día 8: Oh María, nuestra abogada, presenta nuestras súplicas a tu Hijo Divino. Padre Nuestro, Dios te salve María, Gloria.',
  'Día 9: Oh Virgen Inmaculada, gozamos en tu gloria y confiamos en tu intercesión. Padre Nuestro, Dios te salve María, Gloria.',
  ],
  'st_michael': [
  'Día 1 — San Miguel, Príncipe de la Milicia Celestial:\nOh glorioso San Miguel, Príncipe de la Milicia Celestial, defiéndenos en la batalla contra los poderes de las tinieblas. Protégenos de las asechanzas del demonio y ordena que se retire. Padre Nuestro, Dios te salve María, Gloria.\n\nOración a San Miguel: San Miguel Arcángel, defiéndenos en la batalla. Sé nuestro amparo contra la maldad y las asechanzas del demonio. Que Dios le reprenda, es nuestra humilde súplica. Y tu, ó Príncipe de la Milicia Celestial, con el poder que Dios te ha dado, arroja al infierno a Satánás y a todos los espíritus malignos que andan por el mundo para la perdición de las almas. Amén. ',
  'Día 2 — San Miguel, Defensor de la Iglesia:\nOh San Miguel, tutor y protector de la Santa Iglesia Católica, intercede por ella contra todos sus enemigos. Obtén para nosotros la gracia de permanecer firmes en la fe. Padre Nuestro, Dios te salve María, Gloria.\n\nOración a San Miguel: San Miguel Arcangel, defendenos en la batalla... San Miguel Arcángel, defiéndenos en la batalla...',
  'Día 3 — San Miguel, defensor de la justicia de Dios:\nOh San Miguel, que arrojaste a Lucía y sus ángeles rebeldes por mandato de Dios, obtén para mí la gracia de la verdadera humildad y obediencia a la voluntad de Dios. Padre Nuestro, Dios te salve María, Gloria.\n\nOración a San Miguel: San Miguel Arcangel, defendenos en la batalla... San Miguel Arcángel, defiéndenos en la batalla...',
  'Día 4 — San Miguel, Guardián del Santísimo Sacramento:\nOh San Miguel, que adoras el Santísimo Sacramento con los ángeles del cielo, obtén para mí una devoción cada vez más profunda a la Presencia Real de Cristo. Padre Nuestro, Dios te salve María, Gloria.\n\nOración a San Miguel: San Miguel Arcangel, defendenos en la batalla... San Miguel Arcángel, defiéndenos en la batalla...',
  'Día 5 — San Miguel, Protector de los moribundos:\nOh San Miguel, que estás presente en la hora de la muerte defendiendo las almas de los asaltos del demonio, obtén para mí la gracia de una muerte santa y pacífica. Padre Nuestro, Dios te salve María, Gloria.\n\nOración a San Miguel: San Miguel Arcangel, defendenos en la batalla... San Miguel Arcángel, defiéndenos en la batalla...',
  'Día 6 — San Miguel, Guardián de las almas del Purgatorio:\nOh San Miguel, que asistes a las santas almas del Purgatorio, obtén para ellas alivio y descanso eterno. Que yo también sea purificado y hecho digno del cielo. Padre Nuestro, Dios te salve María, Gloria.\n\nOración a San Miguel: San Miguel Arcangel, defendenos en la batalla... San Miguel Arcángel, defiéndenos en la batalla...',
  'Día 7 — San Miguel, Guía de los fieles:\nOh San Miguel, guía de las almas hacia el reino celestial, llévame por el camino de la justicia. Protégeme de los engaños del maligno. Padre Nuestro, Dios te salve María, Gloria.\n\nOración a San Miguel: San Miguel Arcangel, defendenos en la batalla... San Miguel Arcángel, defiéndenos en la batalla...',
  'Día 8 — San Miguel, Fortaleza en la tentación:\nOh San Miguel, valiente guerrero de Dios, fortifícame en los tiempos de tentación. Escóndeme de todo mal y ayúdame a permanecer firme en la virtud. Padre Nuestro, Dios te salve María, Gloria.\n\nOración a San Miguel: San Miguel Arcangel, defendenos en la batalla... San Miguel Arcángel, defiéndenos en la batalla...',
  'Día 9 — San Miguel, Líder Victorioso:\nOh glorioso San Miguel, que triunfaste sobre los poderes del infierno, obtén para mí la perseverancia final y la gracia de luchar valientemente contra todo mal. Que yo, contigo, sea hallado digno de entrar en la gloria del cielo. Padre Nuestro, Dios te salve María, Gloria.\n\nOración a San Miguel: San Miguel Arcángel, defiéndenos en la batalla. Sé nuestro amparo contra la maldad y las asechanzas del demonio. Que Dios le reprenda, es nuestra humilde súplica. Y tu, ó Príncipe de la Milicia Celestial, con el poder que Dios te ha dado, arroja al infierno a Satánás y a todos los espíritus malignos que andan por el mundo para la perdición de las almas. Amén. ',
  ],
  'our_lady_montserrat': [
  'Día 1: Oh Virgen de Montserrat, Madre de Dios y Madre nuestra, a ti nos encomendamos. Padre Nuestro, Dios te salve María, Gloria.',
  'Día 2: Oh Bienaventurada Virgen de Montserrat, obtén para mí la gracia de una sincera conversión de corazón. Padre Nuestro, Dios te salve María, Gloria.',
  'Día 3: Oh Nuestra Señora sentada en la montaña de la gracia, eleva mi alma hacia Dios. Padre Nuestro, Dios te salve María, Gloria.',
  'Día 4: Oh Moreneta, que brillas con la luz de Cristo, ilumina mi camino. Padre Nuestro, Dios te salve María, Gloria.',
  'Día 5: Oh Madre de Montserrat, protege a todos los que te invocan en sus necesidades. Padre Nuestro, Dios te salve María, Gloria.',
  'Día 6: Oh Bienaventurada Virgen, que has consolado a tantos peregrinos, consuélame en mis dificultades. Padre Nuestro, Dios te salve María, Gloria.',
  'Día 7: Oh Virgen de Montserrat, que has inspirado a los santos, inspírame hacia la santidad. Padre Nuestro, Dios te salve María, Gloria.',
  'Día 8: Oh Madre de la Misericordia, por tu intercesión, obtén para mí el favor que busco. Padre Nuestro, Dios te salve María, Gloria.',
  'Día 9: Oh Virgen de Montserrat, doy gracias por las gracias recibidas. Que yo permanezca siempre devoto a ti. Padre Nuestro, Dios te salve María, Gloria.',
  ],
  'st_joseph': [
  'Día 1: Oh glorioso San José, padre putativo de Jesús y casto esposo de la Bienaventurada Virgen, obtén para mí una fe viva. Padre Nuestro, Dios te salve María, Gloria.',
  'Día 2: Oh San José, modelo de humildad, enséñame a someterme a la voluntad de Dios en todas las cosas. Padre Nuestro, Dios te salve María, Gloria.',
  'Día 3: Oh San José, espejo de paciencia, obtén para mí la gracia de llevar mis cruces con resignación. Padre Nuestro, Dios te salve María, Gloria.',
  'Día 4: Oh San José, modelo de obediencia, ayúdame a obedecer los mandamientos de Dios y de su Iglesia. Padre Nuestro, Dios te salve María, Gloria.',
  'Día 5: Oh San José, patrono de los trabajadores, bendice mis labores y provee mis necesidades. Padre Nuestro, Dios te salve María, Gloria.',
  'Día 6: Oh San José, protector de la Santa Iglesia, defiende a la Iglesia de todos sus enemigos. Padre Nuestro, Dios te salve María, Gloria.',
  'Día 7: Oh San José, patrono de la feliz agonía, obtén para mí la gracia de la perseverancia final. Padre Nuestro, Dios te salve María, Gloria.',
  'Día 8: Oh San José, terror de los demonios, protégeme de las asechanzas del maligno. Padre Nuestro, Dios te salve María, Gloria.',
  'Día 9: Oh glorioso San José, me encomiendo a tu protección. Concede que, por tu intercesión, yo obtenga los favores que busco. Padre Nuestro, Dios te salve María, Gloria.',
  ],
};

/// Spanish metadata per novena (id -> title/subtitle/saint/note)
const Map<String, Map<String, String>> _novenasEs = {
  'divine_mercy': {'title': 'Novena de la Divina Misericordia', 'subtitle': 'Dada por Jesús a Santa Faustina', 'saint': 'Jesús \u2014 Divina Misericordia', 'note': 'Cualquier momento \u2014 9 d\u00edas consecutivos'},
  'miraculous_medal': {'title': 'Nuestra Se\u00f1ora de la Medalla Milagrosa', 'subtitle': 'Por la intercesi\u00f3n de la Sant\u00edsima Virgen', 'saint': 'La Sant\u00edsima Virgen Mar\u00eda', 'note': 'Cualquier momento \u2014 9 d\u00edas consecutivos'},
  'st_jude': {'title': 'San Judas Tadeo', 'subtitle': 'Patrono de los casos desesperados y dif\u00edciles', 'saint': 'San Judas Tadeo', 'note': 'Cualquier momento \u2014 9 d\u00edas consecutivos'},
  'st_joseph': {'title': 'San Jos\u00e9', 'subtitle': 'Patrono de la Iglesia Universal, de los trabajadores y de las familias', 'saint': 'San Jos\u00e9', 'note': 'Cualquier momento \u2014 tradicionalmente del 10 al 18 de marzo por su fiesta'},
  'sacred_heart': {'title': 'Sagrado Coraz\u00f3n de Jesús', 'subtitle': 'Devoción al amor de Cristo', 'saint': 'Sagrado Coraz\u00f3n de Jesús', 'note': 'Cualquier momento \u2014 tradicionalmente 9 días antes del Primer Viernes'},
  'immaculate_conception': {'title': 'Inmaculada Concepción', 'subtitle': 'Patrona de los Estados Unidos', 'saint': 'La Santísima Virgen María', 'note': 'Cualquier momento — tradicionalmente del 29 de noviembre al 8 de diciembre'},
  'holy_spirit': {'title': 'Novena al Espíritu Santo', 'subtitle': 'La novena original — rezada por los Apóstoles', 'saint': 'El Espíritu Santo', 'note': '9 días antes de Pentecostés (o cualquier momento)'},
  'st_therese': {'title': 'Santa Teresita del Niño Jesús', 'subtitle': 'La Pequeña Flor — dejaré caer una lluvia de rosas', 'saint': 'Santa Teresita del Niño Jesús', 'note': 'Cualquier momento — 9 días consecutivos'},
  'our_lady_montserrat': {'title': 'Nuestra Señora de Montserrat', 'subtitle': 'Moreneta de Cataluña, patrona de España', 'saint': 'La Santísima Virgen María — Montserrat', 'note': 'Cualquier momento — 9 días consecutivos'},
  'st_michael': {'title': 'San Miguel Arcángel', 'subtitle': 'Defensor en la batalla, protector contra el mal', 'saint': 'San Miguel Arcángel', 'note': 'Cualquier momento — 9 días consecutivos (especialmente antes de la fiesta del 29 de septiembre)'},
};

final List<Novena> catholicNovenas = [
  Novena(
    id: 'divine_mercy',
    title: 'Divine Mercy Novena',
    subtitle: 'Given by Jesus to St. Faustina',
    saintOrFeast: 'Jesus — Divine Mercy',
    icon: Icons.favorite,
    color: Color(0xFFE57373),
    startDateNote: 'Begins Good Friday, ends Divine Mercy Sunday',
    dayPrayers: [
      'Day 1 — All mankind, especially sinners:\n"Today, bring to Me all mankind, especially all sinners, and immerse them in the ocean of My mercy."\n\nPray: 1 Our Father, 1 Hail Mary, 1 Glory Be, then the Chaplet of Divine Mercy.',
      'Day 2 — Priests and religious:\n"Today, bring to Me the souls of priests and religious, and immerse them in My unfathomable mercy."\n\nPray: 1 Our Father, 1 Hail Mary, 1 Glory Be, then the Chaplet of Divine Mercy.',
      'Day 3 — All devout and faithful souls:\n"Today, bring to Me all devout and faithful souls, and immerse them in the ocean of My mercy."\n\nPray: 1 Our Father, 1 Hail Mary, 1 Glory Be, then the Chaplet of Divine Mercy.',
      'Day 4 — Those who do not know Christ:\n"Today, bring to Me the pagans and those who do not know Me."\n\nPray: 1 Our Father, 1 Hail Mary, 1 Glory Be, then the Chaplet of Divine Mercy.',
      'Day 5 — Heretics and schismatics:\n"Today, bring to Me the souls of heretics and schismatics, and immerse them in the ocean of My mercy."\n\nPray: 1 Our Father, 1 Hail Mary, 1 Glory Be, then the Chaplet of Divine Mercy.',
      'Day 6 — The meek and humble, especially little children:\n"Today, bring to Me the meek and humble, and the souls of little children."\n\nPray: 1 Our Father, 1 Hail Mary, 1 Glory Be, then the Chaplet of Divine Mercy.',
      'Day 7 — Those who venerate and glorify My mercy:\n"Today, bring to Me the souls who especially venerate and glorify My mercy."\n\nPray: 1 Our Father, 1 Hail Mary, 1 Glory Be, then the Chaplet of Divine Mercy.',
      'Day 8 — The souls in Purgatory:\n"Today, bring to Me the souls who are in the prison of Purgatory."\n\nPray: 1 Our Father, 1 Hail Mary, 1 Glory Be, then the Chaplet of Divine Mercy.',
      'Day 9 — The lukewarm:\n"Today, bring to Me the souls who have become lukewarm."\n\nPray: 1 Our Father, 1 Hail Mary, 1 Glory Be, then the Chaplet of Divine Mercy.',
    ],
  ),
  Novena(
    id: 'miraculous_medal',
    title: 'Our Lady of the Miraculous Medal',
    subtitle: 'Through the intercession of the Blessed Virgin',
    saintOrFeast: 'Blessed Virgin Mary',
    icon: Icons.auto_awesome,
    color: FidelisTheme.gold,
    startDateNote: 'Anytime — 9 consecutive days',
    dayPrayers: [
      'Day 1: O Immaculate Virgin Mary, Mother of Our Lord Jesus and our Mother, we come to you with confidence. Obtain for us the graces we need most. Our Father, Hail Mary, Glory Be.',
      'Day 2: O Mary, conceived without sin, pray for us who have recourse to thee. Grant us the grace of fervent prayer. Our Father, Hail Mary, Glory Be.',
      'Day 3: O Blessed Virgin, refuge of sinners, intercede for us that we may obtain true sorrow for our sins. Our Father, Hail Mary, Glory Be.',
      'Day 4: O Mother of Mercy, through thy Miraculous Medal, grant us perseverance in good works. Our Father, Hail Mary, Glory Be.',
      'Day 5: O Immaculate Mary, obtain for us a lively faith, firm hope, and burning charity. Our Father, Hail Mary, Glory Be.',
      'Day 6: O Queen of Heaven, through thy powerful intercession, grant us the grace to live holy lives. Our Father, Hail Mary, Glory Be.',
      'Day 7: O Mary, comfort of the afflicted, bring our petitions before the throne of God. Our Father, Hail Mary, Glory Be.',
      'Day 8: O Virgin most powerful, obtain for us the grace to resist temptation and avoid sin. Our Father, Hail Mary, Glory Be.',
      'Day 9: O Immaculate Conception, we place our petitions at thy feet and trust in thy motherly care. Our Father, Hail Mary, Glory Be.',
    ],
  ),
  Novena(
    id: 'st_jude',
    title: 'St. Jude Thaddeus',
    subtitle: 'Patron of hopeless and desperate cases',
    saintOrFeast: 'St. Jude Thaddeus',
    icon: Icons.local_fire_department,
    color: Color(0xFFFF9800),
    startDateNote: 'Anytime — 9 consecutive days',
    dayPrayers: [
      'Day 1: Most holy Apostle, St. Jude, faithful servant and friend of Jesus, the Church honors and invokes you as the patron of hopeless cases. Pray that I may receive the grace of God. Our Father, Hail Mary, Glory Be.',
      'Day 2: St. Jude, apostle of hope, intercede for me in my necessities. Obtain for me the grace to trust in God\'s providence. Our Father, Hail Mary, Glory Be.',
      'Day 3: Glorious St. Jude, help me in my present and urgent petition. Grant that God\'s will be done in all things. Our Father, Hail Mary, Glory Be.',
      'Day 4: St. Jude, who suffered martyrdom for the faith, pray that I may have courage in my trials. Our Father, Hail Mary, Glory Be.',
      'Day 5: Blessed St. Jude, who labored among the lost, pray for me when I feel abandoned. Our Father, Hail Mary, Glory Be.',
      'Day 6: St. Jude, faithful witness to Christ, strengthen my faith in times of doubt. Our Father, Hail Mary, Glory Be.',
      'Day 7: Dear St. Jude, friend of Jesus, obtain for me the favor I seek if it be God\'s will. Our Father, Hail Mary, Glory Be.',
      'Day 8: St. Jude, patron of the desperate, fill my heart with hope and trust in God. Our Father, Hail Mary, Glory Be.',
      'Day 9: Most holy St. Jude, I give thanks to God for the graces obtained through your intercession. May I always praise the Lord. Our Father, Hail Mary, Glory Be.',
    ],
  ),
  Novena(
    id: 'st_joseph',
    title: 'St. Joseph',
    subtitle: 'Patron of the Universal Church, workers, and families',
    saintOrFeast: 'St. Joseph',
    icon: Icons.carpenter,
    color: Color(0xFF8D6E63),
    startDateNote: 'Anytime — traditionally March 10–18 for his feast',
    dayPrayers: [
      'Day 1: O glorious St. Joseph, foster father of Jesus and chaste spouse of the Blessed Virgin, obtain for me a lively faith. Our Father, Hail Mary, Glory Be.',
      'Day 2: O St. Joseph, model of humility, teach me to submit to God\'s will in all things. Our Father, Hail Mary, Glory Be.',
      'Day 3: O St. Joseph, mirror of patience, obtain for me the grace to bear my crosses with resignation. Our Father, Hail Mary, Glory Be.',
      'Day 4: O St. Joseph, model of obedience, help me to obey the commandments of God and His Church. Our Father, Hail Mary, Glory Be.',
      'Day 5: O St. Joseph, patron of workers, bless my labors and provide for my needs. Our Father, Hail Mary, Glory Be.',
      'Day 6: O St. Joseph, protector of the Holy Church, defend the Church from all enemies. Our Father, Hail Mary, Glory Be.',
      'Day 7: O St. Joseph, patron of a happy death, obtain for me the grace of final perseverance. Our Father, Hail Mary, Glory Be.',
      'Day 8: O St. Joseph, terror of demons, protect me from the snares of the evil one. Our Father, Hail Mary, Glory Be.',
      'Day 9: O glorious St. Joseph, I commend myself to your protection. Grant that through your intercession I may obtain the favors I seek. Our Father, Hail Mary, Glory Be.',
    ],
  ),
  Novena(
    id: 'sacred_heart',
    title: 'Sacred Heart of Jesus',
    subtitle: 'Devotion to the love of Christ',
    saintOrFeast: 'Sacred Heart of Jesus',
    icon: Icons.favorite_border,
    color: Color(0xFFE53935),
    startDateNote: 'Anytime — traditionally 9 days before First Friday',
    dayPrayers: [
      'Day 1: O Divine Heart of Jesus, burning with love for us, inflame my heart with love for Thee. Our Father, Hail Mary, Glory Be.',
      'Day 2: O Sacred Heart, source of all consolation, comfort me in my trials. Our Father, Hail Mary, Glory Be.',
      'Day 3: O Heart of Jesus, meek and humble, teach me to be gentle and humble of heart. Our Father, Hail Mary, Glory Be.',
      'Day 4: O Sacred Heart, refuge of sinners, have mercy on me. Our Father, Hail Mary, Glory Be.',
      'Day 5: O Heart of Jesus, full of goodness, grant me the grace of true contrition. Our Father, Hail Mary, Glory Be.',
      'Day 6: O Sacred Heart, treasure of all graces, enrich my soul with Thy gifts. Our Father, Hail Mary, Glory Be.',
      'Day 7: O Heart of Jesus, King and center of all hearts, reign in my heart. Our Father, Hail Mary, Glory Be.',
      'Day 8: O Sacred Heart, patient and most merciful, forgive me my sins. Our Father, Hail Mary, Glory Be.',
      'Day 9: O Divine Heart, I consecrate myself to Thee. Reign in me forever. Our Father, Hail Mary, Glory Be.',
    ],
  ),
  Novena(
    id: 'immaculate_conception',
    title: 'Immaculate Conception',
    subtitle: 'Patroness of the United States',
    saintOrFeast: 'Blessed Virgin Mary',
    icon: Icons.star,
    color: Color(0xFF42A5F5),
    startDateNote: 'Anytime — traditionally Nov 29–Dec 8',
    dayPrayers: [
      'Day 1: O Immaculate Mary, conceived without original sin, pray for us. Obtain for me the grace of purity of heart. Our Father, Hail Mary, Glory Be.',
      'Day 2: O Mary, spotless from the first moment of thy conception, help me to avoid all sin. Our Father, Hail Mary, Glory Be.',
      'Day 3: O Immaculate Virgin, thou who didst crush the head of the serpent, protect me from the attacks of the devil. Our Father, Hail Mary, Glory Be.',
      'Day 4: O Mary, full of grace, obtain for me an increase of grace in my soul. Our Father, Hail Mary, Glory Be.',
      'Day 5: O Immaculate Mother, who art the glory of the human race, help me to live a holy life. Our Father, Hail Mary, Glory Be.',
      'Day 6: O Blessed Virgin, chosen by God from all eternity, obtain for me the grace of perseverance. Our Father, Hail Mary, Glory Be.',
      'Day 7: O Immaculate Conception, shrine of the Holy Spirit, fill my heart with divine love. Our Father, Hail Mary, Glory Be.',
      'Day 8: O Mary, our advocate, present our petitions to thy Divine Son. Our Father, Hail Mary, Glory Be.',
      'Day 9: O Immaculate Virgin, we rejoice in thy glory and trust in thy intercession. Our Father, Hail Mary, Glory Be.',
    ],
  ),
  Novena(
    id: 'holy_spirit',
    title: 'Novena to the Holy Spirit',
    subtitle: 'The original novena — prayed by the Apostles',
    saintOrFeast: 'Holy Spirit',
    icon: Icons.wb_sunny,
    color: Color(0xFFFFCA28),
    startDateNote: '9 days before Pentecost (or anytime)',
    dayPrayers: [
      'Day 1 — Charity: Come, Holy Spirit, and fill my heart with the fire of divine charity. Our Father, Hail Mary, Glory Be + "Come, Holy Spirit, fill the hearts of Thy faithful, and kindle in them the fire of Thy love."',
      'Day 2 — Joy: Come, Holy Spirit, and grant me the grace of spiritual joy. Our Father, Hail Mary, Glory Be.',
      'Day 3 — Peace: Come, Holy Spirit, and grant me interior peace. Our Father, Hail Mary, Glory Be.',
      'Day 4 — Patience: Come, Holy Spirit, and grant me the virtue of patience. Our Father, Hail Mary, Glory Be.',
      'Day 5 — Generosity: Come, Holy Spirit, and make me generous in serving God. Our Father, Hail Mary, Glory Be.',
      'Day 6 — Goodness: Come, Holy Spirit, and fill my soul with Thy goodness. Our Father, Hail Mary, Glory Be.',
      'Day 7 — Mildness: Come, Holy Spirit, and make me gentle and mild like Christ. Our Father, Hail Mary, Glory Be.',
      'Day 8 — Faithfulness: Come, Holy Spirit, and make me faithful to my duties. Our Father, Hail Mary, Glory Be.',
      'Day 9 — Moderation: Come, Holy Spirit, and grant me the grace of self-control. Our Father, Hail Mary, Glory Be.',
    ],
  ),
  Novena(
    id: 'st_therese',
    title: 'St. Thérèse of Lisieux',
    subtitle: 'The Little Flower — "I will let fall a shower of roses"',
    saintOrFeast: 'St. Thérèse of the Child Jesus',
    icon: Icons.local_florist,
    color: Color(0xFFEC407A),
    startDateNote: 'Anytime — 9 consecutive days',
    dayPrayers: [
      'Day 1: O Little Flower of Jesus, who didst promise to let fall a shower of roses, obtain for me the grace of childlike trust in God. Our Father, Hail Mary, Glory Be.',
      'Day 2: O St. Thérèse, who didst walk the Little Way, teach me to do small things with great love. Our Father, Hail Mary, Glory Be.',
      'Day 3: O Little Flower, who found heaven in suffering, help me to bear my crosses joyfully. Our Father, Hail Mary, Glory Be.',
      'Day 4: O St. Thérèse, who loved the Holy Face of Jesus, obtain for me true devotion to Christ. Our Father, Hail Mary, Glory Be.',
      'Day 5: O Little Flower, doctor of the Church, obtain for me wisdom and understanding. Our Father, Hail Mary, Glory Be.',
      'Day 6: O St. Thérèse, patron of the missions, help me to spread the Gospel by my example. Our Father, Hail Mary, Glory Be.',
      'Day 7: O Little Flower, who trusted completely in God, increase my faith and hope. Our Father, Hail Mary, Glory Be.',
      'Day 8: O St. Thérèse, who prayed from your cloister for the whole world, intercede for my intentions. Our Father, Hail Mary, Glory Be.',
      'Day 9: O Little Flower, I thank God for the blessings obtained through your intercession. May I love God more each day. Our Father, Hail Mary, Glory Be.',
    ],
  ),
  Novena(
    id: 'our_lady_montserrat',
    title: 'Our Lady of Montserrat',
    subtitle: 'Dark Virgin of Catalonia, patron of Spain',
    saintOrFeast: 'Blessed Virgin Mary — Montserrat',
    icon: Icons.terrain,
    color: Color(0xFF7E57C2),
    startDateNote: 'Anytime — 9 consecutive days',
    dayPrayers: [
      'Day 1: O Our Lady of Montserrat, Mother of God and our Mother, we entrust ourselves to thee. Our Father, Hail Mary, Glory Be.',
      'Day 2: O Blessed Virgin of Montserrat, obtain for me the grace of sincere conversion of heart. Our Father, Hail Mary, Glory Be.',
      'Day 3: O Our Lady, who art seated upon the mountain of grace, lift me up to God. Our Father, Hail Mary, Glory Be.',
      'Day 4: O Dark Virgin, who shiniest with the light of Christ, illuminate my path. Our Father, Hail Mary, Glory Be.',
      'Day 5: O Mother of Montserrat, protect all who call upon thee in their needs. Our Father, Hail Mary, Glory Be.',
      'Day 6: O Blessed Virgin, who hast comforted so many pilgrims, comfort me in my difficulties. Our Father, Hail Mary, Glory Be.',
      'Day 7: O Our Lady of Montserrat, who hast inspired saints, inspire me to holiness. Our Father, Hail Mary, Glory Be.',
      'Day 8: O Mother of Mercy, through thy intercession, obtain for me the favor I seek. Our Father, Hail Mary, Glory Be.',
      'Day 9: O Our Lady of Montserrat, I give thanks for the graces received. May I ever remain devoted to thee. Our Father, Hail Mary, Glory Be.',
    ],
  ),
  Novena(
    id: 'st_anthony',
    title: 'St. Anthony of Padua',
    subtitle: 'Patron of lost items and the poor',
    saintOrFeast: 'St. Anthony of Padua',
    icon: Icons.search,
    color: Color(0xFF66BB6A),
    startDateNote: 'Anytime — 9 consecutive days (esp. Tuesdays)',
    dayPrayers: [
      'Day 1: O glorious St. Anthony, who didst preach the Gospel with power, obtain for me the grace to live my faith boldly. Our Father, Hail Mary, Glory Be.',
      'Day 2: O St. Anthony, friend of the poor, help me to be generous to those in need. Our Father, Hail Mary, Glory Be.',
      'Day 3: O St. Anthony, finder of lost things, help me to find what I have lost — both material and spiritual. Our Father, Hail Mary, Glory Be.',
      'Day 4: O St. Anthony, hammer of heretics, strengthen me in the true faith. Our Father, Hail Mary, Glory Be.',
      'Day 5: O St. Anthony, who held the Infant Jesus, obtain for me the grace of childlike love for Christ. Our Father, Hail Mary, Glory Be.',
      'Day 6: O St. Anthony, wonder-worker, intercede for me in my pressing needs. Our Father, Hail Mary, Glory Be.',
      'Day 7: O St. Anthony, patron of the oppressed, defend me against injustice. Our Father, Hail Mary, Glory Be.',
      'Day 8: O St. Anthony, who didst love the Eucharist, increase my devotion to the Blessed Sacrament. Our Father, Hail Mary, Glory Be.',
      'Day 9: O glorious St. Anthony, I thank God for the favors obtained through your intercession. May I ever imitate your virtues. Our Father, Hail Mary, Glory Be.',
    ],
  ),
  Novena(
    id: 'st_michael',
    title: 'St. Michael the Archangel',
    subtitle: 'Defender in battle, protector against evil',
    saintOrFeast: 'St. Michael the Archangel',
    icon: Icons.shield,
    color: Color(0xFF1565C0),
    startDateNote: 'Anytime — 9 consecutive days (esp. before Sept 29 feast)',
    dayPrayers: [
      "Day 1 — St. Michael, Prince of the Heavenly Host:\nO glorious St. Michael, Prince of the Heavenly Host, defend us in battle against the powers of darkness. Protect us from the snares of the devil and command him to depart. Our Father, Hail Mary, Glory Be.\n\nPrayer to St. Michael: St. Michael the Archangel, defend us in battle. Be our protection against the wickedness and snares of the devil. May God rebuke him, we humbly pray. And do thou, O Prince of the Heavenly Host, by the power of God, cast into hell Satan and all the evil spirits who prowl about the world seeking the ruin of souls. Amen.",
      "Day 2 — St. Michael, Defender of the Church:\nO St. Michael, guardian and protector of the Holy Catholic Church, intercede for her against all enemies. Obtain for us the grace to remain steadfast in the faith. Our Father, Hail Mary, Glory Be.\n\nPrayer to St. Michael: St. Michael the Archangel, defend us in battle...",
      "Day 3 — St. Michael, Champion of God's Justice:\nO St. Michael, who didst cast down Lucifer and his rebel angels by the command of God, obtain for me the grace of true humility and obedience to God's will. Our Father, Hail Mary, Glory Be.\n\nPrayer to St. Michael: St. Michael the Archangel, defend us in battle...",
      "Day 4 — St. Michael, Guardian of the Blessed Sacrament:\nO St. Michael, who dost adore the Blessed Sacrament with the angels of heaven, obtain for me an ever-deeper devotion to the Real Presence of Christ. Our Father, Hail Mary, Glory Be.\n\nPrayer to St. Michael: St. Michael the Archangel, defend us in battle...",
      "Day 5 — St. Michael, Protector of the Dying:\nO St. Michael, who art present at the hour of death to defend souls from the assaults of the devil, obtain for me the grace of a holy and peaceful death. Our Father, Hail Mary, Glory Be.\n\nPrayer to St. Michael: St. Michael the Archangel, defend us in battle...",
      "Day 6 — St. Michael, Guardian of Souls in Purgatory:\nO St. Michael, who dost assist the holy souls in Purgatory, obtain for them relief and eternal rest. May I also be purified and made worthy of heaven. Our Father, Hail Mary, Glory Be.\n\nPrayer to St. Michael: St. Michael the Archangel, defend us in battle...",
      "Day 7 — St. Michael, Guide of the Faithful:\nO St. Michael, guide of souls to the heavenly kingdom, lead me on the path of righteousness. Protect me from the deceits of the evil one. Our Father, Hail Mary, Glory Be.\n\nPrayer to St. Michael: St. Michael the Archangel, defend us in battle...",
      "Day 8 — St. Michael, Strength in Temptation:\nO St. Michael, mighty warrior of God, strengthen me in times of temptation. Shield me from all evil and help me to stand firm in virtue. Our Father, Hail Mary, Glory Be.\n\nPrayer to St. Michael: St. Michael the Archangel, defend us in battle...",
      "Day 9 — St. Michael, Victorious Leader:\nO glorious St. Michael, who didst triumph over the powers of hell, obtain for me final perseverance and the grace to fight valiantly against all evil. May I, with thee, be found worthy to enter the glory of heaven. Our Father, Hail Mary, Glory Be.\n\nPrayer to St. Michael: St. Michael the Archangel, defend us in battle. Be our protection against the wickedness and snares of the devil. May God rebuke him, we humbly pray. And do thou, O Prince of the Heavenly Host, by the power of God, cast into hell Satan and all the evil spirits who prowl about the world seeking the ruin of souls. Amen.",
    ],
  ),
];
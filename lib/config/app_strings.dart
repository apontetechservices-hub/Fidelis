import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide language support: ONE app with an English/Español toggle that
/// changes the interface of the whole app. Prayer CONTENT language (Latin
/// toggle) is separate — see PrayerTranslations in the prayers feature.
class AppStrings {
  AppStrings._();

  static String _locale = 'en';
  static String get locale => _locale;
  static bool get isSpanish => _locale == 'es';

  static final ValueNotifier<String> localeNotifier = ValueNotifier('en');

  static const List<(String code, String label)> languages = [
    ('en', 'English'),
    ('es', 'Español'),
  ];

  /// Load the saved preference, falling back to the device language.
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('app_language');
    _locale = saved ?? _systemLanguage();
    localeNotifier.value = _locale;
  }

  static String _systemLanguage() {
    final code =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    return code == 'es' ? 'es' : 'en';
  }

  static Future<void> setLanguage(String code) async {
    _locale = code;
    localeNotifier.value = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', code);
  }

  /// Translate: the mapped string for the active locale (English fallback).
  static String t(String key) =>
      _strings[key]?[_locale] ?? _strings[key]?['en'] ?? key;

  /// Language-aware lookup for screens whose content carries its own language
  /// (rosary steps follow the rosary's own selector, not the app locale).
  static String tFor(String key, String lang) =>
      _strings[key]?[lang] ?? _strings[key]?['en'] ?? key;

  static const Map<String, Map<String, String>> _strings = {
    // ---- Navigation ----
    'nav_home': {'en': 'Home', 'es': 'Inicio'},
    'nav_rosary': {'en': 'Rosary', 'es': 'Rosario'},
    'nav_readings': {'en': 'Readings', 'es': 'Lecturas'},
    'nav_prayers': {'en': 'Prayers', 'es': 'Oraciones'},
    'nav_calendar': {'en': 'Calendar', 'es': 'Calendario'},

    // ---- Home ----
    'quick_actions': {'en': 'Quick Actions', 'es': 'Acciones rápidas'},
    'daily_prayers': {'en': 'Daily Prayers', 'es': 'Oraciones del Día'},
    'morning_prayer': {'en': 'Morning Prayer', 'es': 'Oración matutina'},
    'evening_prayer': {'en': 'Evening Prayer', 'es': 'Oración vespertina'},
    'novenas': {'en': 'Novenas', 'es': 'Novenas'},
    'more_chaplets': {'en': 'More Chaplets', 'es': 'Más coronillas'},
    'about_rosary': {'en': 'About the Rosary', 'es': 'Sobre el Rosario'},
    'stations': {'en': 'Stations of the Cross', 'es': 'Vía Crucis'},
    'pray_todays_rosary': {
      'en': "Pray Today's Rosary",
      'es': 'Reza el Rosario de hoy',
    },
    'liturgy_coming': {
      'en': 'Liturgy of the Hours — coming in a future update!',
      'es': 'Liturgia de las Horas — ¡próximamente!',
    },
    'exit_title': {'en': 'Exit Fidelis?', 'es': '¿Salir de Fidelis?'},
    'exit_body': {
      'en': 'Are you sure you want to close the app?',
      'es': '¿Seguro que quieres cerrar la aplicación?',
    },
    'stay': {'en': 'Stay', 'es': 'Quedarme'},
    'exit': {'en': 'Exit', 'es': 'Salir'},
    'go_to_rosary': {'en': 'Go to Rosary', 'es': 'Ir al Rosario'},

    // ---- App bars / titles ----
    'title_prayers': {'en': 'Prayers', 'es': 'Oraciones'},
    'title_readings': {'en': 'Daily Mass Readings', 'es': 'Lecturas de la Misa Diaria'},
    'title_settings': {'en': 'Settings', 'es': 'Ajustes'},
    'title_holy_rosary': {'en': 'Holy Rosary', 'es': 'Santo Rosario'},
    'title_novenas': {'en': 'Novenas', 'es': 'Novenas'},
    'title_saints': {'en': '1962 Calendar', 'es': 'Calendario 1962'},
    'mass_readings': {'en': 'Mass Readings', 'es': 'Lecturas de la Misa'},

    // ---- Prayers categories ----
    'cat_daily': {'en': 'Daily Prayers', 'es': 'Oraciones Diarias'},
    'cat_morning_evening': {
      'en': 'Morning & Evening Prayer',
      'es': 'Oración Matutina y Vespertina',
    },
    'cat_marian': {'en': 'Marian Prayers', 'es': 'Oraciones Marianas'},
    'cat_litanies': {'en': 'Litanies', 'es': 'Letanías'},
    'cat_for_the_dead': {
      'en': 'Prayers for the Dead',
      'es': 'Oraciones por los Difuntos',
    },
    'cat_devotions': {'en': 'Devotions', 'es': 'Devociones'},

    // ---- Readings / Saints shared ----
    'no_readings': {
      'en': 'No readings available for this date.',
      'es': 'No hay lecturas disponibles para esta fecha.',
    },
    'no_data_for_date': {
      'en': 'No data available for this date',
      'es': 'No hay datos disponibles para esta fecha',
    },
    'check_connection': {
      'en': 'Check your connection and try again.',
      'es': 'Revisa tu conexión y vuelve a intentarlo.',
    },
    'retry': {'en': 'Retray', 'es': 'Reintentar'},
    'traditional_1962': {'en': 'Traditional (1962)', 'es': 'Tradicional (1962)'},
    'novus_ordo': {'en': 'Novus Ordo', 'es': 'Novus Ordo'},
    'unable_to_load': {'en': 'Unable to load readings', 'es': 'No se pudieron cargar las lecturas'},
    'please_check_connection': {'en': 'Please check your internet connection and try again.', 'es': 'Revisa tu conexin a internet e intntalo de nuevo.'},
    'title_1962_missal': {'en': '1962 Roman Missal', 'es': 'Misal Romano de 1962'},
    'select_missal': {'en': 'Select Missal', 'es': 'Selecciona el Misal'},
    'go_to_today': {'en': 'Go to today', 'es': 'Ir a hoy'},
    'about': {'en': 'About', 'es': 'Acerca de'},

    // ---- Daily hub ----
    'now_good_time_for': {
      'en': 'NOW IS A GOOD TIME FOR',
      'es': 'AHORA ES BUEN MOMENTO PARA',
    },
    'the_days_prayers': {
      'en': "The Day's Prayers",
      'es': 'Las Oraciones del Día',
    },
    'reminders': {'en': 'Reminders', 'es': 'Recordatorios'},
    'section_notifications': {'en': 'Notifications', 'es': 'Notificaciones'},
    'section_appearance': {'en': 'Appearance', 'es': 'Apariencia'},
    'angelus_reminders': {
      'en': 'Angelus reminders',
      'es': 'Recordatorios del Ángelus',
    },
    'angelus_times': {'en': '6 AM · noon · 6 PM', 'es': '6 AM · mediodía · 6 PM'},
    'sub_morning': {
      'en': 'Begin the day — offer everything to God',
      'es': 'Empieza el día — ofrece todo a Dios',
    },
    'sub_midday': {
      'en': 'Midday — the bell tolls for the Angelus',
      'es': 'Mediodía — la campana llama al Ángelus',
    },
    'sub_mercy': {
      'en': 'The Hour of Great Mercy — 3 PM',
      'es': 'La Hora de la Gran Misericordia — 3 PM',
    },
    'sub_evening': {'en': 'At the close of day', 'es': 'Al caer la tarde'},
    'sub_night': {'en': 'End the day in peace', 'es': 'Termina el día en paz'},
    'angelus_note': {
      'en': "The Angelus commemorates the Incarnation — the Angel's announcement to Mary — "
          'and is traditionally prayed at 6 AM, noon, and 6 PM. '
          'During the Easter Season the app shows the Regina Caeli in its place.',
      'es': 'El Ángelus conmemora la Encarnación — el anuncio del Ángel a María — '
          'y se reza tradicionalmente a las 6 de la mañana, al mediodía y a las 6 de la tarde. '
          'Durante el Tiempo Pascual, la aplicación muestra la Regina Caeli en su lugar.',
    },

    // ---- Settings ----
    'dark_mode': {'en': 'Dark Mode', 'es': 'Modo oscuro'},
    'reduce_eye_strain': {
      'en': 'Reduce eye strain in low light',
      'es': 'Reduce la fatiga visual con poca luz',
    },
    'app_language': {'en': 'App language', 'es': 'Idioma de la aplicación'},
    'language_changed_note': {
      'en': 'The app returns to the home screen when the language changes.',
      'es': 'La aplicación vuelve a la pantalla de inicio al cambiar el idioma.',
    },
    'daily_mass_reminder': {
      'en': 'Daily Mass Reminder',
      'es': 'Recordatorio de la Misa',
    },
    'mass_reminder_time': {
      'en': 'Mass Reminder Time',
      'es': 'Hora del recordatorio de la Misa',
    },
    'daily_rosary_reminder': {
      'en': 'Daily Rosary Reminder',
      'es': 'Recordatorio del Rosario',
    },
    'rosary_reminder_time': {
      'en': 'Rosary Reminder Time',
      'es': 'Hora del recordatorio del Rosario',
    },
    'divine_mercy_chaplet': {
      'en': 'Divine Mercy Chaplet',
      'es': 'Coronilla de la Divina Misericordia',
    },
    'chaplet_reminder_time': {
      'en': 'Chaplet Reminder Time',
      'es': 'Hora del recordatorio de la Coronilla',
    },
    'remind_me_at': {'en': 'Remind me at', 'es': 'Recordar a las'},
    'hour_of_mercy': {'en': 'Hour of Mercy', 'es': 'Hora de la Misericordia'},
    'daily_readings_missal': {
      'en': 'Daily Readings Missal',
      'es': 'Misal para las Lecturas',
    },
    'ordinary_form': {
      'en': 'Ordinary Form — USCCB readings',
      'es': 'Forma Ordinaria — lecturas USCCB',
    },
    'tridentine_mass': {
      'en': 'Tridentine Mass — Extraordinary Form',
      'es': 'Misa Tridentina — Forma Extraordinaria',
    },
    'novus_ordo_missal': {
      'en': 'Novus Ordo (Current Roman Missal)',
      'es': 'Novus Ordo (Misal Romano actual)',
    },
    'traditional_1962_missal': {
      'en': 'Traditional (1962 Roman Missal)',
      'es': 'Tradicional (Misal Romano de 1962)',
    },
    'liturgical_data': {'en': 'Liturgical Data', 'es': 'Datos Litúrgicos'},
    'no_ads': {'en': 'No Ads, Ever', 'es': 'Sin anuncios, nunca'},
    'prayer_is_sacred': {
      'en': 'Prayer is sacred. This app will never show advertisements.',
      'es': 'La oración es sagrada. Esta aplicación nunca mostrará anuncios.',
    },
    'traditional_catholic_app': {
      'en': 'Traditional Catholic Prayer App',
      'es': 'Aplicación de Oración Católica Tradicional',
    },

    // ---- Rosary screen ----
    'begin': {'en': 'Begin', 'es': 'Comenzar'},
    'cancel': {'en': 'Cancel', 'es': 'Cancelar'},
    'rosary_for_the_dead': {
      'en': 'Rosary for the Dead',
      'es': 'Rosario por los Difuntos',
    },
    'traditional': {'en': 'Traditional', 'es': 'Tradicional'},
    'male': {'en': 'Male', 'es': 'Hombre'},
    'female': {'en': 'Female', 'es': 'Mujer'},
    'previous': {'en': 'Previous', 'es': 'Anterior', 'la': 'Recede'},
    'next': {'en': 'Next', 'es': 'Siguiente'},
    'finish': {'en': 'Finish', 'es': 'Terminar'},
    'amen': {'en': 'Amen', 'es': 'Amén', 'la': 'Amen'},
    'leave': {'en': 'Leave', 'es': 'Salir'},
    'resume_rosary': {'en': 'Resume Rosary', 'es': 'Retomar el Rosario', 'la': 'Repete Rosarium'},
    'discard_progress': {'en': 'Discard saved progress', 'es': 'Descartar progreso guardado', 'la': 'Servatum Profectum Repone'},
    'pray_specific_mystery': {'en': 'Pray a Specific Mystery', 'es': 'Rezar un Misterio Específico', 'la': 'Elige Mysterium'},
    'enter_name': {'en': 'Enter name', 'es': 'Escribe el nombre', 'la': 'Scribe Nomen'},
    'name_of_deceased': {'en': 'Name of the deceased', 'es': 'Nombre del difunto'},
    'prayer_language': {'en': 'Prayer Language', 'es': 'Idioma de la Oración', 'la': 'Lingua Precationis'},
    'rosary_complete': {'en': '🌹 Rosary Complete', 'es': '🌹 Rosario Completo'},
    'stations_complete': {'en': '✝️ Stations Complete', 'es': '✝️ Vía Crucis Completado'},
    'chaplet_complete': {'en': '🙏 Chaplet Complete', 'es': '🙏 Coronilla Completa'},
    'leave_rosary': {'en': 'Leave Rosary?', 'es': '¿Salir del Rosario?'},
    'leave_chaplet': {'en': 'Leave Chaplet?', 'es': '¿Salir de la Coronilla?'},
    'progress_saved_note': {'en': 'Your progress will be saved. Resume from the Rosary tab later.', 'es': 'Tu progreso se guardará. Retómalo más tarde desde la pestaña Rosario.', 'la': 'Profectum servabitur. Repete ex Rosarii plica postea.'},
    'progress_will_be_lost': {'en': 'Your progress will be lost. Are you sure?', 'es': 'Se perderá tu progreso. ¿Seguro?'},
    'progress_saved_toast': {'en': 'Progress saved! Resume from the Rosary tab.', 'es': '¡Progreso guardado! Retómalo desde la pestaña Rosario.', 'la': 'Profectum servatum! Repete ex Rosarii plica.'},
    'lbl_sign_of_cross': {'en': 'Sign of the Cross', 'es': 'La Señal de la Cruz', 'la': 'Signum Crucis'},
    'lbl_creed': {'en': "Apostles' Creed", 'es': 'Credo de los Apóstoles', 'la': 'Symbolum Apostolorum'},
    'lbl_de_profundis': {'en': 'De Profundis (Psalm 129)', 'es': 'De Profundis (Salmo 129)', 'la': 'De Profundis (Psalmus 129)'},
    'lbl_our_father': {'en': 'Our Father', 'es': 'Padre Nuestro', 'la': 'Pater Noster'},
    'lbl_hail_mary': {'en': 'Hail Mary ({{n}} of {{m}})', 'es': 'Ave María ({{n}} de {{m}})', 'la': 'Ave María ({{n}} ex {{m}})'},
    'lbl_glory_be': {'en': 'Glory Be', 'es': 'Gloria', 'la': 'Gloria'},
    'lbl_decade': {'en': 'Decade {{n}}', 'es': 'Decena {{n}}', 'la': 'Decena {{n}}'},
    'lbl_our_father_decade': {'en': 'Our Father (Decade {{n}})', 'es': 'Padre Nuestro (Decena {{n}})', 'la': 'Pater Noster (Decena {{n}})'},
    'lbl_hail_mary_decade': {'en': 'Hail Mary ({{n}} of 10) — Decade {{d}}', 'es': 'Ave María ({{n}} de 10) — Decena {{d}}', 'la': 'Ave María ({{n}} ex 10) — Decena {{d}}'},
    'lbl_glory_be_decade': {'en': 'Glory Be (Decade {{n}})', 'es': 'Gloria (Decena {{n}})', 'la': 'Gloria (Decena {{n}})'},
    'lbl_fatima': {'en': 'O My Jesus (Decade {{n}})', 'es': 'Oh Jesús Mío (Decena {{n}})', 'la': 'O Mi Iesu (Decena {{n}})'},
    'lbl_eternal_rest': {'en': 'Eternal Rest (Decade {{n}})', 'es': 'Descanso Eterno (Decena {{n}})', 'la': 'Requies Aeterna (Decena {{n}})'},
    'lbl_hail_holy_queen': {'en': 'Hail Holy Queen', 'es': 'Dios te Salve, Reina', 'la': 'Salve Regina'},
    'lbl_litany_bvm': {'en': 'Litany of the Blessed Virgin Mary', 'es': 'Letanía de la Bienaventurada Virgen María', 'la': 'Litania Beatissimae Virginis Mariae'},
    'lbl_concluding': {'en': 'Concluding Prayer', 'es': 'Oración Final', 'la': 'Oratio Conclusoria'},
    'lbl_dead_closing': {'en': 'Prayer for the Faithful Departed', 'es': 'Oración por los Fieles Difuntos', 'la': 'Oratio pro Fidelibus Defunctis'},
    'lbl_spiritual_fruit': {'en': 'Spiritual Fruit: {{v}}', 'es': 'Fruto Espiritual: {{v}}', 'la': 'Fructus Spiritualis: {{v}}'},
    'lbl_announce': {'en': 'Announce the {{o}} Mystery', 'es': 'Anuncia el {{n}}º Misterio', 'la': 'Annuntia {{o}} Mysterium'},
    'lbl_meditate': {'en': 'Meditate on the {{o}} Mystery', 'es': 'Medita el {{n}}º Misterio', 'la': 'Meditare {{o}} Mysterium'},
    'st_francis': {'en': 'St. Francis', 'es': 'San Francisco'},
    'method_st_francis': {'en': 'Method of St. Francis of Assisi', 'es': 'Método de San Francisco de Asís'},
    'traditional_method': {'en': 'Traditional Method', 'es': 'Método Tradicional'},
    'daily_reflection': {'en': 'Daily Reflection', 'es': 'Reflexión Diaria'},
    'search_saints': {'en': 'Search saints and feasts...', 'es': 'Busca santos y fiestas...'},
    'today_label': {'en': 'Today', 'es': 'Hoy'},
    'rank_label': {'en': 'Rank', 'es': 'Rango'},
    'color_label': {'en': 'Color', 'es': 'Color'},
    'commemorations_label': {'en': 'Commemorations', 'es': 'Conmemoraciones'},
    'season_label': {'en': 'Season', 'es': 'Tiempo'},
    'unable_to_load_calendar': {'en': 'Unable to load calendar', 'es': 'No se pudo cargar el calendario'},
    'feria_commemoration': {'en': 'Feria / Commemoration', 'es': 'Feria / Conmemoración'},
    'reset_novena_q': {'en': 'Reset Novena?', 'es': '¿Reiniciar la Novena?'},
    'reset_novena_body': {'en': 'This will clear all your progress. Are you sure?', 'es': 'Esto borrará todo tu progreso. ¿Seguro?'},
    'reset': {'en': 'Reset', 'es': 'Reiniciar'},
    'begin_this_novena': {'en': 'Begin This Novena', 'es': 'Comenzar Esta Novena'},
    'your_progress': {'en': 'Your Progress', 'es': 'Tu Progreso'},
    'complete_check': {'en': 'Complete ✓', 'es': 'Completada ✓'},
    'days_done': {'en': '{{n}}/9 days', 'es': '{{n}}/9 días'},
    'daily_reminder': {'en': 'Daily Reminder', 'es': 'Recordatorio Diario'},
    'day_template': {'en': 'Day {{n}}', 'es': 'Día {{n}}'},
    'day_of_nine': {'en': 'Day {{n}} of 9', 'es': 'Día {{n}} de 9'},
    'mark_day_complete': {'en': 'Mark Day {{n}} Complete', 'es': 'Marcar el Día {{n}} Completo'},
    'undo_day': {'en': 'Undo Day {{n}}', 'es': 'Deshacer el Día {{n}}'},

  };
}
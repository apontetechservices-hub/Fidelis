import 'mystery_data.dart';

/// Defines the step-by-step structure of the Rosary
/// Each step has a prayer key and bead type for the UI

enum RosaryStepType {
  signOfTheCross,
  creed,
  ourFather,
  hailMary,
  gloryBe,
  fatimaPrayer,
  hailHolyQueen,
  litany,
  concludingPrayer,
  mysteryAnnouncement,
  mysteryMeditation,
  deProfundis,
  eternalRest,
  deadRosaryClosing,
}

class RosaryStep {
  final RosaryStepType type;
  final String prayerKey; // Key for RosaryPrayers.get()
  final int? hailMaryCount; // For decades (1-10)
  final int? mysteryIndex; // 0-4 for which mystery in the set
  final String label; // UI label for this step

  const RosaryStep({
    required this.type,
    required this.prayerKey,
    this.hailMaryCount,
    this.mysteryIndex,
    required this.label,
  });
}

class RosaryController {
  /// Build the full rosary step sequence
  /// traditional = no luminous mysteries
  /// novusOrdo = includes luminous mysteries (Thursday)
  static List<RosaryStep> buildRosarySteps({
    required List<String> mysteryTypes, // e.g. ['joyful', 'sorrowful', 'glorious'] or with 'luminous'
    required bool includeLuminous,
    required bool isForDead,
  }) {
    final steps = <RosaryStep>[];

    // Opening
    steps.add(const RosaryStep(
      type: RosaryStepType.signOfTheCross,
      prayerKey: 'sign_of_the_cross',
      label: 'Sign of the Cross',
    ));

    steps.add(const RosaryStep(
      type: RosaryStepType.creed,
      prayerKey: 'apostles_creed',
      label: 'Apostles\' Creed',
    ));

    // If rosary for the dead, add De Profundis
    if (isForDead) {
      steps.add(const RosaryStep(
        type: RosaryStepType.deProfundis,
        prayerKey: 'de_profundis',
        label: 'De Profundis (Psalm 129)',
      ));
    }

    // Our Father (introductory)
    steps.add(const RosaryStep(
      type: RosaryStepType.ourFather,
      prayerKey: 'our_father',
      label: 'Our Father',
    ));

    // 3 Hail Marys (for faith, hope, charity)
    for (int i = 1; i <= 3; i++) {
      steps.add(RosaryStep(
        type: RosaryStepType.hailMary,
        prayerKey: 'hail_mary',
        hailMaryCount: i,
        label: 'Hail Mary ($i of 3)',
      ));
    }

    // Glory Be
    steps.add(const RosaryStep(
      type: RosaryStepType.gloryBe,
      prayerKey: 'glory_be',
      label: 'Glory Be',
    ));

    // 5 Decades
    for (int d = 0; d < mysteryTypes.length; d++) {
      final mysteryType = mysteryTypes[d];

      // Mystery (announcement + meditation combined)
      steps.add(RosaryStep(
        type: RosaryStepType.mysteryAnnouncement,
        prayerKey: 'mystery',
        mysteryIndex: d,
        label: MysteryData.getMysteries(mysteryType)[d].titleEn, // Use formal title
      ));

      // Our Father
      steps.add(RosaryStep(
        type: RosaryStepType.ourFather,
        prayerKey: 'our_father',
        mysteryIndex: d,
        label: 'Our Father (Decade ${d + 1})',
      ));

      // 10 Hail Marys
      for (int h = 1; h <= 10; h++) {
        steps.add(RosaryStep(
          type: RosaryStepType.hailMary,
          prayerKey: 'hail_mary',
          hailMaryCount: h,
          mysteryIndex: d,
          label: 'Hail Mary ($h of 10) — Decade ${d + 1}',
        ));
      }

      // Glory Be
      steps.add(RosaryStep(
        type: RosaryStepType.gloryBe,
        prayerKey: 'glory_be',
        mysteryIndex: d,
        label: 'Glory Be (Decade ${d + 1})',
      ));

      // Fatima Prayer
      steps.add(RosaryStep(
        type: RosaryStepType.fatimaPrayer,
        prayerKey: 'fatima_prayer',
        mysteryIndex: d,
        label: 'O My Jesus (Decade ${d + 1})',
      ));

      // Rosary for the Dead: Eternal Rest after each decade
      if (isForDead) {
        steps.add(RosaryStep(
          type: RosaryStepType.eternalRest,
          prayerKey: 'eternal_rest',
          mysteryIndex: d,
          label: 'Eternal Rest (Decade ${d + 1})',
        ));
      }
    }

    // Hail Holy Queen
    steps.add(const RosaryStep(
      type: RosaryStepType.hailHolyQueen,
      prayerKey: 'hail_holy_queen',
      label: 'Hail Holy Queen',
    ));

    // Litany of Loreto
    steps.add(const RosaryStep(
      type: RosaryStepType.litany,
      prayerKey: 'litany',
      label: 'Litany of the Blessed Virgin Mary',
    ));

    // Concluding Prayer is included at the end of the Litany
    // (V. Pray for us... Let us pray: O God...)
    // No separate step needed — removing duplicate

    // Rosary for the Dead: final closing
    if (isForDead) {
      steps.add(const RosaryStep(
        type: RosaryStepType.deadRosaryClosing,
        prayerKey: 'dead_rosary_closing',
        label: 'Prayer for the Faithful Departed',
      ));
    }

    // Final Sign of the Cross
    steps.add(const RosaryStep(
      type: RosaryStepType.signOfTheCross,
      prayerKey: 'sign_of_the_cross',
      label: 'Sign of the Cross',
    ));

    return steps;
  }

  /// Get the mystery types for a given day
  /// Returns a list of 5 mystery identifiers for the day's set
  static List<String> getDayMysteries(DateTime date, bool includeLuminous) {
    final day = date.weekday;
    String setType;
    switch (day) {
      case 1: setType = 'joyful'; break; // Monday
      case 2: setType = 'sorrowful'; break; // Tuesday
      case 3: setType = 'glorious'; break; // Wednesday
      case 4: setType = includeLuminous ? 'luminous' : 'joyful'; break; // Thursday
      case 5: setType = 'sorrowful'; break; // Friday
      case 6: setType = 'joyful'; break; // Saturday
      case 7: setType = 'glorious'; break; // Sunday
      default: setType = 'joyful';
    }
    // Return 5 entries (one per decade) so the loop builds all 5 decades
    return List.filled(5, setType);
  }

  static String _getMysteryLabel(int index, String type) {
    final num = index + 1;
    return 'Announce the $num${_ordinal(num)} Mystery';
  }

  static String _getMeditationLabel(int index, String type) {
    final num = index + 1;
    return 'Meditate on the $num${_ordinal(num)} Mystery';
  }

  static String _ordinal(int n) {
    if (n >= 11 && n <= 13) return 'th';
    switch (n % 10) {
      case 1: return 'st';
      case 2: return 'nd';
      case 3: return 'rd';
      default: return 'th';
    }
  }
}
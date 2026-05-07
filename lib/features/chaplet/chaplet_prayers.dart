import 'package:flutter/material.dart';
import '../../config/theme.dart';

/// Divine Mercy Chaplet prayer data
class ChapletPrayers {
  // Opening prayer
  static const openingPrayer = {
    'en': 'Eternal Father, I offer You the Body and Blood, Soul and Divinity of Your dearly beloved Son, Our Lord Jesus Christ, in atonement for our sins and those of the whole world.',
    'es': 'Padre Eterno, te ofrezco el Cuerpo y la Sangre, el Alma y la Divinidad de tu amadísimo Hijo, Nuestro Señor Jesucristo, en reparación por nuestros pecados y los del mundo entero.',
  };

  // Prayer on the 10 small beads (repeat 10 times per decade)
  static const smallBeadPrayer = {
    'en': 'For the sake of His sorrowful Passion, have mercy on us and on the whole world.',
    'es': 'Por Su dolorosa Pasión, ten misericordia de nosotros y del mundo entero.',
  };

  // Prayer on the large bead (Our Father) - we use the standard Eternal Father
  static const decadePrayer = {
    'en': 'Eternal Father, I offer You the Body and Blood, Soul and Divinity of Your dearly beloved Son, Our Lord Jesus Christ, in atonement for our sins and those of the whole world.',
    'es': 'Padre Eterno, te ofrezco el Cuerpo y la Sangre, el Alma y la Divinidad de tu amadísimo Hijo, Nuestro Señor Jesucristo, en reparación por nuestros pecados y los del mundo entero.',
  };

  // Closing prayer (repeat 3 times)
  static const closingPrayer = {
    'en': 'Holy God, Holy Mighty One, Holy Immortal One, have mercy on us and on the whole world.',
    'es': 'Santo Dios, Santo Fuerte, Santo Inmortal, ten misericordia de nosotros y del mundo entero.',
  };

  // Final prayer
  static const finalPrayer = {
    'en': 'Eternal God, in whom mercy is endless and the treasury of compassion inexhaustible, look kindly upon us and increase Your mercy in us, that in difficult moments we might not despair nor become despondent, but with great confidence submit ourselves to Your holy will, which is Love and Mercy itself. Amen.',
    'es': 'Dios Eterno, en quien la misericordia es infinita y el tesoro de compasión inagotable, míranos con bondad y aumenta en nosotros Tu misericordia, para que en los momentos difíciles no nos desesperemos ni nos desalentemos, sino con gran confianza nos sometamos a Tu santa voluntad, que es Amor y Misericordia misma. Amén.',
  };

  static String get(String key, String lang) {
    final prayers = {
      'opening': openingPrayer,
      'small_bead': smallBeadPrayer,
      'decade': decadePrayer,
      'closing': closingPrayer,
      'final': finalPrayer,
    };
    return prayers[key]?[lang] ?? prayers[key]?['en'] ?? '';
  }
}

/// Chaplet step types
enum ChapletStepType {
  signOfCross,
  ourFather,
  hailMary,
  creed,
  eternalFather,     // On each large bead
  sorrowfulPassion,  // On each small bead (10x)
  holyGod,           // Closing (3x)
  finalPrayer,
}

class ChapletStep {
  final ChapletStepType type;
  final String label;
  final int? beadCount;      // For tracking within a decade (1-10)
  final int? decadeIndex;    // Which decade (1-5)
  final int? repeatCount;    // For Holy God (1-3)

  const ChapletStep({
    required this.type,
    required this.label,
    this.beadCount,
    this.decadeIndex,
    this.repeatCount,
  });
}

class ChapletController {
  /// Build the full Chaplet step sequence
  static List<ChapletStep> buildSteps({String language = 'en'}) {
    final steps = <ChapletStep>[];

    // Sign of the Cross
    steps.add(const ChapletStep(
      type: ChapletStepType.signOfCross,
      label: 'Sign of the Cross',
    ));

    // Optional: Apostles' Creed
    steps.add(const ChapletStep(
      type: ChapletStepType.creed,
      label: 'Apostles\' Creed',
    ));

    // Our Father
    steps.add(const ChapletStep(
      type: ChapletStepType.ourFather,
      label: 'Our Father',
    ));

    // 3 Hail Marys
    for (int i = 1; i <= 3; i++) {
      steps.add(ChapletStep(
        type: ChapletStepType.hailMary,
        label: 'Hail Mary ($i of 3)',
        beadCount: i,
      ));
    }

    // 5 Decades
    for (int d = 1; d <= 5; d++) {
      // Eternal Father (on the large bead)
      steps.add(ChapletStep(
        type: ChapletStepType.eternalFather,
        label: 'Eternal Father (Decade $d)',
        decadeIndex: d,
      ));

      // 10x "For the sake of His sorrowful Passion"
      for (int h = 1; h <= 10; h++) {
        steps.add(ChapletStep(
          type: ChapletStepType.sorrowfulPassion,
          label: 'Sorrowful Passion ($h of 10) — Decade $d',
          beadCount: h,
          decadeIndex: d,
        ));
      }
    }

    // Holy God (3 times)
    for (int i = 1; i <= 3; i++) {
      steps.add(ChapletStep(
        type: ChapletStepType.holyGod,
        label: 'Holy God ($i of 3)',
        repeatCount: i,
      ));
    }

    // Final prayer
    steps.add(const ChapletStep(
      type: ChapletStepType.finalPrayer,
      label: 'Closing Prayer',
    ));

    return steps;
  }
}
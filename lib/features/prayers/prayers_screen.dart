import 'package:flutter/material.dart';
import '../../config/theme.dart';
import 'litany_reader_screen.dart';
import '../rosary/litany_of_loreto.dart';
import '../chaplet/chaplet_list_screen.dart';

class PrayersScreen extends StatelessWidget {
  const PrayersScreen({super.key});

  /// Find a prayer by title and navigate to its detail screen.
  /// Returns true if found and navigated, false otherwise.
  static bool openPrayerByName(BuildContext context, String title) {
    for (final category in _prayerCategories) {
      for (final prayer in category.prayers) {
        if (prayer.title == title) {
          if (prayer.isChaplet) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ChapletListScreen()));
            return true;
          }
          if (prayer.isLitany && prayer.title == 'Litany of Loreto') {
            Navigator.push(context, MaterialPageRoute(builder: (_) => LitanyReaderScreen(
              title: prayer.title,
              invocations: LitanyOfLoreto.getInvocations('en'),
              closingPrayer: LitanyOfLoreto.getClosingPrayer('en'),
            )));
            return true;
          }
          if (prayer.isLitany) {
            final lines = prayer.text.split('\n').where((l) => l.trim().isNotEmpty).toList();
            Navigator.push(context, MaterialPageRoute(builder: (_) => LitanyReaderScreen(
              title: prayer.title,
              invocations: lines,
            )));
            return true;
          }
          Navigator.push(context, MaterialPageRoute(builder: (_) => _PrayerDetailScreen(prayer: prayer)));
          return true;
        }
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Prayers')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        children: [
          for (final category in _prayerCategories) ...[
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              child: Text(
                category.name,
                style: theme.textTheme.titleLarge?.copyWith(color: FidelisTheme.gold),
              ),
            ),
            for (final prayer in category.prayers)
              _PrayerCard(prayer: prayer),
          ],
        ],
      ),
    );
  }
}

class _PrayerCard extends StatelessWidget {
  final _PrayerEntry prayer;
  const _PrayerCard({required this.prayer});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showPrayer(context, prayer),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(prayer.icon, size: 20, color: theme.brightness == Brightness.dark ? FidelisTheme.gold : FidelisTheme.deepRed),
              const SizedBox(width: 12),
              Expanded(
                child: Text(prayer.title, style: theme.textTheme.bodyLarge),
              ),
              const Icon(Icons.chevron_right, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  void _showPrayer(BuildContext context, _PrayerEntry prayer) {
    if (prayer.isChaplet) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ChapletListScreen()),
      );
      return;
    }

    if (prayer.isLitany && prayer.title == 'Litany of Loreto') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LitanyReaderScreen(
            title: prayer.title,
            invocations: LitanyOfLoreto.getInvocations('en'),
            closingPrayer: LitanyOfLoreto.getClosingPrayer('en'),
          ),
        ),
      );
      return;
    }

    // For other litany-style prayers with long text, also use the reader
    if (prayer.isLitany) {
      final lines = prayer.text.split('\n').where((l) => l.trim().isNotEmpty).toList();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LitanyReaderScreen(
            title: prayer.title,
            invocations: lines,
          ),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _PrayerDetailScreen(prayer: prayer),
      ),
    );
  }
}

class _PrayerDetailScreen extends StatelessWidget {
  final _PrayerEntry prayer;
  const _PrayerDetailScreen({required this.prayer});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(prayer.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SelectableText(
              prayer.text,
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.9, fontSize: 17),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _PrayerCategory {
  final String name;
  final List<_PrayerEntry> prayers;
  _PrayerCategory({required this.name, required this.prayers});
}

class _PrayerEntry {
  final String title;
  final String text;
  final IconData icon;
  final bool isLitany;
  final bool isChaplet;
  _PrayerEntry({
    required this.title,
    required this.text,
    required this.icon,
    this.isLitany = false,
    this.isChaplet = false,
  });
}

final _prayerCategories = <_PrayerCategory>[
  _PrayerCategory(name: 'Daily Prayers', prayers: [
    _PrayerEntry(
      title: 'Divine Mercy Chaplet',
      icon: Icons.favorite_border,
      text: '',
      isChaplet: true,
    ),
    _PrayerEntry(
      title: 'Morning Offering',
      icon: Icons.wb_sunny,
      text: 'O Jesus, through the Immaculate Heart of Mary, I offer Thee my prayers, works, joys, and sufferings of this day for all the intentions of Thy Sacred Heart, in union with the Holy Sacrifice of the Mass throughout the world, for the salvation of souls, the reparation of sins, the reunion of Christians, and in particular for the intentions of the Holy Father this month. Amen.',
    ),
    _PrayerEntry(
      title: 'Act of Contrition',
      icon: Icons.favorite,
      text: 'O my God, I am heartily sorry for having offended Thee, and I detest all my sins because of Thy just punishments, but most of all because they offend Thee, my God, who art all good and deserving of all my love. I firmly resolve, with the help of Thy grace, to sin no more and to avoid the near occasions of sin. Amen.',
    ),
    _PrayerEntry(
      title: 'Anima Christi',
      icon: Icons.church,
      text: 'Soul of Christ, sanctify me.\nBody of Christ, save me.\nBlood of Christ, inebriate me.\nWater from the side of Christ, wash me.\nPassion of Christ, strengthen me.\nO good Jesus, hear me.\nWithin Thy wounds, hide me.\nSuffer me not to be separated from Thee.\nFrom the malignant enemy, defend me.\nIn the hour of my death, call me,\nand bid me come to Thee,\nthat with Thy Saints I may praise Thee\nfor ever and ever. Amen.',
    ),
    _PrayerEntry(
      title: 'Prayer before Mass',
      icon: Icons.church,
      text: 'Almighty and ever-living God, I approach the Sacrament of Thy only-begotten Son, our Lord Jesus Christ. I come sick to the Physician of life; unclean, to the Fountain of mercy; blind, to the Light of eternal brightness; poor and needy, to the Lord of heaven and earth. Therefore I beseech Thee, that Thou wouldst wash, cleanse, and quicken me with Thy Holy Spirit. Amen.',
    ),
    _PrayerEntry(
      title: 'Prayer before Communion',
      icon: Icons.church,
      text: 'Lord, I am not worthy that Thou shouldst come under my roof; but speak the word only, and my soul shall be healed. O Lord, I acknowledge my unworthiness to receive Thy sacred Body and precious Blood. But I believe firmly, O Lord, and confess, that Thou art the Christ, the Son of the living God, who hast come into the world to save sinners, of whom I am the chief. Wherefore, O Lord, I beseech Thee, let Thy grace, which is infinite, supply what is wanting in me, that I may worthily approach this most holy Sacrament. Amen.',
    ),
    _PrayerEntry(
      title: 'Prayer after Communion',
      icon: Icons.church,
      text: 'I give Thee thanks, O Lord, holy Father, almighty, eternal God, that Thou hast vouchsafed to feed me, a sinner, Thine unworthy servant, with the precious Body and Blood of Thy Son, our Lord Jesus Christ. May this Holy Communion be to me not a condemnation but a saving defence against sin, and a pledge of future glory. Let it increase my faith, strengthen my charity, and confirm me in Thy grace. Amen.',
    ),
    _PrayerEntry(
      title: 'Anima Christi (after Communion)',
      icon: Icons.church,
      text: 'Soul of Christ, sanctify me.\nBody of Christ, save me.\nBlood of Christ, inebriate me.\nWater from the side of Christ, wash me.\nPassion of Christ, strengthen me.\nO good Jesus, hear me.\nWithin Thy wounds, hide me.\nSuffer me not to be separated from Thee.\nFrom the malignant enemy, defend me.\nIn the hour of my death, call me,\nand bid me come to Thee,\nthat with Thy Saints I may praise Thee\nfor ever and ever. Amen.',
    ),
    _PrayerEntry(
      title: 'Prayer of St. Thomas Aquinas before Communion',
      icon: Icons.church,
      text: 'Almighty and ever-living God, I approach the Sacrament of Thy only-begotten Son, our Lord Jesus Christ, as one sick to the Physician of life, as one unclean to the Fountain of mercy, as one blind to the Light of eternal brightness, as one poor and needy to the Lord of heaven and earth. Therefore I beseech Thee, of Thy most abundant mercy, that Thou wouldst vouchsafe to purify my heart and sanctify my soul, that I may be made worthy to receive the Body and Blood of Thy Son. Who liveth and reigneth with Thee in the unity of the Holy Ghost, God, world without end. Amen.',
    ),
    _PrayerEntry(
      title: 'Prayer of St. Thomas Aquinas after Communion',
      icon: Icons.church,
      text: 'I thank Thee, O Lord, holy Father, almighty, eternal God, that Thou hast vouchsafed, for no merit of mine own, but out of Thy pure mercy, to feed me, a sinner, Thine unworthy servant, with the precious Body and Blood of Thy Son, our Lord Jesus Christ. I pray that this Holy Communion may not be to me an increase of sin unto punishment, but an availing defence unto salvation. May it be to me the armor of faith, the shield of a good conscience, and the fortification of all virtues. Who livest and reignest, world without end. Amen.',
    ),
    _PrayerEntry(
      title: 'Prayer after Mass (Thanksgiving)',
      icon: Icons.church,
      text: 'Blessed, praised, and adored be Jesus Christ on His throne of glory in Heaven, and in the Most Holy Sacrament of the Altar. O Sacrament most holy, O Sacrament divine, all praise and all thanksgiving be every moment Thine. May the Heart of Jesus in the Most Blessed Sacrament be praised, adored, and loved with grateful affection at every moment in all the tabernacles of the world, even unto the end of time. Amen.',
    ),
    _PrayerEntry(
      title: 'Night Prayer',
      icon: Icons.nightlight,
      text: 'Visit, we beseech Thee, O Lord, this dwelling, and drive far from it all snares of the enemy. Let Thy holy Angels dwell with us to preserve us in peace; and let Thy blessing be upon us, through Jesus Christ our Lord. Amen.',
    ),
  ]),

  _PrayerCategory(name: 'Morning & Evening Prayer', prayers: [
    _PrayerEntry(
      title: 'Morning Prayer (Prime)',
      icon: Icons.wb_sunny,
      text: 'In the name of the Father, and of the Son, and of the Holy Ghost. Amen.\n\nOur Father, Hail Mary, I believe in God.\n\nV. O God, come to my assistance.\nR. O Lord, make haste to help me.\nGlory be to the Father, and to the Son, and to the Holy Ghost. As it was in the beginning, is now, and ever shall be, world without end. Amen. Alleluia.\n\n\nHYMN\n\nThe star of morn to night succeeds;\nWe therefore meekly pray,\nMay God, in all our words and deeds,\nKeep us from harm this day.\n\nMay He in love restrain us still\nFrom tones of strife and words of ill,\nAnd wrap around and close our eyes\nTo earth\'s absorbing vanities.\n\nMay wrath and thoughts that gender shame\nNe\'er in our breasts abide,\nAnd painful abstinences tame\nOf wanton flesh the pride;\n\nSo when the weary day is o\'er,\nAnd night and stillness come once more,\nBlameless and clean from spot of earth\nWe may repeat with reverent mirth\n\nTo God the Father glory be,\nAnd to His Only Son,\nAnd to the Spirit, One and Three,\nWhile endless ages run. Amen.\n\n\nPSALM 54\n\nSave me, O God, by thy name, and vindicate me by thy might.\nHear my prayer, O God; give ear to the words of my mouth.\nFor insolent men have risen against me, ruthless men seek my life; they do not set God before them.\nBehold, God is my helper; the Lord is the upholder of my life.\nHe will require my enemies with evil; in thy faithfulness put an end to them.\nWith a freewill offering I will sacrifice to thee; I will give thanks to thy name, O Lord, for it is good.\nFor thou hast delivered me from every trouble, and my eye has looked in triumph on my enemies.\nGlory be to the Father, etc.\n\n\nPSALM 119:1-32\n\nBlessed are those whose way is blameless, who walk in the law of the Lord!\nBlessed are those who keep his testimonies, who seek him with their whole heart,\nwho also do no wrong, but walk in his ways!\nThou hast commanded thy precepts to be kept diligently.\nO that my ways may be steadfast in keeping thy statutes!\nThen I shall not be put to shame, having my eyes fixed on all thy commandments.\nI will praise thee with an upright heart, when I learn thy righteous ordinances.\nI will observe thy statutes; O forsake me not utterly!\nHow can a young man keep his way pure? By guarding it according to thy word.\nWith my whole heart I seek thee; let me not wander from thy commandments!\nI have laid up thy word in my heart, that I might not sin against thee.\nBlessed be thou, O Lord; teach me thy statutes!\nWith my lips I declare all the ordinances of thy mouth.\nIn the way of thy testimonies I delight as much as in all riches.\nI will meditate on thy precepts, and fix my eyes on thy ways.\nI will delight in thy statutes; I will not forget thy word.\nGlory be to the Father, etc.\n\nDeal bountifully with thy servant, that I may live and observe thy word.\nOpen my eyes, that I may behold wondrous things out of thy law.\nI am a sojourner on earth; hide not thy commandments from me!\nMy soul is consumed with longing for thy ordinances at all times.\nThou dost rebuke the insolent, accursed ones, who wander from thy commandments;\ntake away from me their scorn and contempt, for I have kept thy testimonies.\nEven though princes sit plotting against me, thy servant will meditate on thy statutes.\nThy testimonies are my delight, they are my counselors.\nMy soul cleaves to the dust; revive me according to thy word!\nWhen I told of my ways, thou didst answer me; teach me thy statutes!\nMake me understand the way of thy precepts, and I will meditate on thy wondrous works.\nMy soul melts away for sorrow; strengthen me according to thy word!\nPut false ways far from me; and graciously teach me thy law!\nI have chosen the way of faithfulness, I set thy ordinances before me.\nI cleave to thy testimonies, O Lord; let me not be put to shame!\nI will run in the way of thy commandments when thou enlargest my understanding!\nGlory be to the Father, etc.\n\n\nCHAPTER\n\nUnto the King of ages, the Immortal, Invisible, only God, be honor and glory for ever and ever.\nR. Thanks be to God.\n\n\nSHORT RESPONSORY\n\nChrist, Thou Son of the living God, have mercy on us.\nR. Christ, Thou Son of the living God, have mercy on us.\nV. Thou that sittest at the right hand of the Father.\nR. Have mercy on us.\nV. Glory be to the Father, and to the Son, and to the Holy Ghost.\nR. Christ, Thou Son of the living God, have mercy on us.\nV. Arise, O Christ, and help us.\nR. And deliver us for Thy name\'s sake.\n\n\nPRAYERS\n\nV. O Lord, hear my prayer.\nR. And let my cry come unto Thee.\nV. Vouchsafe, O Lord, this day\nR. To keep us without sin.\nV. Have mercy on us, O Lord.\nR. Have mercy on us.\nV. Let Thy mercy, O Lord, be upon us.\nR. As we have hoped in Thee.\n\n\nCOLLECT\n\nO Lord God Almighty, who hast brought us to the beginning of this day: let Thy power so defend us therein, that this day we fall into no sin, but that all our thoughts, words, and works may always tend to what is just in Thy sight. Through our Lord Jesus Christ, Thy Son, who liveth and reigneth with Thee in the unity of the Holy Ghost, one God, world without end. Amen.',
    ),
    _PrayerEntry(
      title: 'Prayer of Consecration of the Day',
      icon: Icons.wb_twilight,
      text: 'O Lord God, King of heaven and earth, may it please Thee this day to order and to hallow, to rule and to govern our hearts and our bodies, our thoughts, our words and our works, according to Thy law and in the doing of Thy commandments, that we, being helped by Thee, may here and hereafter worthily be saved and delivered by Thee, O Saviour of the world, who livest and reignest for ever and ever. Amen.',
    ),
    _PrayerEntry(
      title: 'Evening Prayer (Compline)',
      icon: Icons.nightlight,
      text: 'In the name of the Father, and of the Son, and of the Holy Ghost. Amen.\n\nV. O God, come to my assistance.\nR. O Lord, make haste to help me.\nGlory be to the Father, and to the Son, and to the Holy Ghost. As it was in the beginning, is now, and ever shall be, world without end. Amen. Alleluia.\n\n\nSHORT LESSON\n\nBe sober, be watchful. Your adversary the devil prowls around like a roaring lion, seeking some one to devour. Resist him, firm in your faith. And do Thou, O Lord, have mercy on us.\nR. Thanks be to God.\n\nV. Our help is in the name of the Lord.\nR. Who hath made heaven and earth.\n\n\nPSALM 4\n\nAnswer me when I call, O God of my right! Thou hast given me room when I was in distress. Be gracious to me, and hear my prayer!\nO men, how long shall my honor suffer shame? How long will you love vain words, and seek after lies?\nBut know that the Lord has set apart the godly for himself; the Lord hears when I call to him.\nBe angry, but sin not; commune with your own hearts on your beds, and be silent.\nOffer right sacrifices, and put your trust in the Lord.\nThere are many who say, "O that we might see some good!" Lift up the light of thy countenance upon us, O Lord!\nThou hast put more joy in my heart than they have when their grain and wine abound.\nIn peace I will both lie down and sleep; for thou alone, O Lord, makest me dwell in safety.\nGlory be to the Father, etc.\n\n\nPSALM 31\n\nIn thee, O Lord, do I seek refuge; let me never be put to shame; in thy righteousness deliver me!\nIncline thy ear to me, rescue me speedily! Be thou a rock of refuge for me, a strong fortress to save me!\nYea, thou art my rock and my fortress; and for thy name\'s sake lead me and guide me.\nThou wilt take me out of the net they have hidden for me, for thou art my refuge.\nInto thy hand I commit my spirit; thou hast redeemed me, O Lord, faithful God.\nGlory be to the Father, etc.\n\n\nPSALM 91\n\nHe who dwells in the shelter of the Most High, who abides in the shadow of the Almighty,\nwill say to the Lord, "My refuge and my fortress; my God, in whom I trust."\nFor he will deliver you from the snare of the fowler and from the deadly pestilence;\nhe will cover you with his pinions, and under his wings you will find refuge; his faithfulness is a shield and buckler.\nYou will not fear the terror of the night, nor the arrow that flies by day,\nnor the pestilence that stalks in darkness, nor the destruction that wastes at noonday.\nA thousand may fall at your side, ten thousand at your right hand; but it will not come near you.\nYou will only look with your eyes and see the recompense of the wicked.\nBecause you have made the Lord your refuge, the Most High your habitation,\nno evil shall befall you, no scourge come near your tent.\nFor he will give his angels charge of you to guard you in all your ways.\nOn their hands they will bear you up, lest you dash your foot against a stone.\nYou will tread on the lion and the adder, the young lion and the serpent you will trample under foot.\nBecause he cleaves to me in love, I will deliver him; I will protect him, because he knows my name.\nWhen he calls to me, I will answer him; I will be with him in trouble, I will rescue him and honor him.\nWith long life I will satisfy him, and show him my salvation.\nGlory be to the Father, etc.\n\n\nPSALM 134\n\nCome, bless the Lord, all you servants of the Lord, who stand by night in the house of the Lord!\nLift up your hands to the holy place and bless the Lord!\nMay the Lord bless you from Zion, he who made heaven and earth!\nGlory be to the Father, etc.\n\n\nHYMN\n\nNow that the daylight dies away,\nBy all Thy grace and love,\nThee, Maker of the world, we pray\nTo watch our bed above.\n\nLet dreams depart and phantoms fly,\nThe offspring of the night;\nKeep us, like shrines, beneath Thine eye,\nPure in our foes\' despite.\n\nThis grace on Thy redeemed confer,\nFather, Co-equal Son,\nAnd Holy Ghost, the Comforter,\nEternal Three in One. Amen.\n\n\nCHAPTER\n\nThou, O Lord, art among us, and Thy holy name is called upon us: forsake us not, O Lord our God.\nR. Thanks be to God.\n\n\nRESPONSORY\n\nInto Thy hands, O Lord, I commend my spirit.\nR. Into Thy hands, O Lord, I commend my spirit.\nV. Thou hast redeemed us, O Lord, God of truth.\nR. I commend my spirit.\nV. Glory be to the Father, and to the Son, and to the Holy Ghost.\nR. Into Thy hands, O Lord, I commend my spirit.\nV. Keep us, O Lord, as the apple of Thine eye.\nR. Protect us under the shadow of Thy wings.\n\n\nCANTICLE OF SIMEON (Nunc Dimittis)\n\nAnt. Save us, O Lord, watching, guard us sleeping: that we may watch with Christ, and may rest in peace.\n\nLord, now lettest thou thy servant depart in peace, according to thy word;\nfor mine eyes have seen thy salvation\nwhich thou hast prepared in the presence of all peoples,\na light for revelation to the Gentiles, and for glory to thy people Israel.\nGlory be to the Father, etc.\n\n\nCOLLECT\n\nVisit, we beseech Thee, O Lord, this habitation, and drive far from it all snares of the enemy: let Thy holy Angels dwell therein to keep us in peace: and may Thy blessing be upon us always. Through our Lord Jesus Christ, Thy Son, who liveth and reigneth with Thee in the unity of the Holy Ghost, one God, world without end. Amen.\n\n\nBENEDICTION\n\nMay the Almighty and merciful Lord bless us; the Father, the Son, and the Holy Ghost.\nR. Amen.\n\n\nMARIAN ANTIPHON\n\nSee Salve Regina (Marian Prayers) or the appropriate seasonal antiphon:\n• Alma Redemptoris Mater (Advent through Purification)\n• Ave Regina Caelorum (Purification through Holy Week)\n• Regina Caeli (Easter through Trinity Sunday)\n• Salve Regina (Trinity Sunday through Advent)',
    ),
    _PrayerEntry(
      title: 'Short Morning Prayer',
      icon: Icons.wb_sunny,
      text: 'In the name of the Father, and of the Son, and of the Holy Ghost. Amen.\n\nCome, Holy Ghost, fill the hearts of Thy faithful, and kindle in them the fire of Thy love.\n\nV. Send forth Thy Spirit, and they shall be created.\nR. And Thou shalt renew the face of the earth.\n\nLet us pray.\nO God, who by the light of the Holy Ghost didst instruct the hearts of the faithful, grant that by the same Holy Spirit we may be truly wise and ever enjoy His consolations. Through Christ our Lord. Amen.\n\n\nOUR FATHER\n\nOur Father, who art in heaven, hallowed be Thy name; Thy kingdom come; Thy will be done on earth as it is in heaven. Give us this day our daily bread; and forgive us our trespasses as we forgive those who trespass against us. And lead us not into temptation, but deliver us from evil. Amen.\n\nHAIL MARY\n\nHail Mary, full of grace, the Lord is with thee; blessed art thou amongst women, and blessed is the fruit of thy womb, Jesus. Holy Mary, Mother of God, pray for us sinners, now and at the hour of our death. Amen.\n\nI BELIEVE IN GOD\n\nI believe in God, the Father Almighty, Creator of heaven and earth; and in Jesus Christ, His only Son, our Lord; who was conceived by the Holy Ghost, born of the Virgin Mary; suffered under Pontius Pilate, was crucified, died, and was buried. He descended into hell; the third day He rose again from the dead; He ascended into heaven, and sitteth at the right hand of God the Father Almighty; from thence He shall come to judge the living and the dead. I believe in the Holy Ghost, the Holy Catholic Church, the communion of Saints, the forgiveness of sins, the resurrection of the body, and life everlasting. Amen.\n\n\nACT OF CONSECRATION OF THE DAY\n\nO Lord God, King of heaven and earth, may it please Thee this day to order and to hallow, to rule and to govern our hearts and our bodies, our thoughts, our words and our works, according to Thy law and in the doing of Thy commandments, that we, being helped by Thee, may here and hereafter worthily be saved and delivered by Thee, O Saviour of the world, who livest and reignest for ever and ever. Amen.\n\n\nACT OF FAITH\n\nO my God, I firmly believe that Thou art one God in three divine Persons, Father, Son, and Holy Ghost; I believe that Thy divine Son became man, and died for our sins, and that He will come to judge the living and the dead. I believe these and all the truths which the Holy Catholic Church teaches, because Thou hast revealed them, who canst neither deceive nor be deceived.\n\n\nACT OF HOPE\n\nO my God, relying on Thy almighty power and infinite goodness and promises, I hope to obtain pardon for my sins, the help of Thy grace, and life everlasting, through the merits of Jesus Christ, my Lord and Redeemer.\n\n\nACT OF CHARITY\n\nO my God, I love Thee above all things with my whole heart and soul, because Thou art all good and worthy of all love. I love my neighbor as myself for the love of Thee. I forgive all who have injured me, and ask pardon of all whom I have injured.\n\n\nPRAYER FOR THE INTERCESSION OF THE SAINTS\n\nMay the Blessed Virgin Mary and all the Saints intercede for us with the Lord, that we may be helped and saved by Him who liveth and reigneth for ever and ever. Amen.',
    ),
    _PrayerEntry(
      title: 'Short Evening Prayer',
      icon: Icons.nightlight,
      text: 'In the name of the Father, and of the Son, and of the Holy Ghost. Amen.\n\n\nEXAMINATION OF CONSCIENCE\n\nO my God, sovereign Judge of men, who desirest not the death of a sinner, but that he should be converted and saved, enlighten my mind, that I may know the sins which I have this day committed in thought, word, or deed, and give me the grace of true contrition.\n\n(Here examine your conscience.)\n\n\nACT OF CONTRITION\n\nO my God, I heartily repent, and am grieved that I have offended Thee, because Thou art infinitely good, and sin is infinitely displeasing to Thee. I humbly ask of Thee mercy and pardon, through the infinite merits of Jesus Christ. I resolve, by the assistance of Thy grace, to do penance for my sins, and I will endeavor never more to offend Thee.\n\nI confess to Almighty God, to Blessed Mary ever Virgin, to Blessed Michael the Archangel, to Blessed John the Baptist, to the Holy Apostles Peter and Paul, and to all the Saints, that I have sinned exceedingly, in thought, word, and deed, through my fault, through my fault, through my most grievous fault. Therefore I beseech Blessed Mary ever Virgin, Blessed Michael the Archangel, Blessed John the Baptist, the Holy Apostles Peter and Paul, and all the Saints, to pray to the Lord our God for me.\n\nMay the Almighty and merciful Lord grant us pardon, absolution, and remission of our sins. Amen.\n\n\nOUR FATHER\n\nOur Father, who art in heaven, hallowed be Thy name; Thy kingdom come; Thy will be done on earth as it is in heaven. Give us this day our daily bread; and forgive us our trespasses as we forgive those who trespass against us. And lead us not into temptation, but deliver us from evil. Amen.\n\nHAIL MARY\n\nHail Mary, full of grace, the Lord is with thee; blessed art thou amongst women, and blessed is the fruit of thy womb, Jesus. Holy Mary, Mother of God, pray for us sinners, now and at the hour of our death. Amen.\n\nI BELIEVE IN GOD\n\nI believe in God, the Father Almighty, Creator of heaven and earth; and in Jesus Christ, His only Son, our Lord; who was conceived by the Holy Ghost, born of the Virgin Mary; suffered under Pontius Pilate, was crucified, died, and was buried. He descended into hell; the third day He rose again from the dead; He ascended into heaven, and sitteth at the right hand of God the Father Almighty; from thence He shall come to judge the living and the dead. I believe in the Holy Ghost, the Holy Catholic Church, the communion of Saints, the forgiveness of sins, the resurrection of the body, and life everlasting. Amen.\n\n\nTHANKSGIVING\n\nO my God, I present myself before Thee at the end of another day, to offer Thee anew the homage of my heart. I humbly adore Thee, my Creator, my Redeemer, and my Judge! I believe in Thee, because Thou art Truth itself; I hope in Thee, because Thou art faithful to Thy promises; I love Thee with my whole heart, because Thou art infinitely worthy of being loved; and for Thy sake I love my neighbor as myself.\n\nEnable me, O my God, to return Thee thanks as I ought for all Thine inestimable blessings and favors. Thou hast thought of me, and loved me from all eternity; Thou hast formed me out of nothing; Thou hast delivered up Thy beloved Son to the ignominious death of the Cross for my redemption; Thou hast made me a member of Thy holy Church; Thou hast preserved me from falling into the abyss of eternal misery, when my sins had provoked Thee to punish me; and Thou hast graciously continued to spare me, even though I have not ceased to offend Thee. What return, O my God, can I make for Thine innumerable blessings, and particularly for the favors of this day?\n\n\nPRAYER FOR A HAPPY DEATH\n\nO God, great and omnipotent Judge of the living and the dead, we are to appear before Thee after this short life to render an account of our works. Grant that, accompanied by the Blessed Virgin Mary and all the Saints, we may be found worthy to enter into Thine everlasting joy. Through our Lord Jesus Christ, Thy Son, who liveth and reigneth with Thee in the unity of the Holy Ghost, one God, world without end. Amen.\n\n\nPRAYER FOR THE INTERCESSION OF THE SAINTS\n\nMay the Blessed Virgin Mary and all the Saints intercede for us with the Lord, that we may be helped and saved by Him who liveth and reigneth for ever and ever. Amen.\n\n\nPRAYER FOR THE FAITHFUL DEPARTED\n\nEternal rest grant unto them, O Lord, and let perpetual light shine upon them. May they rest in peace. Amen.',
    ),
  ]),

  _PrayerCategory(name: 'Marian Prayers', prayers: [
    _PrayerEntry(
      title: 'Salve Regina',
      icon: Icons.auto_awesome,
      text: 'Hail, holy Queen, Mother of mercy, our life, our sweetness, and our hope. To thee do we cry, poor banished children of Eve. To thee do we send up our sighs, mourning and weeping in this valley of tears. Turn then, most gracious Advocate, thine eyes of mercy toward us. And after this our exile, show unto us the blessed fruit of thy womb, Jesus. O clement, O loving, O sweet Virgin Mary.\n\nV. Pray for us, O holy Mother of God.\nR. That we may be made worthy of the promises of Christ.',
    ),
    _PrayerEntry(
      title: 'Memorare',
      icon: Icons.auto_awesome,
      text: 'Remember, O most gracious Virgin Mary, that never was it known that any one who fled to thy protection, implored thy help, or sought thy intercession, was left unaided. Inspired by this confidence, I fly unto thee, O Virgin of virgins, my Mother. To thee I come; before thee I stand, sinful and sorrowful. O Mother of the Word Incarnate, despise not my petitions, but in thy mercy hear and answer me. Amen.',
    ),
    _PrayerEntry(
      title: 'Sub Tuum Praesidium',
      icon: Icons.shield,
      text: 'We fly to thy patronage, O holy Mother of God; despise not our petitions in our necessities, but deliver us always from all dangers, O glorious and blessed Virgin. Amen.',
    ),
    _PrayerEntry(
      title: 'Ave Maris Stella',
      icon: Icons.waves,
      text: 'Hail, bright star of ocean,\nGod\'s own Mother blest;\nEver sinless Virgin,\nHeaven\'s peaceful rest.\n\nJoyful at the greeting\nThat the Gabriel gave,\nGrace thy Virgin spirit\nStill sublimely brave.\n\nBreak the sinner\'s fetters,\nMake our blindness cease;\nDrive away our dangers,\nShed on us thy peace.\n\nShow thyself a Mother;\nOffer Him our sighs,\nWho for our transgressions,\nBled, and suffer\'d, dies.\n\nVirgin all excelling,\nMildest of the mild,\nFreed from guilt, preserve us,\nPure and undefiled.\n\nKeep our life all spotless,\nMake our journey sure,\nIllumine all our darkness,\nEvery ill endure.\n\nBest of mothers, dearest,\nMake us love thy Son;\nLead us home to heaven,\nThere with Him as one.\n\nPraise to God the Father,\nGlory to the Son,\nPraise to the Holy Ghost,\nWhile the ages run. Amen.',
    ),
  ]),

  _PrayerCategory(name: 'Litanies', prayers: [
    _PrayerEntry(
      title: 'Litany of Loreto',
      icon: Icons.auto_awesome,
      text: '', // Shown in interactive reader
      isLitany: true,
    ),
    _PrayerEntry(
      title: 'Litany of the Saints',
      icon: Icons.people,
      isLitany: true,
      text: 'Lord, have mercy on us.\nChrist, have mercy on us.\nLord, have mercy on us.\nChrist, hear us.\nChrist, graciously hear us.\n\nGod the Father of Heaven, have mercy on us.\nGod the Son, Redeemer of the world, have mercy on us.\nGod the Holy Ghost, have mercy on us.\nHoly Trinity, one God, have mercy on us.\n\nHoly Mary, pray for us.\nHoly Mother of God, pray for us.\nHoly Virgin of virgins, pray for us.\nSt. Michael, pray for us.\nSt. Gabriel, pray for us.\nSt. Raphael, pray for us.\nAll holy Angels and Archangels, pray for us.\nAll holy orders of blessed Spirits, pray for us.\n\nSt. John the Baptist, pray for us.\nSt. Joseph, pray for us.\nAll holy Patriarchs and Prophets, pray for us.\nSt. Peter, pray for us.\nSt. Paul, pray for us.\nSt. Andrew, pray for us.\nSt. John, pray for us.\nAll holy Apostles and Evangelists, pray for us.\n\nSt. Stephen, pray for us.\nSt. Lawrence, pray for us.\nAll holy Martyrs, pray for us.\nSt. Gregory, pray for us.\nSt. Augustine, pray for us.\nAll holy Bishops and Confessors, pray for us.\n\nSt. Benedict, pray for us.\nSt. Francis, pray for us.\nSt. Dominic, pray for us.\nAll holy Monks and Hermits, pray for us.\n\nSt. Mary Magdalene, pray for us.\nSt. Agnes, pray for us.\nSt. Cecilia, pray for us.\nAll holy Virgins and Widows, pray for us.\nAll holy Saints of God, pray for us.\n\nBe merciful, spare us, O Lord.\nBe merciful, graciously hear us, O Lord.\n\nFrom all evil, O Lord, deliver us.\nFrom all sin, O Lord, deliver us.\nFrom Thy wrath, O Lord, deliver us.\nFrom sudden and unprovided death, O Lord, deliver us.\nFrom the snares of the devil, O Lord, deliver us.\nFrom wrath, hatred, and all ill will, O Lord, deliver us.\nFrom lightning and tempest, O Lord, deliver us.\nFrom the scourge of earthquake, O Lord, deliver us.\nFrom plague, famine, and war, O Lord, deliver us.\nFrom everlasting death, O Lord, deliver us.\n\nWe sinners, we beseech Thee, hear us.\nThat Thou wouldst spare us, we beseech Thee, hear us.\nThat Thou wouldst pardon us, we beseech Thee, hear us.\nThat Thou wouldst bring us to true penance, we beseech Thee, hear us.\nThat Thou wouldst govern and preserve Thy holy Church, we beseech Thee, hear us.\nThat Thou wouldst preserve our Holy Father the Pope, we beseech Thee, hear us.\nThat Thou wouldst grant peace and unity to all Christian people, we beseech Thee, hear us.\n\nLamb of God, who takest away the sins of the world, spare us, O Lord.\nLamb of God, who takest away the sins of the world, graciously hear us, O Lord.\nLamb of God, who takest away the sins of the world, have mercy on us.\n\nChrist, hear us.\nChrist, graciously hear us.\nLord, have mercy.\nChrist, have mercy.\nLord, have mercy.',
    ),
    _PrayerEntry(
      title: 'Litany of the Sacred Heart',
      icon: Icons.favorite,
      isLitany: true,
      text: 'Lord, have mercy on us. Christ, have mercy on us.\nLord, have mercy on us. Christ, hear us. Christ, graciously hear us.\n\nGod the Father of Heaven, have mercy on us.\nGod the Son, Redeemer of the world, have mercy on us.\nGod the Holy Ghost, have mercy on us.\nHoly Trinity, one God, have mercy on us.\n\nHeart of Jesus, Son of the Eternal Father, have mercy on us.\nHeart of Jesus, formed by the Holy Ghost in the womb of the Virgin Mother, have mercy on us.\nHeart of Jesus, substantially united to the Word of God, have mercy on us.\nHeart of Jesus, of infinite majesty, have mercy on us.\nHeart of Jesus, holy temple of God, have mercy on us.\nHeart of Jesus, tabernacle of the Most High, have mercy on us.\nHeart of Jesus, house of God and gate of Heaven, have mercy on us.\nHeart of Jesus, burning furnace of charity, have mercy on us.\nHeart of Jesus, refuge of the afflicted, have mercy on us.\nHeart of Jesus, patient and most merciful, have mercy on us.\nHeart of Jesus, generous to all who invoke Thee, have mercy on us.\nHeart of Jesus, fountain of life and holiness, have mercy on us.\nHeart of Jesus, propitiation for our sins, have mercy on us.\nHeart of Jesus, loaded with contempt and bruises, have mercy on us.\nHeart of Jesus, meek and humble, have mercy on us.\nHeart of Jesus, obedient even unto death, have mercy on us.\nHeart of Jesus, pierced with a lance, have mercy on us.\nHeart of Jesus, source of all consolation, have mercy on us.\nHeart of Jesus, our life and resurrection, have mercy on us.\nHeart of Jesus, our peace and our reconciliation, have mercy on us.\nHeart of Jesus, victim for our sins, have mercy on us.\nHeart of Jesus, salvation of all who trust in Thee, have mercy on us.\nHeart of Jesus, hope of all who die in Thee, have mercy on us.\nHeart of Jesus, delight of all the Saints, have mercy on us.\n\nLamb of God, who takest away the sins of the world, spare us, O Lord.\nLamb of God, who takest away the sins of the world, graciously hear us, O Lord.\nLamb of God, who takest away the sins of the world, have mercy on us.\n\nV. Jesus, meek and humble of heart.\nR. Make our hearts like unto Thine.\n\nLet us pray: Almighty and eternal God, look upon the Heart of Thy most beloved Son and upon the praises and satisfaction which He offers Thee in the name of sinners; and being appeased, grant pardon to those who implore Thy mercy, in the name of the same Jesus Christ Thy Son, who liveth and reigneth with Thee for ever and ever. Amen.',
    ),
  ]),

  _PrayerCategory(name: 'Prayers for the Dead', prayers: [
    _PrayerEntry(
      title: 'De Profundis (Psalm 130)',
      icon: Icons.church,
      text: 'Out of the depths I cry to thee, O Lord!\nLord, hear my voice!\nLet thy ears be attentive to the voice of my supplications!\nIf thou, O Lord, shouldst mark iniquities, Lord, who could stand?\nBut there is forgiveness with thee, that thou mayest be feared.\nI wait for the Lord, my soul waits, and in his word I hope;\nmy soul waits for the Lord more than watchmen for the morning,\nmore than watchmen for the morning.\nO Israel, hope in the Lord!\nFor with the Lord there is steadfast love, and with him is plenteous redemption.\nAnd he will redeem Israel from all his iniquities.\n\nGlory Be to the Father, and to the Son, and to the Holy Ghost.\nAs it was in the beginning, is now, and ever shall be, world without end. Amen.',
    ),
    _PrayerEntry(
      title: 'Eternal Rest',
      icon: Icons.local_fire_department,
      text: 'Eternal rest grant unto them, O Lord,\nand let perpetual light shine upon them.\nMay they rest in peace. Amen.\n\nMay the souls of the faithful departed, through the mercy of God, rest in peace. Amen.',
    ),
    _PrayerEntry(
      title: 'Prayer for the Dead',
      icon: Icons.church,
      text: 'O God, the Creator and Redeemer of all the faithful, grant unto the souls of Thy servants and handmaids the remission of all their sins, that through pious supplications they may obtain the pardon which they have always desired. Through Jesus Christ our Lord. Amen.',
    ),
  ]),

  _PrayerCategory(name: 'Devotions', prayers: [
    _PrayerEntry(
      title: 'Act of Faith',
      icon: Icons.lightbulb,
      text: 'O my God, I firmly believe that Thou art one God in three divine Persons, Father, Son, and Holy Ghost; I believe that Thy divine Son became man, and died for our sins, and that He will come to judge the living and the dead. I believe these and all the truths which the Holy Catholic Church teaches, because Thou hast revealed them, who canst neither deceive nor be deceived.',
    ),
    _PrayerEntry(
      title: 'Act of Hope',
      icon: Icons.lightbulb,
      text: 'O my God, relying on Thy almighty power and infinite goodness and promises, I hope to obtain pardon for my sins, the help of Thy grace, and life everlasting, through the merits of Jesus Christ, my Lord and Redeemer.',
    ),
    _PrayerEntry(
      title: 'Act of Charity',
      icon: Icons.lightbulb,
      text: 'O my God, I love Thee above all things with my whole heart and soul, because Thou art all good and worthy of all love. I love my neighbor as myself for the love of Thee. I forgive all who have injured me, and ask pardon of all whom I have injured.',
    ),
    _PrayerEntry(
      title: 'Prayer to St. Michael the Archangel',
      icon: Icons.shield,
      text: 'St. Michael the Archangel, defend us in battle; be our safeguard against the wickedness and snares of the devil. May God rebuke him, we humbly pray: and do thou, O Prince of the heavenly host, by the power of God, thrust into hell Satan and all the evil spirits who prowl about the world seeking the ruin of souls. Amen.',
    ),
    _PrayerEntry(
      title: 'Prayer before a Crucifix',
      icon: Icons.add,
      text: 'Behold, O kind and most sweet Jesus, I cast myself upon my knees in Thy sight, and with the most fervent desire of my soul, I pray and beseech Thee that Thou wouldst impress upon my heart lively sentiments of faith, hope, and charity, with true repentance for my sins, and a firm purpose of amendment; whilst with deep affection and grief of soul I ponder within myself and mentally contemplate Thy five most precious wounds, having before my eyes the words which David, Thy prophet, put on Thy lips concerning Thee: "They have pierced My hands and My feet; they have numbered all My bones."',
    ),
  ]),
];
/// Mystery data for the Holy Rosary — long version with meditations
class MysteryData {
  final String id;
  final String type; // joyful, sorrowful, glorious, luminous
  final int number; // 1-5 within each set
  final String titleEn;
  final String titleLa;
  final String titleEs;
  final String meditationEn;
  final String meditationLa;
  final String meditationEs;
  final String fruitEn;
  final String fruitLa;
  final String fruitEs;
  final String imageAsset; // Path to mystery image asset
  final String verseRef; // Scripture reference (e.g. "Luke 1:26-38")
  final String verseText; // RSVCE Bible text for this mystery

  const MysteryData({
    required this.id,
    required this.type,
    required this.number,
    required this.titleEn,
    required this.titleLa,
    required this.titleEs,
    required this.meditationEn,
    required this.meditationLa,
    required this.meditationEs,
    required this.fruitEn,
    required this.fruitLa,
    required this.fruitEs,
    this.imageAsset = '',
    this.verseRef = '',
    this.verseText = '',
  });

  String title(String lang) {
    switch (lang) {
      case 'la': return titleLa;
      case 'es': return titleEs;
      default: return titleEn;
    }
  }

  String meditation(String lang) {
    switch (lang) {
      case 'la': return meditationLa;
      case 'es': return meditationEs;
      default: return meditationEn;
    }
  }

  String fruit(String lang) {
    switch (lang) {
      case 'la': return fruitLa;
      case 'es': return fruitEs;
      default: return fruitEn;
    }
  }

  static const List<MysteryData> joyful = [
    MysteryData(
      id: 'joyful_1',
      type: 'joyful',
      number: 1,
      titleEn: 'The Annunciation',
      titleLa: 'Annuntiátio',
      titleEs: 'La Anunciación',
      meditationEn: 'The Angel Gabriel announces to the Blessed Virgin Mary that she has been chosen to be the Mother of God. Mary humbly accepts the will of the Father: "Behold the handmaid of the Lord; be it done unto me according to Thy word."',
      meditationLa: 'Angelus Gabriel Beátæ Maríæ Vírgini nuntiát se eléctam esse Dei Matrem. María humíliter Patris voluntátem accípit: "Ecce ancílla Dómini; fiat mihi secúndum verbum tuum."',
      meditationEs: 'El ángel Gabriel anuncia a la Santísima Virgen María que ha sido elegida para ser Madre de Dios. María humildemente acepta la voluntad del Padre: "He aquí la esclava del Señor; hágase en mí según tu palabra."',
      fruitEn: 'Humility',
      fruitLa: 'Humilitas',
      fruitEs: 'Humildad',
      imageAsset: 'assets/mysteries/joyful_1.jpg',
      verseRef: 'Luke 1:26-38',
      verseText: '''In the sixth month the angel Gabriel was sent from God to a city of Galilee named Nazareth, to a virgin betrothed to a man whose name was Joseph, of the house of David; and the virgin's name was Mary. And he came to her and said, "Hail, full of grace, the Lord is with you!" But she was greatly troubled at the saying, and considered in her mind what sort of greeting this might be. And the angel said to her, "Do not be afraid, Mary, for you have found favor with God. And behold, you will conceive in your womb and bear a son, and you shall call his name Jesus. He will be great, and will be called the Son of the Most High; and the Lord God will give to him the throne of his father David, and he will reign over the house of Jacob for ever; and of his kingdom there will be no end." And Mary said to the angel, "How can this be, since I have no husband?" And the angel said to her, "The Holy Spirit will come upon you, and the power of the Most High will overshadow you; therefore the child to be born will be called holy, the Son of God. And behold, your kinswoman Elizabeth in her old age has also conceived a son; and this is the sixth month with her who was called barren. For with God nothing will be impossible." And Mary said, "Behold, I am the handmaid of the Lord; let it be to me according to your word." And the angel departed from her.''',
    ),
    MysteryData(
      id: 'joyful_2',
      type: 'joyful',
      number: 2,
      titleEn: 'The Visitation',
      titleLa: 'Visitátio',
      titleEs: 'La Visitación',
      meditationEn: 'Mary visits her cousin Elizabeth, who is also with child. The infant John the Baptist leaps in Elizabeth\'s womb at the presence of the Lord. Elizabeth exclaims: "Blessed art thou among women, and blessed is the fruit of thy womb!"',
      meditationLa: 'María visitat cousínam suam Elisábeth, quæ etiam grávida est. Infans Ioánnes Bapta in útero Elisábeth exsíllat ad præséntiam Dómini. Elisábeth exclámat: "Benedícta tu inter mulíeres, et benedíctus fructus ventris tui!"',
      meditationEs: 'María visita a su prima Isabel, que también está encinta. El niño Juan Bautista salta en el seno de Isabel ante la presencia del Señor. Isabel exclama: "¡Bendita tú entre las mujeres, y bendito el fruto de tu vientre!"',
      fruitEn: 'Charity toward our neighbor',
      fruitLa: 'Caritas erga próximum',
      fruitEs: 'Caridad hacia el prójimo',
      imageAsset: 'assets/mysteries/joyful_2.jpg',
      verseRef: 'Luke 1:39-45',
      verseText: '''In those days Mary arose and went with haste into the hill country, to a city of Judah, and she entered the house of Zechariah and greeted Elizabeth. And when Elizabeth heard the greeting of Mary, the babe leaped in her womb; and Elizabeth was filled with the Holy Spirit and she exclaimed with a loud cry, "Blessed are you among women, and blessed is the fruit of your womb! And why is this granted me, that the mother of my Lord should come to me? For behold, when the voice of your greeting came to my ears, the babe in my womb leaped for joy. And blessed is she who believed that there would be a fulfilment of what was spoken to her from the Lord." ''',
    ),
    MysteryData(
      id: 'joyful_3',
      type: 'joyful',
      number: 3,
      titleEn: 'The Nativity',
      titleLa: 'Nativítas',
      titleEs: 'El Nacimiento',
      meditationEn: 'Jesus is born in a stable at Bethlehem. The Word is made flesh and dwells among us. The shepherds and the angels come to adore the newborn King. Mary treasures all these things in her heart.',
      meditationLa: 'Iesus nascítur in præsépio Bethlehémitáno. Verbum caro factum est et habitávit in nobis. Pastóres et ángeli adórant Regem novéllo nátum. María ómnia hæc verba conservábat in corde suo.',
      meditationEs: 'Jesús nace en un pesebre en Belén. El Verbo se hizo carne y habitó entre nosotros. Los pastores y los ángeles vienen a adorar al Rey recién nacido. María guardaba todas estas cosas en su corazón.',
      fruitEn: 'Detachment from the things of this world; love of poverty',
      fruitLa: 'Abditió a rerum huius mundi; amor paupertátis',
      fruitEs: 'Desprendimiento de las cosas de este mundo; amor a la pobreza',
      imageAsset: 'assets/mysteries/joyful_3.jpg',
      verseRef: 'Luke 2:1-7',
      verseText: '''In those days a decree went out from Caesar Augustus that all the world should be enrolled. This was the first enrollment, when Quirinius was governor of Syria. And all went to be enrolled, each to his own city. And Joseph also went up from Galilee, from the city of Nazareth, to Judea, to the city of David, which is called Bethlehem, because he was of the house and lineage of David, to be enrolled with Mary, his betrothed, who was with child. And while they were there, the time came for her to be delivered. And she gave birth to her first-born son and wrapped him in swaddling cloths, and laid him in a manger, because there was no place for them in the inn.''',
    ),
    MysteryData(
      id: 'joyful_4',
      type: 'joyful',
      number: 4,
      titleEn: 'The Presentation',
      titleLa: 'Presentátio',
      titleEs: 'La Presentación',
      meditationEn: 'Mary and Joseph present the Child Jesus in the Temple. Simeon, filled with the Holy Spirit, takes the Child in his arms and prophesies. A sword of sorrow shall pierce Mary\'s soul.',
      meditationLa: 'María et Ioseph Púerum Iesum in Templo præséntant. Símeon, Spíritu Sancto plenus, Púerum in bráchia súscipit et prophetat. Gládius doloris ánimam Maríæ perforábit.',
      meditationEs: 'María y José presentan al Niño Jesús en el Templo. Simeón, lleno del Espíritu Santo, toma al Niño en sus brazos y profetiza. Una espada de dolor traspasará el alma de María.',
      fruitEn: 'Obedience to the law of God; purity of intention',
      fruitLa: 'Obediéntia legi Dei; puritas intentiónis',
      fruitEs: 'Obediencia a la ley de Dios; pureza de intención',
      imageAsset: 'assets/mysteries/joyful_4.jpg',
      verseRef: 'Luke 2:22-35',
      verseText: '''And when the time came for their purification according to the law of Moses, they brought him up to Jerusalem to present him to the Lord... and to offer a sacrifice according to what is said in the law of the Lord, "a pair of turtledoves, or two young pigeons." Now there was a man in Jerusalem, whose name was Simeon, and this man was righteous and devout, looking for the consolation of Israel, and the Holy Spirit was upon him. And it had been revealed to him by the Holy Spirit that he should not see death before he had seen the Lord's Christ. And inspired by the Spirit he came into the temple; and when the parents brought in the child Jesus, to do for him according to the custom of the law, he took him up in his arms and blessed God and said, "Lord, now lettest thou thy servant depart in peace, according to thy word; for mine eyes have seen thy salvation which thou hast prepared in the presence of all peoples, a light for revelation to the Gentiles, and for glory to thy people Israel." ''',
    ),
    MysteryData(
      id: 'joyful_5',
      type: 'joyful',
      number: 5,
      titleEn: 'Finding in the Temple',
      titleLa: 'Invéntio in Templo',
      titleEs: 'El Niño perdido y hallado en el Templo',
      meditationEn: 'After three days of searching, Mary and Joseph find the Child Jesus in the Temple, sitting among the doctors, listening and asking questions. "Did you not know that I must be about My Father\'s business?"',
      meditationLa: 'Post tres dies quæréndi, María et Ioseph Púerum Iesum in Templo ínveniunt, sedéntem in médio doctórum, audiéntem et interrogántem. "Nesciébatis quia in his quæ Patris mei sunt, oportet me esse?"',
      meditationEs: 'Después de tres días de búsqueda, María y José encuentran al Niño Jesús en el Templo, sentado entre los doctores, escuchando y preguntando. "¿No sabíais que es necesario que yo esté en las cosas de mi Padre?"',
      fruitEn: 'Zeal for the glory of God; prudence',
      fruitLa: 'Zelus glóriæ Dei; prudéntia',
      fruitEs: 'Cel por la gloria de Dios; prudencia',
      imageAsset: 'assets/mysteries/joyful_5.jpg',
      verseRef: 'Luke 2:41-52',
      verseText: '''Now his parents went to Jerusalem every year at the feast of the Passover. And when he was twelve years old, they went up according to custom; and when the feast was ended, as they were returning, the boy Jesus stayed behind in Jerusalem. His parents did not know it, but supposing him to be in the company they went a day's journey, and they sought him among their kinsfolk and acquaintances; and when they did not find him, they returned to Jerusalem, seeking him. After three days they found him in the temple, sitting among the teachers, listening to them and asking them questions; and all who heard him were amazed at his understanding and his answers. And when they saw him they were astonished; and his mother said to him, "Son, why have you treated us so? Behold, your father and I have been looking for you anxiously." And he said to them, "How is it that you sought me? Did you not know that I must be in my Father's house?" ''',
    ),
  ];

  static const List<MysteryData> sorrowful = [
    MysteryData(
      id: 'sorrowful_1',
      type: 'sorrowful',
      number: 1,
      titleEn: 'The Agony in the Garden',
      titleLa: 'Agónia in Horto',
      titleEs: 'La Agonía en el Huerto',
      meditationEn: 'Jesus prays in the Garden of Gethsemane. His soul is sorrowful even unto death. He sweats blood. "Father, if it be possible, let this chalice pass from Me; nevertheless, not as I will, but as Thou wilt."',
      meditationLa: 'Iesus in Horto Gethsemaní orat. Ánima eius tristis est usque ad mortem. Sánguinem sudat. "Pater, si possíbile est, tránsiat a me calix iste; verúmtamen non sicut ego völo, sed sicut tu."',
      meditationEs: 'Jesús ora en el Huerto de los Olivos. Su alma está triste hasta la muerte. Suda sangre. "Padre, si es posible, pase de mí este cáliz; pero no como yo quiero, sino como tú."',
      fruitEn: 'Sorrow for sin; conformity to the will of God',
      fruitLa: 'Dolor pro peccáto; conformitáte voluntáti Dei',
      fruitEs: 'Dolor por el pecado; conformidad con la voluntad de Dios',
      imageAsset: 'assets/mysteries/sorrowful_1.jpg',
      verseRef: 'Matthew 26:36-46',
      verseText: '''Then Jesus went with them to a place called Gethsemane, and he said to his disciples, "Sit here, while I go yonder and pray." And taking with him Peter and the two sons of Zebedee, he began to be sorrowful and troubled. Then he said to them, "My soul is very sorrowful, even to death; remain here, and watch with me." And going a little farther he fell on his face and prayed, "My Father, if it be possible, let this cup pass from me; nevertheless, not as I will, but as thou wilt." And he came to the disciples and found them sleeping; and he said to Peter, "So, could you not watch with me one hour? Watch and pray that you may not enter into temptation; the spirit indeed is willing, but the flesh is weak." Again, for the second time, he went away and prayed, "My Father, if this cannot pass unless I drink it, thy will be done." ''',
    ),
    MysteryData(
      id: 'sorrowful_2',
      type: 'sorrowful',
      number: 2,
      titleEn: 'The Scourging at the Pillar',
      titleLa: 'Flagellátio ad Colúmnam',
      titleEs: 'La Flagelación',
      meditationEn: 'Jesus is stripped and scourged at the pillar. His sacred flesh is torn by the cruel lashes. He offers His suffering for our sins, that we may be healed.',
      meditationLa: 'Iesus exspoliátur et flagellátur ad colúmnam. Caro eius sacra crudélibus verbéribus lacerátur. Passiónem suam offert pro peccátis nostris, ut sanémur.',
      meditationEs: 'Jesús es despojado y flagelado en la columna. Su carne sagrada es desgarrada por los crueles azotes. Ofrece su sufrimiento por nuestros pecados, para que seamos sanados.',
      fruitEn: 'Mortification of the senses; penance',
      fruitLa: 'Mortificátio sensuum; pæniténtia',
      fruitEs: 'Mortificación de los sentidos; penitencia',
      imageAsset: 'assets/mysteries/sorrowful_2.jpg',
      verseRef: 'John 19:1',
      verseText: '''Then Pilate took Jesus and scourged him.''',
    ),
    MysteryData(
      id: 'sorrowful_3',
      type: 'sorrowful',
      number: 3,
      titleEn: 'The Crowning with Thorns',
      titleLa: 'Coronátio Spinis',
      titleEs: 'La Coronación de Espinas',
      meditationEn: 'Jesus is crowned with thorns. A purple cloak is thrown over His bleeding shoulders. They mock Him: "Hail, King of the Jews!" He suffers in silence for our pride.',
      meditationLa: 'Iesus spinis coronátur. Clamis purpúrea super úmera sánguinem stillántia iácitur. Eum illúdunt: "Ave, Rex Iudæórum!" Pro supérbia nostra siléntio pátitur.',
      meditationEs: 'Jesús es coronado de espinas. Le echan sobre los hombros sangrantes un manto de púrpura. Lo escarnecen: "¡Salve, Rey de los judíos!" Sufre en silencio por nuestra soberbia.',
      fruitEn: 'Contempt of the world; patience in suffering',
      fruitLa: 'Contémptus mundi; patiéntia in passióne',
      fruitEs: 'Desprecio del mundo; paciencia en el sufrimiento',
      imageAsset: 'assets/mysteries/sorrowful_3.jpg',
      verseRef: 'Matthew 27:27-31',
      verseText: '''Then the soldiers of the governor took Jesus into the praetorium, and they gathered the whole battalion before him. They stripped him and put a scarlet robe upon him, and plaiting a crown of thorns they put it on his head, and put a reed in his right hand. And kneeling before him they mocked him, saying, "Hail, King of the Jews!" And they spat upon him, and took the reed and struck him on the head. And when they had mocked him, they stripped him of the robe, and put his own clothes on him, and led him away to crucify him.''',
    ),
    MysteryData(
      id: 'sorrowful_4',
      type: 'sorrowful',
      number: 4,
      titleEn: 'The Carrying of the Cross',
      titleLa: 'Bajulátio Crucis',
      titleEs: 'El Camino del Calvario',
      meditationEn: 'Jesus carries His Cross to Calvary. He falls beneath its weight. Simon of Cyrene helps Him. Veronica wipes His face. The women of Jerusalem weep for Him.',
      meditationLa: 'Iesus Crucem suam ad Calváriam portat. Sub pondere cadit. Simon Cyrenénsis iuvat eum. Verónica vultum eius terget. Multíeres Ierúsalymsuper eum plorant.',
      meditationEs: 'Jesús carga su Cruz hacia el Calvario. Cae bajo su peso. Simón de Cirene le ayuda. Verónica limpia su rostro. Las mujeres de Jerusalén lloran por Él.',
      fruitEn: 'Patience in carrying our cross; love of the Cross',
      fruitLa: 'Patiéntia portándi crucem nostram; amor Crucis',
      fruitEs: 'Paciencia para llevar nuestra cruz; amor a la Cruz',
      imageAsset: 'assets/mysteries/sorrowful_4.jpg',
      verseRef: 'John 19:17',
      verseText: '''So they took Jesus, and he went out, bearing his own cross, to the place called the place of a skull, which is called in Hebrew Golgotha.''',
    ),
    MysteryData(
      id: 'sorrowful_5',
      type: 'sorrowful',
      number: 5,
      titleEn: 'The Crucifixion',
      titleLa: 'Crucifíxio',
      titleEs: 'La Crucifixión y Muerte',
      meditationEn: 'Jesus is nailed to the Cross. "Father, forgive them, for they know not what they do." He gives His Mother to John. He thirsts. He commends His spirit to the Father. He dies for our salvation.',
      meditationLa: 'Iesus clavis affígitur ad Crucem. "Pater, dimítte illis, non enim sciunt quid fáciunt." Matrem suam Ioánni trádit. Sítiit. Spíritum Patri comméndat. Pro salúte nostra móritur.',
      meditationEs: 'Jesús es clavado en la Cruz. "Padre, perdónalos, porque no saben lo que hacen." Entrega a su Madre a Juan. Tiene sed. Encomienda su espíritu al Padre. Muere por nuestra salvación.',
      fruitEn: 'Forgiveness of injuries; love of enemies',
      fruitLa: 'Dimíssio offensiónum; amor inimicórum',
      fruitEs: 'Perdón de las ofensas; amor a los enemigos',
      imageAsset: 'assets/mysteries/sorrowful_5.jpg',
      verseRef: 'John 19:18-30',
      verseText: '''There they crucified him, and with him two others, one on either side, and Jesus between them. Pilate also wrote a title and put it on the cross; it read, "Jesus of Nazareth, the King of the Jews." ... After this Jesus, knowing that all was now finished, said (to fulfil the scripture), "I thirst." A bowl full of vinegar stood there; so they put a sponge full of the vinegar on hyssop and held it to his mouth. When Jesus had received the vinegar, he said, "It is finished"; and he bowed his head and gave up his spirit.''',
    ),
  ];

  static const List<MysteryData> glorious = [
    MysteryData(
      id: 'glorious_1',
      type: 'glorious',
      number: 1,
      titleEn: 'The Resurrection',
      titleLa: 'Resurréctio',
      titleEs: 'La Resurrección',
      meditationEn: 'Jesus rises from the dead on the third day, conquering death and sin. The stone is rolled away. The tomb is empty. He appears to Mary Magdalene and the disciples. "I am the Resurrection and the Life."',
      meditationLa: 'Iesus a mórtuis tértia die resúrgit, mortem et peccátum vincens. Lapis revóluitur. Sepúlcrum vácuum est. Appáret Maríæ Magdalénæ et discípulis. "Ego sum Resurréctio et Vita."',
      meditationEs: 'Jesús resucita de entre los muertos al tercer día, venciendo a la muerte y al pecado. La piedra es removida. El sepulcro está vacío. Se aparece a María Magdalena y a los discípulos. "Yo soy la Resurrección y la Vida."',
      fruitEn: 'Faith; fervor in the service of God',
      fruitLa: 'Fides; fervor in servítio Dei',
      fruitEs: 'Fe; fervor en el servicio de Dios',
      imageAsset: 'assets/mysteries/glorious_1.jpg',
      verseRef: 'Matthew 28:1-10',
      verseText: '''Now after the sabbath, toward the dawn of the first day of the week, Mary Magdalene and the other Mary went to see the sepulchre. And behold, there was a great earthquake; for an angel of the Lord descended from heaven and came and rolled back the stone, and sat upon it. His appearance was like lightning, and his raiment white as snow. And for fear of him the guards trembled and became like dead men. But the angel said to the women, "Do not be afraid; for I know that you seek Jesus who was crucified. He is not here; for he has risen, as he said. Come, see the place where he lay." ''',
    ),
    MysteryData(
      id: 'glorious_2',
      type: 'glorious',
      number: 2,
      titleEn: 'The Ascension',
      titleLa: 'Ascénsio',
      titleEs: 'La Ascensión',
      meditationEn: 'Jesus ascends into heaven, sitting at the right hand of the Father. He sends the apostles to preach the Gospel to all nations. "I am with you always, even unto the end of the world."',
      meditationLa: 'Iesus in cælum ascéndit, sedens ad déxteram Patris. Apostólos mittit prædicáre Evangélium ómnibus géntibus. "Ego vobíscum sum ómnibus diébus usque ad consummatiónem sǽculi."',
      meditationEs: 'Jesús asciende al cielo, sentándose a la derecha del Padre. Envía a los apóstoles a predicar el Evangelio a todas las naciones. "Yo estoy con vosotros todos los días, hasta el fin del mundo."',
      fruitEn: 'Hope; desire for heaven',
      fruitLa: 'Spes; desiderium cæli',
      fruitEs: 'Esperanza; deseo del cielo',
      imageAsset: 'assets/mysteries/glorious_2.jpg',
      verseRef: 'Acts 1:6-11',
      verseText: '''So when they had come together, they asked him, "Lord, will you at this time restore the kingdom to Israel?" He said to them, "It is not for you to know times or seasons which the Father has fixed by his own authority. But you shall receive power when the Holy Spirit has come upon you; and you shall be my witnesses in Jerusalem and in all Judea and Samaria and to the end of the earth." And when he had said this, as they were looking on, he was lifted up, and a cloud took him out of their sight. And while they were gazing into heaven as he went, behold, two men stood by them in white robes, and said, "Men of Galilee, why do you stand looking into heaven? This Jesus, who was taken up from you into heaven, will come in the same way as you saw him go into heaven." ''',
    ),
    MysteryData(
      id: 'glorious_3',
      type: 'glorious',
      number: 3,
      titleEn: 'The Descent of the Holy Spirit',
      titleLa: 'Déscensus Spíritus Sancti',
      titleEs: 'La Venida del Espíritu Santo',
      meditationEn: 'The Holy Spirit descends upon the Apostles in the form of tongues of fire. They are filled with the Spirit and speak in diverse tongues. The Church is born. Three thousand are baptized.',
      meditationLa: 'Spíritus Sanctus super Apostólos descéndit in forma linguárum ignis. Spíritu repléntur et diversis linguis loquúntur. Ecclésia nascítur. Tria míllia baptizántur.',
      meditationEs: 'El Espíritu Santo desciende sobre los Apóstoles en forma de lenguas de fuego. Se llenan del Espíritu y hablan en diversas lenguas. Nace la Iglesia. Tres mil son bautizados.',
      fruitEn: 'Love of God; zeal for the salvation of souls',
      fruitLa: 'Amor Dei; zelus pro salúte animárum',
      fruitEs: 'Amor de Dios; celo por la salvación de las almas',
      imageAsset: 'assets/mysteries/glorious_3.jpg',
      verseRef: 'Acts 2:1-4',
      verseText: '''When the day of Pentecost had come, they were all together in one place. And suddenly a sound came from heaven like the rush of a mighty wind, and it filled all the house where they were sitting. And there appeared to them tongues as of fire, distributed and resting on each one of them. And they were all filled with the Holy Spirit and began to speak in other tongues, as the Spirit gave them utterance.''',
    ),
    MysteryData(
      id: 'glorious_4',
      type: 'glorious',
      number: 4,
      titleEn: 'The Assumption',
      titleLa: 'Assúmptio',
      titleEs: 'La Asunción',
      meditationEn: 'The Blessed Virgin Mary is assumed body and soul into heaven. She who bore the Son of God in her womb is taken up to share in His glory. She is crowned Queen of Heaven and Earth.',
      meditationLa: 'Beáta Virgo María, córpore et ánima in cælum assúmptur. Quæ Fílium Dei in útero géruit, in eius glóriam assúmptur. Regína Cæli et Terræ coronátur.',
      meditationEs: 'La Santísima Virgen María es asunta al cielo en cuerpo y alma. La que llevó al Hijo de Dios en su seno es llevada a compartir su gloria. Es coronada Reina del Cielo y de la Tierra.',
      fruitEn: 'Devotion to Mary; grace of a happy death',
      fruitLa: 'Devótio Maríæ; grátia felícis mortis',
      fruitEs: 'Devoción a María; gracia de una buena muerte',
      imageAsset: 'assets/mysteries/glorious_4.jpg',
      verseRef: 'Revelation 12:1',
      verseText: '''And a great portent appeared in heaven, a woman clothed with the sun, with the moon under her feet, and on her head a crown of twelve stars.''',
    ),
    MysteryData(
      id: 'glorious_5',
      type: 'glorious',
      number: 5,
      titleEn: 'The Coronation of the Blessed Virgin',
      titleLa: 'Coronátio Beátæ Vírginis',
      titleEs: 'La Coronación de la Santísima Virgen',
      meditationEn: 'Mary is crowned Queen of Heaven and Earth by the Most Holy Trinity. She reigns with Christ and intercedes for us as our loving Mother. All generations shall call her blessed.',
      meditationLa: 'María a Sanctíssima Trinitáte Regína Cæli et Terræ coronátur. Cum Christo regnat et pro nobis ut Mater amáns intercédit. Omnes generatiónes beátam eam dícent.',
      meditationEs: 'María es coronada Reina del Cielo y de la Tierra por la Santísima Trinidad. Reina con Cristo e intercede por nosotros como Madre amorosa. Todas las generaciones la llamarán bienaventurada.',
      fruitEn: 'Perseverance and increase of virtue; final perseverance',
      fruitLa: 'Perseverántia et augmentum virtútis; finalis perseverántia',
      fruitEs: 'Perseverancia y aumento de virtud; perseverancia final',
      imageAsset: 'assets/mysteries/glorious_5.jpg',
      verseRef: 'Revelation 12:1',
      verseText: '''And a great portent appeared in heaven, a woman clothed with the sun, with the moon under her feet, and on her head a crown of twelve stars.''',
    ),
  ];

  static const List<MysteryData> luminous = [
    MysteryData(
      id: 'luminous_1',
      type: 'luminous',
      number: 1,
      titleEn: 'The Baptism of Our Lord',
      titleLa: 'Baptísma Dómini',
      titleEs: 'El Bautismo del Señor',
      meditationEn: 'Jesus comes to John at the Jordan to be baptized. The heavens open, the Spirit descends like a dove, and the voice of the Father proclaims: "This is My beloved Son, in whom I am well pleased."',
      meditationLa: 'Iesus ad Ioánnem in Iordáne venit baptizári. Cæli aperiúntur, Spíritus ut colúmba descéndit, et vox Patris pronúntiat: "Hic est Fílius meus diléctus, in quo mihi bene complácui."',
      meditationEs: 'Jesús viene a Juan al Jordán para ser bautizado. Los cielos se abren, el Espíritu desciende como paloma, y la voz del Padre proclama: "Este es mi Hijo amado, en quien me complazco."',
      fruitEn: 'Openness to the Holy Spirit; living our baptismal promises',
      fruitLa: 'Apértio Spíritu Sancto; vivénda promíssa baptísmatis',
      fruitEs: 'Apertura al Espíritu Santo; vivir las promesas bautismales',
      imageAsset: 'assets/mysteries/luminous_1.jpg',
      verseRef: 'Matthew 3:13-17',
      verseText: '''Then Jesus came from Galilee to the Jordan to John, to be baptized by him. John would have prevented him, saying, "I need to be baptized by you, and do you come to me?" But Jesus answered him, "Let it be so now; for thus it is fitting for us to fulfil all righteousness." Then he consented. And when Jesus was baptized, he went up immediately from the water, and behold, the heavens were opened and he saw the Spirit of God descending like a dove, and alighting on him; and lo, a voice from heaven, saying, "This is my beloved Son, with whom I am well pleased." ''',
    ),
    MysteryData(
      id: 'luminous_2',
      type: 'luminous',
      number: 2,
      titleEn: 'The Wedding at Cana',
      titleLa: 'Núptiæ Canénses',
      titleEs: 'Las Bodas de Caná',
      meditationEn: 'At the wedding feast at Cana, Mary intercedes with her Son: "They have no wine." Jesus performs His first public miracle, changing water into wine. "Do whatever He tells you."',
      meditationLa: 'In núptiis Canénsibus, María apud Fílium suum intercédit: "Vinum non habent." Iesus primum públicum miráculum facit, aquam in vinum convertens. "Quodcúmque díxerit vobis, fácite."',
      meditationEs: 'En las bodas de Caná, María intercede ante su Hijo: "No tienen vino." Jesús realiza su primer milagro público, convirtiendo el agua en vino. "Haced todo lo que Él os diga."',
      fruitEn: 'Trust in Mary\'s intercession; doing whatever Jesus tells us',
      fruitLa: 'Fidúcia in intercessióne Maríæ; faciénda quæcúmque Iesus nobis dícit',
      fruitEs: 'Confianza en la intercesión de María; hacer lo que Jesús nos diga',
      imageAsset: 'assets/mysteries/luminous_2.jpg',
      verseRef: 'John 2:1-11',
      verseText: '''On the third day there was a marriage at Cana in Galilee, and the mother of Jesus was there; Jesus also was invited to the marriage, with his disciples. When the wine failed, the mother of Jesus said to him, "They have no wine." And Jesus said to her, "O woman, what have you to do with me? My hour has not yet come." His mother said to the servants, "Do whatever he tells you." ... This, the first of his signs, Jesus did at Cana in Galilee, and manifested his glory; and his disciples believed in him.''',
    ),
    MysteryData(
      id: 'luminous_3',
      type: 'luminous',
      number: 3,
      titleEn: 'The Proclamation of the Kingdom',
      titleLa: 'Proclamátio Regni',
      titleEs: 'La Proclamación del Reino',
      meditationEn: 'Jesus preaches the Gospel of the Kingdom: "Repent, for the kingdom of heaven is at hand." He calls sinners to conversion and offers the mercy of the Father to all who repent.',
      meditationLa: 'Iesus Evangélium Regni prædícit: "Pænitémini, appropinquávit enim regnum cælórum." Peccatóres ad conversiónem vocat et misericórdiam Patris ómnibus pæniténtibus offert.',
      meditationEs: 'Jesús predica el Evangelio del Reino: "Arrepentíos, porque el reino de los cielos se ha acercado." Llama a los pecadores a la conversión y ofrece la misericordia del Padre a todos los que se arrepienten.',
      fruitEn: 'Repentance and conversion; trust in God\'s mercy',
      fruitLa: 'Pæniténtia et convérsio; fidúcia in misericórdia Dei',
      fruitEs: 'Arrepentimiento y conversión; confianza en la misericordia de Dios',
      imageAsset: 'assets/mysteries/luminous_3.jpg',
      verseRef: 'Mark 1:14-15',
      verseText: '''Now after John was arrested, Jesus came into Galilee, preaching the gospel of God, and saying, "The time is fulfilled, and the kingdom of God is at hand; repent, and believe in the gospel." ''',
    ),
    MysteryData(
      id: 'luminous_4',
      type: 'luminous',
      number: 4,
      titleEn: 'The Transfiguration',
      titleLa: 'Transfigurátio',
      titleEs: 'La Transfiguración',
      meditationEn: 'Jesus takes Peter, James, and John up the mountain and is transfigured before them. His face shines like the sun, His garments become white as light. Moses and Elijah appear. The Father speaks: "Listen to Him."',
      meditationLa: 'Iesus Petrum, Iacóbum et Ioánnem in montem dúcit et coram eis transfigurátur. Fáciés eius sicut sol lúcet, vestiménta eius alba sicut lux fíunt. Móyses et Elías appárent. Pater lóquitur: "Aúdite eum."',
      meditationEs: 'Jesús toma a Pedro, Santiago y Juan al monte y se transfigura ante ellos. Su rostro brilla como el sol, sus vestiduras se vuelven blancas como la luz. Aparecen Moisés y Elías. El Padre habla: "Escuchadle."',
      fruitEn: 'Desire for holiness; listening to Christ',
      fruitLa: 'Desidérium sanctitátis; audiéndum Christo',
      fruitEs: 'Deseo de santidad; escuchar a Cristo',
      imageAsset: 'assets/mysteries/luminous_4.jpg',
      verseRef: 'Matthew 17:1-8',
      verseText: '''And after six days Jesus took with him Peter and James and John his brother, and led them up a high mountain apart. And he was transfigured before them, and his face shone like the sun, and his garments became white as light. And behold, there appeared to them Moses and Elijah, talking with him... He was still speaking, when lo, a bright cloud overshadowed them, and a voice from the cloud said, "This is my beloved Son, with whom I am well pleased; listen to him." ''',
    ),
    MysteryData(
      id: 'luminous_5',
      type: 'luminous',
      number: 5,
      titleEn: 'The Institution of the Eucharist',
      titleLa: 'Institútio Eucharístiæ',
      titleEs: 'La Institución de la Eucaristía',
      meditationEn: 'At the Last Supper, Jesus takes bread and wine: "This is My Body... This is My Blood of the new and everlasting covenant." He gives Himself to us in the Most Blessed Sacrament, to remain with us always.',
      meditationLa: 'In Coéna Domínica, Iesus panem et vinum accípit: "Hoc est Corpus meum... Hic est sanguis meus novi et ætérni testaménti." Seipsum nobis in Sacraménto Altíssimo dat, ut nobíscum semper maneát.',
      meditationEs: 'En la Última Cena, Jesús toma pan y vino: "Este es mi Cuerpo... Esta es mi Sangre del nuevo y eterno pacto." Se da a sí mismo en el Santísimo Sacramento, para permanecer siempre con nosotros.',
      fruitEn: 'Love of the Eucharist; adoration of the Blessed Sacrament',
      fruitLa: 'Amor Eucharístiæ; adesátio Sanctíssimi Sacraménti',
      fruitEs: 'Amor a la Eucaristía; adoración al Santísimo Sacramento',
      imageAsset: 'assets/mysteries/luminous_5.jpg',
      verseRef: '1 Corinthians 11:23-26',
      verseText: '''For I received from the Lord what I also delivered to you, that the Lord Jesus on the night when he was betrayed took bread, and when he had given thanks, he broke it, and said, "This is my body which is for you. Do this in remembrance of me." In the same way also the cup, after supper, saying, "This cup is the new covenant in my blood. Do this, as often as you drink it, in remembrance of me." For as often as you eat this bread and drink the cup, you proclaim the Lord's death until he comes.''',
    ),
  ];

  /// Get mysteries by type
  static List<MysteryData> getMysteries(String type) {
    switch (type) {
      case 'joyful': return joyful;
      case 'sorrowful': return sorrowful;
      case 'glorious': return glorious;
      case 'luminous': return luminous;
      default: return joyful;
    }
  }
}
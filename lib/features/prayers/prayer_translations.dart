/// Trilingual prayer texts: Latin + Spanish lookups by prayer title.
/// Prayers missing from a map fall back gracefully (the detail screen simply
/// doesn't offer that language). The Latin texts follow traditional liturgical
/// usage; Spanish follows the standard devotional forms.
class PrayerTranslations {
  static const Map<String, String> latin = {
    'The Angelus':
        'ANGELUS\n\nV. Angelus Domini nuntiavit Mariæ.\nR. Et concepit de Spiritu Sancto.\n\nAve Maria, gratia plena, Dominus tecum; benedicta tu in mulieribus, et benedictus fructus ventris tui, Iesus. Sancta Maria, Mater Dei, ora pro nobis peccatoribus, nunc et in hora mortis nostræ. Amen.\n\nV. Ecce ancilla Domini.\nR. Fiat mihi secundum verbum tuum.\n\nAve Maria, gratia plena, Dominus tecum; benedicta tu in mulieribus, et benedictus fructus ventris tui, Iesus. Sancta Maria, Mater Dei, ora pro nobis peccatoribus, nunc et in hora mortis nostræ. Amen.\n\nV. Et Verbum caro factum est.\nR. Et habitavit in nobis.\n\nAve Maria, gratia plena, Dominus tecum; benedicta tu in mulieribus, et benedictus fructus ventris tui, Iesus. Sancta Maria, Mater Dei, ora pro nobis peccatoribus, nunc et in hora mortis nostræ. Amen.\n\nV. Ora pro nobis, sancta Dei Genetrix.\nR. Ut digni efficiamur promissionibus Christi.\n\nOREMUS\nGratiam tuam, quæsumus, Domine, mentibus nostris infunde; ut qui, angelo nuntiante, Christi Filii tui incarnationem cognovimus, per passionem ejus et crucem ad resurrectionis gloriam perducamur. Per eundem Christum Dominum nostrum. Amen.',
    'Regina Caeli (Easter Angelus)':
        'REGINA CAELI\n\nV. Regina cæli, lætare, alleluia.\nR. Quia quem meruisti portare, alleluia.\nV. Resurrexit, sicut dixit, alleluia.\nR. Ora pro nobis Deum, alleluia.\nV. Gaude et lætare, Virgo Maria, alleluia.\nR. Quia surrexit Dominus vere, alleluia.\nV. Ora pro nobis, sancta Dei Genetrix.\nR. Ut digni efficiamur promissionibus Christi, alleluia.\n\nOREMUS\nDeus, qui per Resurrectionem Filii tui, Domini nostri Iesu Christi, mundum lætificare dignatus es: præsta, quæsumus; ut per ejusdem Genetricis Virginis Mariæ intercessionem ad perpetuæ gaudia vitæ perfrui mereamur. Per eundem Christum Dominum nostrum.\nR. Amen.',
    'Morning Offering':
        'O Iesu dulcissime, per Cor Immaculatum Mariæ, Matris Tuae et nostræ, offero Tibi preces, opera, gaudia ac patientias huius diei, ad omnes intentiones Cordis Tui Sanctissimi, in unione cum sanctissimo Sacrificio Missæ per totum orbem terrarum celebrato, pro salute animarum, pro reparatione peccatorum, pro reunione omnium christifidelium, atque præsertim pro intentionibus Sancti Patris huius mensis. Amen.',
    'Act of Contrition':
        'Deus meus, ex toto corde poenitet me omnium peccatorum meorum, eaque detestor, quia in offensionem Tui commisi, Deus meus, qui es omnis justitia et omnis bonitas atque dignus es amore infinito. Firmiter propono, Te auxiliante, de cetero non peccare et omnes occasiones peccandi cavere. Per merita passionis Domini nostri Iesu Christi, miserere mei. Amen.',
    'Anima Christi':
        'Anima Christi, sanctifica me.\nCorpus Christi, salva me.\nSanguis Christi, inebria me.\nAqua lateris Christi, lava me.\nPassio Christi, conforta me.\nO bone Jesu, exaudi me.\nIntra tua vulnera absconde me.\nNe permittas me separari a Te.\nAb hoste maligno defende me.\nIn hora mortis meæ voca me.\nEt iube me venire ad Te,\nut cum Sanctis tuis laudem Te\nin sæcula sæculorum. Amen.',
    'Prayer before Mass':
        'Omnipotens sempiterne Deus, ecce accedo ad Sacramentum unigeniti Filii tui, Domini nostri Iesu Christi: ego ægrotus venio ad Medicaæ vitae; immundus ad Fontem misericordiæ; cæcus ad Lucem æternæ claritatis; pauper et egenus ad Dominum cæli et terræ. Deprecor igitur immensam largitatem tuæ divitiae, ut sanes et mundes me, omnes maculas vitiorum eveillas, atque omnia in me secundum præcepta tua disponas, ut, Te adiuvante, hic et in futurum digne servari merear, o Salvator mundi, qui vivis et regnas in sæcula sæculorum. Amen.',
    'Prayer before Communion':
        'Domine, non sum dignus ut intres sub tectum meum: sed tantum dic verbo, et sanabitur anima mea. Te, Domine, indignum confiteor ad recipientum Corpus tuum sacrum et Sanguinem pretiosum. Credo firmiter, et confiteor, Te esse Christum, Filium Dei vivi, qui in mundum venisti ut salvares peccatores, quorum primus ego sum. Quare, Domine, obsecro, ut gratia tua, quæ infinita est, suppleat quæ in me desunt, ut digne accedam ad hoc sanctissimum Sacramentum. Amen.',
    'Prayer after Communion':
        'Gratias tibi ago, Domine, Pater sancte, omnipotens, æterne Deus, qui me peccatorem, indignum famulum tuum, ex mera et larga benignitate tua dignatus es pascere Corpore pretioso et Sanguine Filii tui, Domini nostri Iesu Christi. Sit hæc sancta Communio mihi non in condemnationem, sed in defensionem et tutamen, pignusque futuræ gloriæ. Auge fidem meam, conforta charitatem, et confirmes gratiam tuam in me. Amen.',
    'Anima Christi (after Communion)':
        'Anima Christi, sanctifica me.\nCorpus Christi, salva me.\nSanguis Christi, inebria me.\nAqua lateris Christi, lava me.\nPassio Christi, conforta me.\nO bone Jesu, exaudi me.\nIntra tua vulnera absconde me.\nNe permittas me separari a Te.\nAb hoste maligno defende me.\nIn hora mortis meæ voca me.\nEt iube me venire ad Te,\nut cum Sanctis tuis laudem Te\nin sæcula sæculorum. Amen.',
    'Prayer of St. Thomas Aquinas before Communion':
        'Omnipotens sempiterne Deus, ecce accedo ad Sacramentum unigeniti Filii tui, Domini nostri Iesu Christi, tanquam æger ad Medicaæ vitae, immundus ad Fontem misericordiæ, cæcus ad Lucem æternæ claritatis, pauper et egenus ad Dominum cæli et terræ. Te, igitur, deprecor, immensæ divitiæ tuæ abundantia, ut emundare et sanare digneris cor meum, sanctificare animam meam, et dignum facere Corpus et Sanguinem Filii tui accipere. Qui vivis et regnas in sæcula sæculorum. Amen.',
    'Prayer of St. Thomas Aquinas after Communion':
        'Gratias tibi ago, sancte Pater, Domine omnipotens, æterne Deus, quia me peccatorem, indignum famulum tuum, ex mera et larga tua benignitate dignatus es pascere sacro Corpore et Sanguine Filii tui, Domini nostri Iesu Christi. Sit mihi hæc Communio non in condemnationem, sed in salutem; sit mihi armorum fidei, spei et caritatis lorica, bonæ conscientiæ scutum, omniumque virtutum munimentum. Qui vivis et regnas in sæcula sæculorum. Amen.',
    'Prayer after Mass (Thanksgiving)':
        'Benedictum, laudatum atque adoratum sit Iesum Christum sedentem super solium gloriæ suæ in cælo, et præsentem in sanctissimo Sacramento Altaris. O Sacramentum sanctissimum, O Sacramentum divinum, omnis laus et omnis gratiarum actio sit Tibi in omni momento. Cor Iesu, in sanctissimo Sacramento Altaris contentum, benedictum, adoratum et cum gratiarum actione amatum sit in omnibus tabernaculis mundi usque ad finem sæculorum. Amen.',
    'Night Prayer':
        'Visita, quæsumus, Domine, habitationem istam, et omnes insidias inimici ab ea repelle; Angeli tui sancti habitent in ea, qui nos in pace custodiant; et benedictio tua sit super nos semper. Per Christum Dominum nostrum. Amen.',
    'Prayer of Consecration of the Day':
        'O Deus, Rex cæli et terræ, digneris hodie ordinare et sanctificare, regere et gubernare corda et corpora nostra, cogitationes, verba et opera nostra, secundum legem tuam, ut, Te adiuuante, hic et in futurum digne salvari mereamur, o Salvator mundi, qui vivis et regnas in sæcula sæculorum. Amen.',
    'Salve Regina':
        'Salve, Regina, Mater misericordiæ,\nvita, dulcedo et spes nostra, salve.\nAd te clamamus, exsules filii Hevae.\nAd te suspiramus, gementes et flentes\nin hac lacrimarum valle.\nEia ergo, Advocata nostra,\nillos tuos misericordes oculos ad nos converte.\nEt Iesum, benedictum fructum ventris tui,\nnobis post hoc exsilium ostende.\nO clemens, o pia, o dulcis Virgo Maria.\n\nV. Ora pro nobis, sancta Dei Genetrix.\nR. Ut digni efficiamur promissionibus Christi. Amen.',
    'Memorare':
        'Memorare, o piissima Virgo Maria, non audisse unquam in mundo quemquam qui ad tua præsidia confugeret, opem tuam imploraret, suffragium tuum postularet, esse derelictum. Ego, tali animatus exempulo, ad te, Virgo Virginum, Mater, venio; ad te venio; coram te peccator assisto supplex. O Mater Verbi Incarnati, noli despicere preces meas, sed audi propitia et exaudi. Amen.',
    'Sub Tuum Praesidium':
        'Sub tuum præsidium confugimus, Sancta Dei Genetrix.\nNostras deprecationes ne despicias in necessitatibus nostris,\nsed a periculis cunctis libera nos semper,\nVirgo gloriosa et benedicta. Amen.',
    'Ave Maris Stella':
        'Ave, Maris Stella,\nDei Mater alma,\natque semper Virgo,\nfelix cæli porta.\n\nSumens illud Ave\nGabrielis ore,\nfunda nos in pace,\nmutans Evæ nomen.\n\nSolve vincla reis,\nfer lumen cæcis,\nmala nostra pelle,\nbona cuncta posce.\n\nMonstra te esse Matrem,\nsumat per te precem\nqui pro nobis natus\ntulit esse tuus.\n\nVirgo singularis,\ninter omnes mitis,\nnos culpis solutos\nmites fac et castos.\n\nVitam præsta puram,\niter para tutum,\nut videntes Iesum\nsemper collætemur.\n\nSit laus Deo Patri,\nsummo Christo decus,\nSpiritui Sancto\nhonor, tribus unus. Amen.',
    'De Profundis (Psalm 130)':
        'De profundis clamavi ad te, Domine:\nDomine, exaudi vocem meam.\nFiant aures tuæ intendentes,\nin vocem deprecationis meæ.\nSi iniquitates observaveris, Domine,\nDomine, quis sustinebit?\nQuia apud te propitiatio est,\net propter legem tuam sustinui te, Domine.\nSustinuit anima mea in verbo ejus;\nsperavit anima mea in Domino.\nA custodia matutina usque ad noctem,\nsperet Israel in Domino.\nQuia apud Dominum misericordia,\net copiosa apud eum redemptio.\nEt ipse redimet Israel\nex omnibus iniquitatibus ejus.\n\nGloria Patri, et Filio, et Spiritui Sancto.\nSicut erat in principio, et nunc, et semper,\net in sæcula sæculorum. Amen.',
    'Eternal Rest':
        'Requiem æternam dona eis, Domine:\net lux perpetua luceat eis.\nRequiescant in pace. Amen.\n\nAnimabus fidelium defunctorum, per misericordiam Dei, requiescant in pace. Amen.',
    'Prayer for the Dead':
        'Deus, Creator et Redemptor omnium fidelium, dimitte animabus servorum et ancillarum tuarum omnem culpam, et eis gratiam indulgentiæ semper optatæ concede, ut piis supplicationibus præmia sempiterna consequantur. Qui vivis et regnas in sæcula sæculorum. Amen.',
    'Act of Faith':
        'Deus meus, firmiter credo Te esse unum Deum in tribus divinis Personis, Patre, Filio et Spiritu Sancto; credo Filium tuum divinum propter peccata nostra carnem suscepisse, mortuum esse et resurrexisse, atque venturum esse ad judicandum vivos et mortuos. Hæc credo, et omnia quæ sancta Catholica Ecclesia docet, quia Tu ea revelasti, qui falli non potes nec fallere. Amen.',
    'Act of Hope':
        'Deus meus, innitens omnipotentiae tuae atque infinitæ bonitati et promissis tuis, confido me obtenturum remissionem peccatorum meorum, auxilium gratiæ tuæ et vitam æternam, per merita Iesu Christi, Domini et Redemptoris mei. Amen.',
    'Act of Charity':
        'Deus meus, diligo Te super omnia toto corde et tota anima mea, quia es omne bonum et dignus amore infinito; et propter amorem tui proximum diligo quasi meipsum, omnesque offensiones dimitto, cunctisque qui me offendunt ignosco, et de omnibus in quibus Te offendo veniam peto. Amen.',
    'Prayer to St. Michael the Archangel':
        'Sancte Michael Archangele, defende nos in proelio; contra nequitiam et insidias diaboli esto præsidium. Imperet illi Deus, supplices deprecamur: tuque, Princeps militiae cælestis, Satanam aliosque spiritus malignos, qui ad perditionem animarum pervagantur in mundo, divina virtute in infernum detrude. Amen.',
    'Prayer before a Crucifix':
        'En ego, o bone et dulcissime Iesu,\ncoram te procumbo,\nac summo animi desiderio\nte deprecor ac obsecro,\nut in corde meo vitales sensus\nfidei, spei et caritatis imprimas,\nveram peccatorum meorum poenitentiam\ncum firmo proposito emendandi,\n dum mecum intus contemplor\nac mente considero\nquinque vulnera tua pretiosissima,\neo affectu quo David prophetus dicebat:\n"Foderunt manus meas et pedes meos;\nnumeravi omnia ossa mea."',
  };

  static const Map<String, String> spanish = {
    'The Angelus':
        'ÁNGELUS\n\nV. El Ángel del Señor anunció a María.\nR. Y concibió por obra y gracia del Espíritu Santo.\n\nDios te salve María, llena eres de gracia; el Señor contigo; bendita tú eres entre todas las mujeres, y bendito es el fruto de tu vientre, Jesús. Santa María, Madre de Dios, ruega por nosotros, los pecadores, ahora y en la hora de nuestra muerte. Amén.\n\nV. He aquí la esclava del Señor.\nR. Hágase en mí según tu palabra.\n\nDios te salve María, llena eres de gracia; el Señor contigo; bendita tú eres entre todas las mujeres, y bendito es el fruto de tu vientre, Jesús. Santa María, Madre de Dios, ruega por nosotros, los pecadores, ahora y en la hora de nuestra muerte. Amén.\n\nV. Y el Verbo se hizo carne.\nR. Y habitó entre nosotros.\n\nDios te salve María, llena eres de gracia; el Señor contigo; bendita tú eres entre todas las mujeres, y bendito es el fruto de tu vientre, Jesús. Santa María, Madre de Dios, ruega por nosotros, los pecadores, ahora y en la hora de nuestra muerte. Amén.\n\nV. Ruega por nosotros, Santa Madre de Dios.\nR. Para que seamos dignos de alcanzar las promesas de Cristo.\n\nOREMOS\nInfunde, Señor, tu gracia en nuestras almas, para que, los que conocimos por el anuncio del Ángel la Encarnación de tu Hijo Jesucristo, lleguemos por su Pasión y su Cruz a la gloria de su Resurrección. Por Jesucristo nuestro Señor. Amén.',
    'Regina Caeli (Easter Angelus)':
        'REGINA CAELI\n\nV. Reina del cielo, alégrate, aleluya.\nR. Porque el Señor, a quien llevaste en tu seno, aleluya.\nV. Ha resucitado como dijo, aleluya.\nR. Ruega por nosotros a Dios, aleluya.\nV. Alégrate y goza, Virgen María, aleluya.\nR. Porque verdaderamente ha resucitado el Señor, aleluya.\nV. Ruega por nosotros, Santa Madre de Dios.\nR. Para que seamos dignos de alcanzar las promesas de Cristo, aleluya.\n\nOREMOS\nOh Dios, que por la Resurrección de tu Hijo, nuestro Señor Jesucristo, te dignaste alegrar al mundo, concédenos, por intercesión de su Madre la Virgen María, alcanzar los gozos de la vida eterna. Por el mismo Jesucristo nuestro Señor. Amén.',
    'Morning Offering':
        'OH JESÚS, por el Inmaculado Corazón de María, Te ofrezco mis oraciones, obras, trabajos, alegrías y sufrimientos de este día, por todas las intenciones de tu Sagrado Corazón, en unión con el Santo Sacrificio de la Misa que se celebra en todo el mundo, por la salvación de las almas, la reparación de los pecados, la reunión de todos los cristianos, y en particular por las intenciones del Santo Padre este mes. Amén.',
    'Act of Contrition':
        'Dios mío, me pesa de todo corazón haberte ofendido, y detesto todos mis pecados, porque pecando ofendí a Ti, Dios mío, que eres todo bondad y mereces ser amado sobre todas las cosas. Propongo firmemente, con tu ayuda, no volver a pecar y evitar las ocasiones próximas de pecado. Amén.',
    'Anima Christi':
        'Anima de Cristo, santifícame.\nCuerpo de Cristo, sálvame.\nSangre de Cristo, embriágame.\nAgua del costado de Cristo, lávame.\nPasión de Cristo, confórtame.\nOh buen Jesús, óyeme.\nEn tus llagas escóndeme.\nNo permitas que me separe de Ti.\nDel enemigo malintencionado defiéndeme.\nEn la hora de mi muerte llámame,\ny mándame venir a Ti,\npara que con tus Santos te alabe\npor los siglos de los siglos. Amén.',
    'Prayer before Mass':
        'Oh Dios todopoderoso y eterno, me acerco al Sacramento de tu Hijo unigénito, nuestro Señor Jesucristo. Vengo enfermo al Médico de la vida; inmundo, a la Fuente de la misericordia; ciego, a la Luz eterna; pobre y necesitado, al Señor del cielo y de la tierra. Te ruego, pues, por la inmensa grandeza de tu divinidad, que me laves, me limpies y me vivifiques con tu Espíritu Santo. Amén.',
    'Prayer before Communion':
        'Señor, no soy digno de que entres en mi casa, pero di una palabra y seré salvado. Reconozco, Señor, que no soy digno de recibir tu Cuerpo sacro y tu Sangre preciosa; pero confieso firmemente que Tú eres el Cristo, Hijo de Dios vivo, que viniste al mundo para salvar a los pecadores, de los cuales soy el primero. Te ruego, pues, que tu gracia infinita suple lo que a mí me falta, para acercarme dignamente a este Santísimo Sacramento. Amén.',
    'Prayer after Communion':
        'Te doy gracias, Señor, Padre santo, Dios todopoderoso y eterno, que has querido alimentar a mí, indigno siervo tuyo y pecador, con el precioso Cuerpo y Sangre de tu Hijo, nuestro Señor Jesucristo. Que esta Santa Comunión no me sea de condenación, sino de defensa contra el pecado y prenda de la gloria futura. Que aumente mi fe, fortalezca mi caridad y me confirme en tu gracia. Amén.',
    'Anima Christi (after Communion)':
        'Anima de Cristo, santifícame.\nCuerpo de Cristo, sálvame.\nSangre de Cristo, embriágame.\nAgua del costado de Cristo, lávame.\nPasión de Cristo, confórtame.\nOh buen Jesús, óyeme.\nEn tus llagas escóndeme.\nNo permitas que me separe de Ti.\nDel enemigo malintencionado defiéndeme.\nEn la hora de mi muerte llámame,\ny mándame venir a Ti,\npara que con tus Santos te alabe\npor los siglos de los siglos. Amén.',
    'Prayer of St. Thomas Aquinas before Communion':
        'Oh Dios todopoderoso y eterno, me acerco al Sacramento de tu Hijo unigénito como enfermo al Médico de la vida, como inmundo a la Fuente de la misericordia, como ciego a la Luz eterna, como pobre y necesitado al Señor del cielo y de la tierra. Te ruego, por la inmensa abundancia de tu misericordia, que te dignes purificar mi corazón y santificar mi alma, para hacerme digno de recibir el Cuerpo y la Sangre de tu Hijo. Tú que vives y reinas por los siglos de los siglos. Amén.',
    'Prayer of St. Thomas Aquinas after Communion':
        'Te doy gracias, Padre santo, Señor todopoderoso, Dios eterno, que, sin merecerlo, me has querido alimentar, con la pura y amplia bondad tuya, con el Cuerpo y la Sangre de tu Hijo, nuestro Señor Jesucristo. Que esta Comunión no sea para mi condenación sino para mi salvación; que me sea coraza de fe, esperanza y caridad, escudo y fortaleza de una buena conciencia. Tú que vives y reinas por los siglos de los siglos. Amén.',
    'Prayer after Mass (Thanksgiving)':
        'Alabado, bendito y adorado sea Jesucristo en su trono de gloria en el Cielo y en el Santísimo Sacramento del Altar. Oh Sacramento santísimo, oh Sacramento divino, toda alabanza y toda acción de gracias sea para Ti en todo momento. Que el Corazón de Jesús en el Santísimo Sacramento del Altar sea alabado, adorado y amado con afecto reconociente en todos los sagrarios del mundo hasta el fin de los tiempos. Amén.',
    'Night Prayer':
        'Visita, Te lo pedimos, Señor, esta casa, y aleja de ella todas las asechanzas del enemigo. Que tus Santos Ángeles habiten en ella para conservarnos en paz, y tu bendición permanezca siempre sobre nosotros. Por Jesucristo nuestro Señor. Amén.',
    'Prayer of Consecration of the Day':
        'Oh Señor Dios, Rey del cielo y de la tierra, dignate hoy ordenar y santificar, regir y gobernar nuestros corazones y cuerpos, nuestros pensamientos, palabras y obras, conforme a tu ley y al cumplimiento de tus mandamientos, para que, ayudados por Ti, seamos dignos de ser salvos y librados, oh Salvador del mundo, que vives y reinas por los siglos de los siglos. Amén.',
    'Salve Regina':
        'Dios te salve, Reina y Madre de misericordia,\nvida, dulzura y esperanza nuestra: Dios te salve.\nA ti llamamos los desterrados hijos de Eva;\na ti suspiramos, gimiendo y llorando\nen este valle de lágrimas.\nEa, pues, Señora, abogada nuestra,\nvuelve a nosotros esos tus ojos misericordiosos;\ny después de este destierro muéstranos a Jesús,\nfruto bendito de tu vientre.\n¡Oh clemente, oh piadosa, oh dulce Virgen María!\n\nRuega por nosotros, Santa Madre de Dios,\npara que seamos dignos de alcanzar las promesas de Cristo. Amén.',
    'Memorare':
        'Acordaos, oh dulcísima Virgen María, que jamás se ha oído decir que ninguno de los que han acudido a vuestra protección, implorando vuestro auxilio y reclamando vuestra intercesión, haya sido abandonado de Vos. Animado de esta confianza, a Vos también acudo, oh Virgen, Madre de Vírgenes; y aunque gimiendo bajo el peso de mis pecados me atrevo a presentarme ante tu majestad, oh Madre del Verbo encarnado, no desdeñéis mis súplicas, antes bien, escuchadlas benignamente y ved de acogerlas. Amén.',
    'Sub Tuum Praesidium':
        'Bajo vuestra protección nos acogemos, Santa Madre de Dios;\nno despreciéis las súplicas que, en nuestras necesidades, os dirigimos;\nantes bien, de todo peligro, oh siempre Virgen gloriosa y bendita, libradnos. Amén.',
    'Ave Maris Stella':
        'Salve, Estrella del mar, Santa Madre de Dios, siempre Virgen, feliz puerta del cielo.\n\nRecibe aquel Ave que de labios de Gabriel salió, y funda nos en la paz, mudando el nombre de Eva.\n\nDesata los lazos de los reos, alumbra a los ciegos, ahuyenta nuestros males, pide todos los bienes.\n\nMuéstrate Madre, y haz que por ti las súplicas alcance Aquel que, naciendo por nosotros, quiso ser tu Hijo.\n\nVirgen singular entre todas, mansa entre todas, haznos exentos de culpa, mansos y castos.\n\nConcédenos una vida pura, prepara el camino seguro, para que, viendo a Jesús, nos gociemos siempre.\n\nSea la alabanza a Dios Padre, la gloria a Cristo muy alto, y el honor al Espíritu Santo, los tres un solo Dios. Amén.',
    'De Profundis (Psalm 130)':
      'Desde lo hondo a Ti grito, oh Señor:\nSeñor, escucha mi voz;\nestén atentos tus oídos\na la voz de mi súplica.\nSi guardas memoria de las iniquidades, Señor,\n¿quién podrá sostenerse?\nPero en Ti se encuentra el perdón,\nporque así te servimos con temor.\nEspera mi alma en el Señor,\nconfía su palabra mi alma.\nEspera el Señor más que los centinelas el alba,\nespera Israel en el Señor.\nPorque con el Señor se encuentra la misericordia,\ny copiosa redención con Él.\nY Él redimirá a Israel\nde todas sus iniquidades.\n\nGloria al Padre, y al Hijo, y al Espíritu Santo.\nComo era en el principio, ahora y siempre,\ny por los siglos de los siglos. Amén.',
    'Eternal Rest':
        'Conédenles, Señor,\nel descanso eterno,\ny brille para ellos la luz perpetua.\nDescansen en paz. Amén.\n\nY las almas de los fieles difuntos,\npor la misericordia de Dios,\ndescansen en paz. Amén.',
    'Prayer for the Dead':
        'Oh Dios, Creador y Redentor de todos los fieles, concede a las almas de tus siervos y siervas la remisión de todos sus pecados, para que, por piadosas súplicas, obtengan el perdón que siempre deseaban. Por Jesucristo nuestro Señor. Amén.',
    'Act of Faith':
        'Dios mío, creo firmemente que Tú eres un solo Dios en tres Personas divinas: Padre, Hijo y Espíritu Santo; creo que tu Hijo divino se hizo hombre por nuestros pecados y murió por nosotros, y que ha de venir a juzgar a los vivos y a los muertos. Creo éstas y todas las verdades que enseña la Santa Iglesia Católica, porque Tú las has revelado, Tú que no puedes engañar ni ser engañado. Amén.',
    'Act of Hope':
        'Dios mío, esperando en tu omnipotencia e infinita bondad, y confiando en tus promesas, espero alcanzar el perdón de mis pecados, el auxilio de tu gracia y la vida eterna, por los méritos de Jesucristo, mi Señor y Redentor. Amén.',
    'Act of Charity':
        'Dios mío, porque eres todo bondad y digno de ser amado sobre todas las cosas, te amo con todo mi corazón y con toda mi alma; y por amor a Ti amo a mi prójimo como a mí mismo, y te perdono de corazón a todos los que me ofendieron, y pido perdón a todos aquellos a quienes ofendí. Amén.',
    'Prayer to St. Michael the Archangel':
        'San Miguel Arcángel, defiéndenos en la batalla; sé nuestro amparo contra la maldad y las asechanzas del demonio. Que Dios le reprenda, es nuestra humilde súplica; y tú, Príncipe de la milicia celestial, arroja al infierno con el poder divino a Satanás y a todos los espíritus malignos que andan por el mundo para la perdición de las almas. Amén.',
    'Prayer before a Crucifix':
        'He aquí, oh Jesús bueno y dulcísimo, me postro ante tu presencia, y con el más ferviente anhelo de mi alma te ruego y suplico imprimas en mi corazón vivos sentimientos de fe, esperanza y caridad, verdadero arrepentimiento de mis pecados y firme propósito de enmendarme, mientras que con profundo cariño y dolor de alma contemplo mentalmente tus cinco llagas más preciosa, teniendo ante mis ojos aquellas palabras que David, tu profeta, puso en tu boca acerca de Ti: "Atravesaron mis manos y mis pies; he contado todos mis huesos."',

  /// Display names in Spanish (lookup keys stay English).
  static const Map<String, String> titlesEs = const {
    'Divine Mercy Chaplet': 'Coronilla de la Divina Misericordia',
    'The Angelus': 'El Ángelus',
    'Regina Caeli (Easter Angelus)': 'Regina Caeli (Ángelus Pascual)',
    'Morning Offering': 'Ofrecimiento de la Mañana',
    'Act of Contrition': 'Acto de Contrición',
    'Anima Christi': 'Anima Christi',
    'Prayer before Mass': 'Oración antes de la Misa',
    'Prayer before Communion': 'Oración antes de Comulgar',
    'Prayer after Communion': 'Oración después de Comulgar',
    'Anima Christi (after Communion)': 'Anima Christi (después de Comulgar)',
    'Prayer of St. Thomas Aquinas before Communion': 'Oración de San Tomás de Aquino antes de Comulgar',
    'Prayer of St. Thomas Aquinas after Communion': 'Oración de San Tomás de Aquino después de Comulgar',
    'Prayer after Mass (Thanksgiving)': 'Oración después de la Misa (Acción de Gracias)',
    'Night Prayer': 'Oración de la Noche',
    'Morning Prayer (Prime)': 'Oración de la Mañana (Prima)',
    'Prayer of Consecration of the Day': 'Consagración del Día',
    'Evening Prayer (Compline)': 'Oración de la Noche (Completas)',
    'Short Morning Prayer': 'Oración Breve de la Mañana',
    'Short Evening Prayer': 'Oración Breve de la Noche',
    'Salve Regina': 'Salve Regina',
    'Memorare': 'Memorare',
    'Sub Tuum Praesidium': 'Sub Tuum Praesidium',
    'Ave Maris Stella': 'Ave Maris Stella',
    'Litany of Loreto': 'Letanía de Loreto',
    'Litany of the Saints': 'Letanía de los Santos',
    'Litany of the Sacred Heart': 'Letanía al Sagrado Corazón de Jesús',
    'De Profundis (Psalm 130)': 'De Profundis (Salmo 130)',
    'Eternal Rest': 'Descanso Eterno',
    'Prayer for the Dead': 'Oración por los Difuntos',
    'Act of Faith': 'Acto de Fe',
    'Act of Hope': 'Acto de Esperanza',
    'Act of Charity': 'Acto de Caridad',
    'Prayer to St. Michael the Archangel': 'Oración a San Miguel Arcángel',
    'Prayer before a Crucifix': 'Oración ante un Crucifijo',
  };

  /// Category display names in Spanish.
  static const Map<String, String> catEs = const {
    'Daily Prayers': 'Oraciones Diarias',
    'Morning & Evening Prayer': 'Oración Matutina y Vespertina',
    'Marian Prayers': 'Oraciones Marianas',
    'Litanies': 'Letanías',
    'Prayers for the Dead': 'Oraciones por los Difuntos',
    'Devotions': 'Devociones',
  };

  };
}
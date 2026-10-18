/// Trilingual prayer texts: Latin + Spanish lookups by prayer title.
/// Prayers missing from a map fall back gracefully (the detail screen simply
/// doesn't offer that language). The Latin texts follow traditional liturgical
/// usage; Spanish follows the standard devotional forms.
class PrayerTranslations {
  static const Map<String, String> latin = {
    'The Lord\'s Prayer':
        'Pater noster, qui es in cælis, sanctificetur nomen Tuum; adveniat regnum Tuum; fiat voluntas Tua, sicut in cælo et in terra. Panem nostrum quotidianum da nobis hodie; et dimitte nobis debita nostra, sicut et nos dimittimus debitoribus nostris; et ne nos inducas in tentationem; sed libera nos a malo. Amen.',
    'Hail Mary':
        'Ave Maria, gratia plena, Dominus tecum; benedicta Tu in mulieribus, et benedictus fructus ventris Tui, Iesus. Sancta Maria, Mater Dei, ora pro nobis peccatoribus, nunc et in hora mortis nostræ. Amen.',
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
        'Omnipotens sempiterne Deus, ecce accedo ad Sacramentum unigeniti Filii tui, Domini nostri Iesu Christi: ego ægrotus venio ad Medicam vitae; immundus ad Fontem misericordiæ; cæcus ad Lucem æternæ claritatis; pauper et egenus ad Dominum cæli et terræ. Deprecor igitur immensam largitatem tuæ divitiae, ut sanes et mundes me, omnes maculas vitiorum eveillas, atque omnia in me secundum præcepta tua disponas, ut, Te adiuvante, hic et in futurum digne servari merear, o Salvator mundi, qui vivis et regnas in sæcula sæculorum. Amen.',
    'Prayer before Communion':
        'Domine, non sum dignus ut intres sub tectum meum: sed tantum dic verbo, et sanabitur anima mea. Te, Domine, indignum confiteor ad recipientum Corpus tuum sacrum et Sanguinem pretiosum. Credo firmiter, et confiteor, Te esse Christum, Filium Dei vivi, qui in mundum venisti ut salvares peccatores, quorum primus ego sum. Quare, Domine, obsecro, ut gratia tua, quæ infinita est, suppleat quæ in me desunt, ut digne accedam ad hoc sanctissimum Sacramentum. Amen.',
    'Prayer after Communion':
        'Gratias tibi ago, Domine, Pater sancte, omnipotens, æterne Deus, qui me peccatorem, indignum famulum tuum, ex mera et larga benignitate tua dignatus es pascere Corpore pretioso et Sanguine Filii tui, Domini nostri Iesu Christi. Sit hæc sancta Communio mihi non in condemnationem, sed in defensionem et tutamen, pignusque futuræ gloriæ. Auge fidem meam, conforta charitatem, et confirmes gratiam tuam in me. Amen.',
    'Anima Christi (after Communion)':
        'Anima Christi, sanctifica me.\nCorpus Christi, salva me.\nSanguis Christi, inebria me.\nAqua lateris Christi, lava me.\nPassio Christi, conforta me.\nO bone Jesu, exaudi me.\nIntra tua vulnera absconde me.\nNe permittas me separari a Te.\nAb hoste maligno defende me.\nIn hora mortis meæ voca me.\nEt iube me venire ad Te,\nut cum Sanctis tuis laudem Te\nin sæcula sæculorum. Amen.',
    'Prayer of St. Thomas Aquinas before Communion':
        'Omnipotens sempiterne Deus, ecce accedo ad Sacramentum unigeniti Filii tui, Domini nostri Iesu Christi, tanquam æger ad Medicam vitae, immundus ad Fontem misericordiæ, cæcus ad Lucem æternæ claritatis, pauper et egenus ad Dominum cæli et terræ. Te, igitur, deprecor, immensæ divitiæ tuæ abundantia, ut emundare et sanare digneris cor meum, sanctificare animam meam, et dignum facere Corpus et Sanguinem Filii tui accipere. Qui vivis et regnas in sæcula sæculorum. Amen.',
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
    'Prayer to St. Michael the Archangel (Long)':
        'Princeps gloriosissime cælestis militiae, sancte Michael Archangele, defende nos in proelio et colluctatione, quae nobis adversus principes et potestates, adversus mundi rectores tenebrarum harum, contra spiritualia nequitiae, in cælestibus. Veni in auxilium hominum, quos Deus creavit inexterminabiles, et ad imaginem similitudinis suae fecit, et a tyrannide diaboli emit pretio magno. Proeliare hodie cum beatorum Angelorum exercitu proelia Domini, sicut pugnasti contra ducem superbiae luciferum, et angelos eius apostaticos: et non valuerunt, neque locus inventus est eorum amplius in cælo. Sed proiectus est draco ille magnus, serpens antiquus, qui vocatur diabolus et satanas, qui seducit universum orbem; et proiectus est in terram, et angeli eius cum illo missi sunt.\n\nEn antiquus inimicus et homicida vehementer erectus est. Transfiguratus in angelum lucis, cum tota malignorum spirituum caterva late circuit et invadit terram, ut in ea deleat nomen Dei et Christi eius, animasque ad æternæ gloriae coronam destinatas furetur, mactet ac perdat in sempiternum interitum. Virus nequitiae suae, tamquam flumen immundissimum, draco maleficus transfundit in homines depravatos mente et corruptos corde; spiritum mendacii, impietatis et blasphemiae; halitumque mortiferum luxuriae, vitiorum omnium et iniquitatum.\n\nEcclesiam, Agni immaculati sponsam, vaferrimi hostes repleverunt amaritudinibus, inebriarunt absinthio; ad omnia desiderabilia eius impias miserunt manus. Ubi sedes beatissimi Petri et Cathedra veritatis ad lucem gentium constituta est, ibi thronum posuerunt abominationis et impietatis suae; ut percusso Pastore, et gregem disperdere valeant.\n\nAdesto itaque, Dux invictissime, populo Dei contra irrumpentes spirituales nequitias, et fac victoriam. Te custodem et patronum sancta veneratur Ecclesia; te gloriatur defensore adversus terrestrium et infernorum nefarias potestates; tibi tradidit Dominus animas redemptorum in superna felicitate locandas. Deprecare Deum pacis, ut conterat satanam sub pedibus nostris, ne ultra valeat captivos tenere homines, et Ecclesiae nocere. Offer nostras preces in conspectu Altissimi, ut cito anticipent nos misericordiae Domini, et apprehendas draconem, serpentem antiquum, qui est diabolus et satanas, ac ligatum mittas in abyssum, ut non seducat amplius gentes. Hinc tuo confisi præsidio ac tutela, sacra sanctae Matris Ecclesiae auctoritate, ad infestationes diabolicae fraudis repellendas in nomine Iesu Christi Dei et Domini nostri fidentes et securi aggredimur.\n\nV. Ecce Crucem Domini, fugite partes adversae.\nR. Vicit Leo de tribu Iuda, radix David.\nV. Fiat misericordia tua, Domine, super nos.\nR. Quemadmodum speravimus in te.\nV. Domine, exaudi orationem meam.\nR. Et clamor meus ad te veniat.\n\nOremus. Deus, et Pater Domini nostri Iesu Christi, invocamus nomen sanctum tuum, et clementiam tuam supplices exposcimus ut, per intercessionem immaculatae semper Virginis Dei Genetricis Mariae, beati Michaelis Archangeli, beati Ioseph eiusdem beatae Virginis Sponsi, beatorum Apostolorum Petri et Pauli et omnium Sanctorum, adversus satanam, omnesque alios immundos spiritus, qui ad nocendum humano generi animasque perdendas pervagantur in mundo, nobis auxilium præstare digneris. Per eundem Christum Dominum nostrum. Amen.',
    'Prayer before a Crucifix':
        'En ego, o bone et dulcissime Iesu,\ncoram te procumbo,\nac summo animi desiderio\nte deprecor ac obsecro,\nut in corde meo vitales sensus\nfidei, spei et caritatis imprimas,\nveram peccatorum meorum poenitentiam\ncum firmo proposito emendandi,\n dum mecum intus contemplor\nac mente considero\nquinque vulnera tua pretiosissima,\neo affectu quo David prophetus dicebat:\n"Foderunt manus meas et pedes meos;\nnumeravi omnia ossa mea."',
    'Apostles\' Creed':
        'Credo in Deum Patrem omnipotentem, Creatorem cæli et terrae. Et in Iesum Christum, Filium eius unicum, Dominum nostrum: qui conceptus est de Spiritu Sancto, natus ex Maria Virgine, passus sub Pontio Pilato, crucifixus, mortuus, et sepultus. Descendit ad inferos; tertia die resurrexit a mortuis. Ascendit ad cælos; sedet ad dexteram Dei Patris omnipotentis. Inde venturus est iudicare vivos et mortuos. Credo in Spiritum Sanctum, sanctam Ecclesiam catholicam, Sanctorum communionem, remissionem peccatorum, carnis resurrectionem, vitam æternam. Amen.',
    'Nicene Creed':
        'Credo in unum Deum, Patrem omnipotentem, factorem cæli et terrae, visibilium omnium et invisibilium.\n\nEt in unum Dominum Iesum Christum, Filium Dei unigenitum, et ex Patre natum ante omnia saecula. Deum de Deo, Lumen de Lumine, Deum verum de Deo vero, genitum non factum, consubstantialem Patri; per quem omnia facta sunt. Qui propter nos homines et propter nostram salutem descendit de cælis. Et incarnatus est de Spiritu Sancto ex Maria Virgine, et homo factus est. Crucifixus etiam pro nobis sub Pontio Pilato, passus et sepultus est, et resurrexit tertia die, secundum Scripturas, et ascendit in cælum, sedet ad dexteram Patris. Et iterum venturus est cum gloria iudicare vivos et mortuos, cuius regni non erit finis.\n\nEt in Spiritum Sanctum, Dominum et vivificantem, qui ex Patre Filioque procedit. Qui cum Patre et Filio simul adoratur et conglorificatur; qui locutus est per prophetas. Et unam, sanctam, catholicam et apostolicam Ecclesiam. Confiteor unum baptisma in remissionem peccatorum. Et expecto resurrectionem mortuorum, et vitam venturi saeculi. Amen.',
    'Athanasian Creed':
        'Quicumque vult salvus esse, ante omnia opus est, ut teneat catholicam fidem:\nQuam nisi quisque integre immaculatque servaverit, absque dubio in æternum peribit.\nFides autem catholica haec est: ut unum Deum in Trinitate, et Trinitatem in unitate veneremur.\nNeque confundentes personas, neque substantiam separantes.\nAlia est enim persona Patris, alia Filii, alia Spiritus Sancti:\nSed Patris, et Filii, et Spiritus Sancti una est divinitas, aequalis gloria, coæterna maiestas.\nQualis Pater, talis Filius, talis Spiritus Sanctus.\nInfinitus Pater, infinitus Filius, infinitus Spiritus Sanctus.\nÆternus Pater, æternus Filius, æternus Spiritus Sanctus.\nEt tamen non tres æterni, sed unus æternus.\nSicut non tres infiniti, nec tres infiniti, sed unus infinitus.\nIta Pater omnipotens, Filius omnipotens, Spiritus Sanctus omnipotens.\nEt tamen non tres omnipotentes, sed unus omnipotens.\nIta Deus Pater, Deus Filius, Deus Spiritus Sanctus.\nEt tamen non tres dii, sed unus est Deus.\nIta Dominus Pater, Dominus Filius, Dominus Spiritus Sanctus.\nEt tamen non tres Domini, sed unus est Dominus.\nQuia, sicut singulatim unamquamque personam Deum ac Dominum confiteri Christiana veritate compellimur:\nIta tres Deos aut tres Dominos dicere catholica religione prohibemur.\nPater a nullo est factus: nec creatus, nec genitus.\nFilius a Patre solo est: non factus, nec creatus, sed genitus.\nSpiritus Sanctus a Patre et Filio: non factus, nec creatus, nec genitus, sed procedens.\nUnus ergo Pater, non tres Patres: unus Filius, non tres Filii: unus Spiritus Sanctus, non tres Spiritus Sancti.\nEt in hac Trinitate nihil prius aut posterius, nihil maius aut minus:\nSed totae tres personae coæternæ sibi sunt et coaequales.\nIta ut per omnia, ut iam dictum est, et unitas in Trinitate, et Trinitas in unitate veneranda sit.\nQui vult ergo salvus esse, de Trinitate ita sentiat.\nSed necessarium est ad æternam salutem, ut incarnationem quoque Domini nostri Iesu Christi fideliter credat.\nEst ergo fides recta ut credamus et confiteamur, quia Dominus noster Iesus Christus, Dei Filius, Deus pariter et homo est.\nDeus est ex substantia Patris ante saecula genitus: et homo est ex substantia matris in saeculo natus.\nPerfectus Deus, perfectus homo: ex anima rationali et humana carne subsistens.\nAequalis Patri secundum divinitatem: minor Patri secundum humanitatem.\nQui licet Deus sit et homo, non duo tamen, sed unus est Christus.\nUnus autem non conversione divinitatis in carnem, sed assumptione humanitatis in Deum.\nUnus omnino, non confusione substantiae, sed unitate personae.\nNam sicut anima rationalis et caro unus est homo: ita Deus et homo unus est Christus.\nQui passus est pro salute nostra: descendit ad inferos: tertia die resurrexit a mortuis.\nAscendit ad cælos: sedet ad dexteram Dei Patris omnipotentis: inde venturus est iudicare vivos et mortuos.\nAd cuius adventum omnes homines resurgere habent cum corporibus suis: et propriis meritis seu operibus suis reddituri sunt rationem.\nEt qui bene egerunt, ibunt in vitam æternam: qui vero mala, in ignem æternum.\nHaec est fides catholica, quam nisi quisque fideliter firmiterque crediderit, salvus esse non poterit.',
    'Litany of the Most Holy Name of Jesus':
        'Domine, miserere nobis.\nChriste, miserere nobis.\nDomine, miserere nobis.\nJesu, exaudi nos.\nJesu, clementer exaudi nos.\n\nDeus Pater caelestis, miserere nobis.\nDeus Filius, Redemptor mundi, miserere nobis.\nDeus Spiritus Sanctus, miserere nobis.\nSancta Trinitas, unus Deus, miserere nobis.\n\nJesu, Fili Dei vivi, miserere nobis.\nJesu, Splendor Patris, miserere nobis.\nJesu, Candor luminis aeterni, miserere nobis.\nJesu, Rex gloriae, miserere nobis.\nJesu, Sol iustitiae, miserere nobis.\nJesu, Fili Virginis Mariae, miserere nobis.\nJesu, amabilissime, miserere nobis.\nJesu, admirabilissime, miserere nobis.\nJesu, Deus fortis, miserere nobis.\nJesu, Pater saeculi futuri, miserere nobis.\nJesu, Angelus magni consilii, miserere nobis.\nJesu, potentissime, miserere nobis.\nJesu, patientissime, miserere nobis.\nJesu, obedientissime, miserere nobis.\nJesu, mitis et humilis corde, miserere nobis.\nJesu, amator castitatis, miserere nobis.\nJesu, amator animarum nostrarum, miserere nobis.\nJesu, Deus pacis, miserere nobis.\nJesu, auctor vitae, miserere nobis.\nJesu, exemplum virtutum, miserere nobis.\nJesu, zelator animarum, miserere nobis.\nJesu, Deus ultionis, miserere nobis.\nJesu, Pater pauperum, miserere nobis.\nJesu, thesaurus fidelium, miserere nobis.\nJesu, Pastor bone, miserere nobis.\nJesu, lux vera, miserere nobis.\nJesu, sapientia sancta, miserere nobis.\nJesu, dulcedo cordium, miserere nobis.\nJesu, spes nostra, miserere nobis.\nJesu, salus nostra, miserere nobis.\n\nAgnus Dei, qui tollis peccata mundi, parce nobis, Jesu.\nAgnus Dei, qui tollis peccata mundi, exaudi nos, Jesu.\nAgnus Dei, qui tollis peccata mundi, miserere nobis, Jesu.\n\nJesu, exaudi nos.\nJesu, clementer exaudi nos.\n\nOremus.\nDomine Jesu Christe, qui dixisti: Petite, et accipietis; quaerite, et invenietis; pulsate, et aperietur vobis: quaesumus, nobis tribue donum tuae caritatis, ut te totis cordibus, verbis et operibus amplectamur, et a laude tua numquam valeamus cessare. Da nobis, Domine, timorem et amorem sancti Nominis tui continua devotione servire; quia numquam desinis eos gubernare, quos soliditate tuae caritatis instruis. Qui vivis et regnas in saecula saeculorum. Amen.',
    'Litany of St. Joseph':
        'Domine, miserere nobis.\nChriste, miserere nobis.\nDomine, miserere nobis.\nChriste, exaudi nos.\nChriste, clementer exaudi nos.\n\nDeus Pater caelestis, miserere nobis.\nDeus Filius, Redemptor mundi, miserere nobis.\nDeus Spiritus Sanctus, miserere nobis.\nSancta Trinitas, unus Deus, miserere nobis.\n\nSancta Maria, ora pro nobis.\nSancte Ioseph, ora pro nobis.\nProles David inclyta, ora pro nobis.\nLumen Patriarcharum, ora pro nobis.\nSponse Dei Genetricis, ora pro nobis.\nCustode castissime Virginis, ora pro nobis.\nNutritore Filii Dei, ora pro nobis.\nDefensore sollicito Christi, ora pro nobis.\nCapite sanctae Familiae, ora pro nobis.\nIoseph iustissime, ora pro nobis.\nIoseph castissime, ora pro nobis.\nIoseph prudentissime, ora pro nobis.\nIoseph fortissime, ora pro nobis.\nIoseph obedientissime, ora pro nobis.\nIoseph fidelissime, ora pro nobis.\nSpeculum patientiae, ora pro nobis.\nAmator paupertatis, ora pro nobis.\nExemplar opificum, ora pro nobis.\nDecus domesticum vitae, ora pro nobis.\nCustode virginum, ora pro nobis.\nColumna familiarum, ora pro nobis.\nSolatium afflictarum, ora pro nobis.\nSpes aegrotantium, ora pro nobis.\nPatrone morientium, ora pro nobis.\nTerror daemonum, ora pro nobis.\nCustode sanctae Ecclesiae, ora pro nobis.\n\nAgnus Dei, qui tollis peccata mundi, parce nobis, Domine.\nAgnus Dei, qui tollis peccata mundi, exaudi nos, Domine.\nAgnus Dei, qui tollis peccata mundi, miserere nobis, Domine.\n\nConstituit eum dominum domus suae.\nEt principem omnis possessionis suae.\n\nOremus.\nDeus, qui ineffabili providentia beatum Ioseph sanctissimae Genetricis tuae Sponsum eligere dignatus es: praesta, quaesumus; ut quem veneramur protectorem in terris, habeamus intercessorem in caelis. Qui vivis et regnas in saecula saeculorum. Amen.',
    'Novena to Our Lady of La Leche':
        'Beata Maria Virgo de Lacte (Nuestra Señora de la Leche y Buen Parto) colitur in Sacrario Missionis Nomen Dei apud Sanctum Augustinum in Florida, antiquissimo Marianorum sacrario in Civitatibus Foederatis Americae. Festum eius die 11 octobris celebratur.\n\nConsuetudo est ut novena per novem dies continuos recitetur. Recitari etiam potest die hebdomadae determinata per novem hebdomadas continuas (verbi gratia, die sabbati), aut die mensis determinato per novem menses continuos (verbi gratia, primis sabbatis). In Dioecesi Sancti Augustini, novena recitari potest in praeparatione Festi Beatae Mariae Virginis de Lacte, incipiente die 3 octobris ut concludatur die 11 octobris.\n\nORATIO NOVENAE (PRIMA FORMA)\n\nDulcis Domina de Lacte, amantissima Mater Iesu, et mater mea, exaudi humilem precem meam. Cor tuum maternum novit omnem votum meum, omnem necessitatem meam. Tibi soli, Virgini immaculatae Matri eius, Filius tuus divinus dedit intellegere sensus qui animam meam implent. Tua fuit sacra dignitas esse Matrem Salvatoris.\n\nIntercede nunc apud eum, mater mea amantissima, ut fiat secundum voluntatem eius (hic mentio fiat petitionis tuae). Hoc peto, o Domina de Lacte, in nomine Filii tui divini, Domini et Salvatoris mei. Amen.\n\nV. O Maria, sine labe concepta.\nR. Ora pro nobis qui ad te confugimus.\nDomina de Lacte, ora pro nobis.\n\nORATIO NOVENAE (ALTERA FORMA)\n\nDulcis Domina de Lacte, amantissima Mater Salvatoris nostri Iesu Christi, et mater mea, quaeso, exaudi humilem precem meam. Cor tuum novit omnem votum meum, omnem necessitatem meam. Confido, cara Mater, quia me sub pallio tuo protectivo suscipies, sicut Filium tuum suscepisti.\n\nIntercede apud eum, quaeso, ut habeam fortitudinem et virtutem ad superandas quascumque difficultates quae me circumdant. Da mihi gratiam ut tibi semper fidelis sim, et tu mihi sis inspiratio lucida nunc et in perpetuum.\n\nSi secundum divinam voluntatem sit, quaeso impetra mihi per intercessionem tuam hanc gratiam (hic mentio fiat petitionis tuae).\n\nV. O Maria, sine labe concepta.\nR. Ora pro nobis qui ad te confugimus.\nDomina de Lacte, ora pro nobis.',
    'Litany of Our Lady of La Leche':
        'Domine, miserere nobis.\nDomine, miserere nobis.\nChriste, miserere nobis.\nChriste, miserere nobis.\nDomine, miserere nobis.\nDomine, miserere nobis.\n\nDeus, Pater noster in caelis, miserere nobis.\nDeus Filius, Redemptor mundi, miserere nobis.\nDeus Spiritus Sanctus, miserere nobis.\nSancta Trinitas, unus Deus, miserere nobis.\n\nSancta Maria, ora pro nobis.\nCastissima Filia Patris, ora pro nobis.\nCastissima Sponsa Spiritus Sancti, ora pro nobis.\nCastissima Mater Filii Dei, ora pro nobis.\nVas electionis, ora pro nobis.\nThronus divinae Maiestatis, ora pro nobis.\nTabernaculum Verbi Divini, ora pro nobis.\nCalix Divinae Vitae, ora pro nobis.\nSancta Mater Dei, ora pro nobis.\nSancta Mater infantis Christi, ora pro nobis.\nConsecratio femininitatis, ora pro nobis.\nSpes femininitatis christianae, ora pro nobis.\nExemplar omnium matrum christianarum, ora pro nobis.\nBenedicta in maternitate tua, ora pro nobis.\nInspiratio sanctae maternitatis, ora pro nobis.\nConsolatio maternitatis, ora pro nobis.\nProtectrix maternitatis, ora pro nobis.\nBenedictio omnis maternitatis christianae, ora pro nobis.\nExaltatio maternitatis, ora pro nobis.\nSanctificatio maternitatis, ora pro nobis.\nRegina sanctissimae Familiae, ora pro nobis.\nRegina castae vitae familiaris, ora pro nobis.\nRegina matrum, ora pro nobis.\nMater matrum, ora pro nobis.\nMater partus felicis, ora pro nobis.\n\nAgnus Dei, qui tollis peccata mundi, miserere nobis.\nAgnus Dei, qui tollis peccata mundi, miserere nobis.\nAgnus Dei, qui tollis peccata mundi, miserere nobis.\n\nV. Domina de Lacte.\nR. Ora pro nobis qui ad te confugimus.\n\nOremus.\n\nVirgo dilecta, Regina caelorum, electa ante omnes mulieres ut esses mater Filii Dei, Maria, mater mea, quae in maternitate tua sanctificavisti statum sanctae maternitatis, ad te veniam implorans; humiliter te deprecor; confidenter in te confido. Scio quod, per intercessionem tuam potenter, me in necessitate mea iuvare potes. In te confugio, Virgo cara. Pauper et egens, ad te pie convertor et omnes spes meas confidenter in manibus tuis pono. Accipe humilem fiduciam meam, exaudi preces meas, et veni in auxilium meum, cara Mater matrum. Amen.\n\nV. Ecce ancilla Domini.\nR. Fiat mihi secundum verbum tuum.',
  };

  static const Map<String, String> spanish = {
    'The Lord\'s Prayer':
        'Padre nuestro, que estás en el cielo, santificado sea tu Nombre; venga a nosotros tu Reino; hágase tu voluntad, en la tierra como en el cielo. Danos hoy nuestro pan de cada día; perdona nuestras ofensas, como también nosotros perdonamos a los que nos ofenden; no nos dejes caer en la tentación y líbranos del mal. Amén.',
    'Hail Mary':
        'Dios te salve María, llena eres de gracia, el Señor es contigo; bendita tú eres entre todas las mujeres, y bendito es el fruto de tu vientre, Jesús. Santa María, Madre de Dios, ruega por nosotros los pecadores, ahora y en la hora de nuestra muerte. Amén.',
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
    'Prayer to St. Michael the Archangel (Long)':
        'Gloriosísimo príncipe de la milicia celestial, Arcángel San Miguel, defiéndenos en la lucha que mantenemos combatiendo contra los principados y potestades, contra los caudillos de este mundo tenebroso, contra los espíritus malignos esparcidos por los aires. Ven en auxilio de los hombres que Dios creó incorruptibles a su imagen y semejanza, y a tan alto precio rescatados de la tiranía del demonio. Con las huestes de los ángeles buenos pelea hoy los combates del Señor, como antaño luchaste contra Lucifer, corifeo de la soberbia, y contra sus ángeles apóstatas. Ellos no pudieron vencer, y perdieron su lugar en el Cielo. Fue precipitado el gran dragón, la antigua serpiente, el denominado diablo y Satanás, el seductor del universo: fue precipitado a la tierra y con él fueron arrojados sus ángeles.\n\nHe aquí que el antiguo enemigo y homicida se ha erguido con vehemencia. Disfrazado de ángel de luz, con la escolta de todos los espíritus malignos rodea e invade la tierra entera, y se instala en todo lugar, con el designio de borrar allí el nombre de Dios y de su Cristo, de arrebatar las almas destinadas a la corona de la gloria eterna, de destruirlas y perderlas para siempre. Como el más inmundo torrente, el maligno dragón derramó sobre los hombres de mente depravada y corrompido corazón, el veneno de su maldad: el espíritu de la mentira, de la impiedad y de la blasfemia; el letal soplo de la lujuria, de todos los vicios e iniquidades.\n\nLos más taimados enemigos han llenado de amargura a la Iglesia, esposa del Cordero Inmaculado, le han dado a beber ajenjo, han puesto sus manos impías sobre todo lo que para Ella es más querido. Donde fueron establecidas la Sede de San Pedro y la Cátedra de la Verdad como luz para las naciones, ellos han erigido el trono de la abominación de la impiedad, de suerte que, golpeado el Pastor, pueda dispersarse la grey. Oh invencible adalid, ayuda al pueblo de Dios contra la perversidad de los espíritus que le atacan y dale la victoria.\n\nLa Iglesia te venera como su guardián y patrono, se gloría que eres su defensor contra los poderes nocivos terrenales e infernales; Dios te confió las almas de los redimidos para colocarlos en el estado de la suprema felicidad. Ruega al Dios de la paz que aplaste al demonio bajo nuestros pies, para que ya no pueda retener cautivos a los hombres y dañar a tu Iglesia. Ofrece nuestras oraciones al Altísimo, para que cuanto antes desciendan sobre nosotros las misericordias del Señor, y sujeta al dragón, la antigua serpiente, que es el diablo y Satanás, y, una vez encadenado, precipítalo en el abismo, para que nunca jamás pueda seducir a las naciones. Después de esto, confiados en tu protección y patrocinio, con la sagrada autoridad de la Santa Madre Iglesia, nos disponemos a rechazar la peste de los fraudes diabólicos, confiados y seguros en el Nombre de Jesucristo, nuestro Dios y Señor.\n\nV. He aquí la Cruz del Señor, huid poderes enemigos.\nR. Ha vencido el León de la tribu de Judá, la raíz de David.\nV. Señor, que tu misericordia venga sobre nosotros.\nR. Como lo esperamos de Ti.\nV. Señor, escucha nuestra oración.\nR. Y llegue a Ti nuestro clamor.\n\nOremos. Dios y Padre de Nuestro Señor Jesucristo, invocamos tu santo Nombre y suplicantes imploramos tu clemencia, para que, por la intercesión de la Inmaculada siempre Virgen María Madre de Dios, del Arcángel San Miguel, de San José Esposo de la Santísima Virgen, de los santos Apóstoles Pedro y Pablo y de todos los Santos, te dignes prestarnos tu auxilio contra Satanás y todos los demás espíritus inmundos que vagan por el mundo para dañar al género humano y para la perdición de las almas. Amén.',
    'Prayer before a Crucifix':
        'He aquí, oh Jesús bueno y dulcísimo, me postro ante tu presencia, y con el más ferviente anhelo de mi alma te ruego y suplico imprimas en mi corazón vivos sentimientos de fe, esperanza y caridad, verdadero arrepentimiento de mis pecados y firme propósito de enmendarme, mientras que con profundo cariño y dolor de alma contemplo mentalmente tus cinco llagas más preciosa, teniendo ante mis ojos aquellas palabras que David, tu profeta, puso en tu boca acerca de Ti: "Atravesaron mis manos y mis pies; he contado todos mis huesos."',
    'Short Morning Prayer':
        '''En el nombre del Padre, y del Hijo, y del Espíritu Santo. Amén.

VEN, ESPÍRITU SANTO
Ven, Espíritu Santo, llena el corazón de tus fieles, y enciende en ellos el fuego de tu amor.

V. Envía tu Espíritu, y serán creados.
R. Y renovarás la faz de la tierra.

OREMOS
Oh Dios, que por la luz del Espíritu Santo instruíste los corazones de los fieles, concédenos que, por ese mismo Espíritu, seamos siempre sabios, y gocemos de sus consolaciones. Por Cristo nuestro Señor. Amén.


PADRE NUESTRO
Padre nuestro, que estás en el cielo; santificado sea tu Nombre; venga a nosotros tu Reino; hágase tu voluntad, en la tierra como en el cielo. Danos hoy nuestro pan de cada día; perdona nuestras ofensas, como también nosotros perdonamos a los que nos ofenden; no nos dejes caer en la tentación, y líbranos del mal. Amén.

DIOS TE SALVE MARÍA
Dios te salve María, llena eres de gracia, el Señor es contigo; bendita tú eres entre todas las mujeres, y bendito es el fruto de tu vientre, Jesús. Santa María, Madre de Dios, ruega por nosotros, los pecadores, ahora y en la hora de nuestra muerte. Amén.

CREO EN DIOS
Creo en Dios, Padre todopoderoso, Creador del cielo y de la tierra. Creo en Jesucristo, su único Hijo, nuestro Señor, que fue concebido por obra y gracia del Espíritu Santo, nació de Santa María Virgen, padeció bajo el poder de Poncio Pilato, fue crucificado, muerto y sepultado, descendió a los infiernos, al tercer día resucitó de entre los muertos, subió a los cielos y está sentado a la derecha de Dios, Padre todopoderoso. Desde allí ha de venir a juzgar a los vivos y a los muertos. Creo en el Espíritu Santo, la santa Iglesia católica, la comunión de los santos, el perdón de los pecados, la resurrección de la carne y la vida eterna. Amén.


CONSAGRACIÓN DEL DÍA
Oh Señor Dios, Rey del cielo y de la tierra, que este día te dignes en ordenar y santificar, regir y gobernar nuestros corazones y cuerpos, nuestros pensamientos, palabras y obras, conforme a tu ley y al cumplimiento de tus mandamientos, para que, ayudados por Ti, seamos dignos de ser salvos y librados, oh Salvador del mundo, que vives y reinas por los siglos de los siglos. Amén.


ACTO DE FE
Dios mío, creo firmemente que Tú eres un solo Dios en tres Personas divinas: Padre, Hijo y Espíritu Santo; creo que tu Hijo divino se hizo hombre por nuestros pecados y murió por nosotros, y que ha de venir a juzgar a los vivos y a los muertos. Creo éstas y todas las verdades que enseña la Santa Iglesia Católica, porque Tú las has revelado, que no puedes engañar ni ser engañado.


ACTO DE ESPERANZA
Dios mío, esperando en tu omnipotencia e infinita bondad, y confiando en tus promesas, espero obtener el perdón de mis pecados, el auxilio de tu gracia y la vida eterna, por los méritos de Jesucristo, mi Señor y Redentor.


ACTO DE CARIDAD
Dios mío, porque eres todo bondad y digno de ser amado sobre todas las cosas, te amo con todo mi corazón y con toda mi alma; y por amor a Ti amo a mi prójimo como a mí mismo, y perdono de corazón a todos los que me han ofendido, y suplico perdón a todos los que he ofendido.


ORACIÓN POR LA INTERCESIÓN DE LOS SANTOS
Que la Bienaventurada Virgen María y todos los Santos intercedan por nosotros ante el Señor, para que seamos ayudados y salvados por Él, que vive y reina por los siglos de los siglos. Amén.''',
    'Short Evening Prayer':
        '''En el nombre del Padre, y del Hijo, y del Espíritu Santo. Amén.


EXAMEN DE CONCIENCIA
Oh Dios mío, juez soberano de los hombres, que no quieres la muerte del pecador, sino que se convierta y viva, ilumina mi mente para que conozca los pecados que hoy he cometido en pensamiento, palabra, obra y omisión, y concédeme la gracia de una verdadera contrición.

(Aquí examina tu conciencia.)


ACTO DE CONTRICIÓN
Dios mío, me arrepiento de corazón y me pesa haberte ofendido, porque eres infinitamente bueno y el pecado te desagrada infinitamente. Te pido humildemente misericordia y perdón, por los méritos infinitos de Jesucristo. Resuelvo, con el auxilio de tu gracia, hacer penitencia de mis pecados, y procurar no ofenderte en adelante.

YO CONFIESO
Yo confieso ante Dios Todopoderoso, y ante Santa María, siempre Virgen, ante San Miguel Arcángel, ante San Juan Bautista, a los Santos Apóstoles Pedro y Pablo, y a todos los Santos, que he pecado mucho en pensamiento, palabra y obra: por mi culpa, por mi culpa, por mi gran culpa. Por eso suplico a Santa María siempre Virgen, a San Miguel Arcángel, a San Juan Bautista, a los Santos Apóstoles Pedro y Pablo, y a todos los Santos, que intercedan por mí ante Dios Nuestro Señor.

Que Dios Todopoderoso y Misericordioso nos conceda el perdón, la absolución y la remisión de nuestros pecados. Amén.


PADRE NUESTRO
Padre nuestro, que estás en el cielo; santificado sea tu Nombre; venga a nosotros tu Reino; hágase tu voluntad, en la tierra como en el cielo. Danos hoy nuestro pan de cada día; perdona nuestras ofensas, como también nosotros perdonamos a los que nos ofenden; no nos dejes caer en la tentación, y líbranos del mal. Amén.

DIOS TE SALVE MARÍA
Dios te salve María, llena eres de gracia, el Señor es contigo; bendita tú eres entre todas las mujeres, y bendito es el fruto de tu vientre, Jesús. Santa María, Madre de Dios, ruega por nosotros, los pecadores, ahora y en la hora de nuestra muerte. Amén.

CREO EN DIOS
Creo en Dios, Padre todopoderoso, Creador del cielo y de la tierra. Creo en Jesucristo, su único Hijo, nuestro Señor, que fue concebido por obra y gracia del Espíritu Santo, nació de Santa María Virgen, padeció bajo el poder de Poncio Pilato, fue crucificado, muerto y sepultado, descendió a los infiernos, al tercer día resucitó de entre los muertos, subió a los cielos y está sentado a la derecha de Dios, Padre todopoderoso. Desde allí ha de venir a juzgar a los vivos y a los muertos. Creo en el Espíritu Santo, la santa Iglesia católica, la comunión de los santos, el perdón de los pecados, la resurrección de la carne y la vida eterna. Amén.


ACCIÓN DE GRACIAS
Oh Dios mío, me presento ante Ti al final de otro día, para ofrecerte de nuevo el homenaje de mi corazón. Te adoro humildemente, Creador mío, Redentor y Juez. Creo en Ti, porque eres Verdad misma; espero en Ti, porque eres fiel a tus promesas; te amo con todo mi corazón, porque eres infinitamente digno de ser amado; y por Ti amo a mi prójimo como a mí mismo.

Hazme, oh Dios mío, dar gracias como debo por todas tus inestimables bendiciones y favores. Me has pensado y amado desde toda la eternidad; me has formado de la nada; entregaste a tu Hijo amado a la muerte ignominiosa de la Cruz por mi redención; me has hecho miembro de tu Santa Iglesia; me has preservado de caer en el abismo de la miseria eterna, aunque mis pecados merecían castigo; y con bondad me has tenido paciencia, aunque no he cesado de ofenderte. ¿Qué retorno, oh Dios mío, puedo hacerte por tus incontables bendiciones, y en particular por los favores de este día?


ORACIÓN PARA UNA MUERTE FELIZ
Oh Dios, grande y omnipotente Juez de los vivos y de los muertos, hemos de comparecer ante Ti después de esta breve vida para dar cuenta de nuestras obras. Concédenos que, acompañados de la Bienaventurada Virgen María y de todos los Santos, seamos hallados dignos de entrar en tu eterna alegría. Por Jesucristo, nuestro Señor, que vive y reina contigo en la unidad del Espíritu Santo, un solo Dios, por los siglos de los siglos. Amén.


ORACIÓN POR LA INTERCESIÓN DE LOS SANTOS
Que la Bienaventurada Virgen María y todos los Santos intercedan por nosotros ante el Señor, para que seamos ayudados y salvados por Él, que vive y reina por los siglos de los siglos. Amén.


ORACIÓN POR LOS FIELES DIFUNTOS
Concédeles, Señor, el descanso eterno, y brille para ellos la luz perpetua. Descansen en paz. Amén.''',
    'Litany of the Saints':
        '''Señor, ten piedad de nosotros.
Cristo, ten piedad de nosotros.
Señor, ten piedad de nosotros. Cristo, escúchanos. Cristo, óyenos.

Dios Padre celestial, ten piedad de nosotros.
Dios Hijo, Redentor del mundo, ten piedad de nosotros.
Dios Espíritu Santo, ten piedad de nosotros.
Santísima Trinidad, un solo Dios, ten piedad de nosotros.

Santa María, ruega por nosotros.
Santa Madre de Dios, ruega por nosotros.
Santa Virgen de las vírgenes, ruega por nosotros.
San Miguel, ruega por nosotros.
San Gabriel, ruega por nosotros.
San Rafael, ruega por nosotros.
Todos los Santos Ángeles y Arcángeles, ruega por nosotros.
Todos los coros de los espíritus bienaventurados, ruega por nosotros.

San Juan Bautista, ruega por nosotros.
San José, ruega por nosotros.
Todos los Santos Patriarcas y Profetas, ruega por nosotros.
San Pedro, ruega por nosotros.
San Pablo, ruega por nosotros.
San Andrés, ruega por nosotros.
San Juan, ruega por nosotros.
Todos los Santos Apóstoles y Evangelistas, ruega por nosotros.

San Esteban, ruega por nosotros.
San Lorenzo, ruega por nosotros.
Todos los Santos Mártires, ruega por nosotros.
San Gregorio, ruega por nosotros.
San Agustín, ruega por nosotros.
Todos los Santos Obispos y Confesores, ruega por nosotros.

San Benito, ruega por nosotros.
San Francisco, ruega por nosotros.
Santo Domingo, ruega por nosotros.
Todos los Santos Monjes y Ermitaños, ruega por nosotros.

Santa María Magdalena, ruega por nosotros.
Santa Inés, ruega por nosotros.
Santa Cecilia, ruega por nosotros.
Todas las Santas Vírgenes y Viudas, ruega por nosotros.
Todos los Santos de Dios, ruega por nosotros.

Sed misericordioso, perdónanos, Señor.
Sed misericordioso, escúchanos, Señor.

De todo mal, Señor, líbranos.
De todo pecado, Señor, líbranos.
De tu ira, Señor, líbranos.
De muerte súbita e imprevista, Señor, líbranos.
De las asechanzas del demonio, Señor, líbranos.
De la ira, del odio y de toda mala voluntad, Señor, líbranos.
Del rayo y de la tempestad, Señor, líbranos.
Del flagelo del terremoto, Señor, líbranos.
De peste, hambre y guerra, Señor, líbranos.
De la muerte eterna, Señor, líbranos.

A nosotros pecadores, Te suplicamos, óyenos.
Que perdones, Te lo suplicamos, óyenos.
Que nos traigas a penitencia verdadera, Te lo suplicamos, óyenos.
Que gobiernes y conserves tu Santa Iglesia, Te lo suplicamos, óyenos.
Que conserves a nuestro Santo Padre, Te lo suplicamos, óyenos.
Que des paz y unión a todo el pueblo cristiano, Te lo suplicamos, óyenos.

Cordero de Dios, que quitas el pecado del mundo, perdónanos, Señor.
Cordero de Dios, que quitas el pecado del mundo, escúchanos, Señor.
Cordero de Dios, que quitas el pecado del mundo, ten piedad de nosotros.

Cristo, escúchanos. Cristo, óyenos.
Señor, ten piedad. Cristo, ten piedad. Señor, ten piedad.''',
    'Litany of the Sacred Heart':
        '''Señor, ten piedad de nosotros. Cristo, ten piedad de nosotros.
Señor, ten piedad de nosotros. Cristo, escúchanos. Cristo, óyenos.

Dios Padre celestial, ten piedad de nosotros.
Dios Hijo, Redentor del mundo, ten piedad de nosotros.
Dios Espíritu Santo, ten piedad de nosotros.
Santísima Trinidad, un solo Dios, ten piedad de nosotros.

Corazón de Jesús, Hijo del Padre Eterno, ten piedad de nosotros.
Corazón de Jesús, formado por el Espíritu Santo en el seno de la Virgen Madre, ten piedad de nosotros.
Corazón de Jesús, unido sustancialmente al Verbo de Dios, ten piedad de nosotros.
Corazón de Jesús, de majestad infinita, ten piedad de nosotros.
Corazón de Jesús, templo sagrado de Dios, ten piedad de nosotros.
Corazón de Jesús, tabernáculo del Altísimo, ten piedad de nosotros.
Corazón de Jesús, casa de Dios y puerta del Cielo, ten piedad de nosotros.
Corazón de Jesús, horno ardiente de caridad, ten piedad de nosotros.
Corazón de Jesús, refugio de los afligidos, ten piedad de nosotros.
Corazón de Jesús, paciente y misericordiosísimo, ten piedad de nosotros.
Corazón de Jesús, generoso para todos los que te invocan, ten piedad de nosotros.
Corazón de Jesús, fuente de vida y santidad, ten piedad de nosotros.
Corazón de Jesús, propiciación de nuestros pecados, ten piedad de nosotros.
Corazón de Jesús, cargado de oprobios, ten piedad de nosotros.
Corazón de Jesús, manso y humilde de corazón, ten piedad de nosotros.
Corazón de Jesús, obediente hasta la muerte, ten piedad de nosotros.
Corazón de Jesús, atravesado por la lanza, ten piedad de nosotros.
Corazón de Jesús, fuente de toda consolación, ten piedad de nosotros.
Corazón de Jesús, nuestra vida y resurrección, ten piedad de nosotros.
Corazón de Jesús, nuestra paz y reconciliación, ten piedad de nosotros.
Corazón de Jesús, víctima de los pecadores, ten piedad de nosotros.
Corazón de Jesús, salvación de los que en ti confían, ten piedad de nosotros.
Corazón de Jesús, esperanza de los que mueren en ti, ten piedad de nosotros.
Corazón de Jesús, delicia de todos los Santos, ten piedad de nosotros.

Cordero de Dios, que quitas el pecado del mundo, perdónanos, Señor.
Cordero de Dios, que quitas el pecado del mundo, escúchanos, Señor.
Cordero de Dios, que quitas el pecado del mundo, ten piedad de nosotros.

V. Jesús, manso y humilde de corazón.
R. Haz nuestro corazón semejante al tuyo.

OREMOS: Todopoderoso y eterno Dios, mira el Corazón de tu Hijo bienamado, y las alabanzas y satisfacciones que te ofrece en nombre de los pecadores; y, aplacado, concede el perdón a los que imploren tu misericordia, en el nombre del mismo Jesucristo, tu Hijo, que vive y reina por los siglos de los siglos. Amén.''',
    'Morning Prayer (Prime)':
        '''En el nombre del Padre, y del Hijo, y del Espíritu Santo. Amén.

Padre nuestro, Dios te salve María, Creo en Dios.

V. Oh Dios, ven en mi auxilio.
R. Señor, apresúrate a socorrerme.
Gloria al Padre, y al Hijo, y al Espíritu Santo. Como era en el principio, ahora y siempre, y por los siglos de los siglos. Amén. Aleluya.


HIMNO

La estrella de la mañana va tras la noche;
por eso suplicamos humildemente:
que Dios, en nuestras palabras y obras,
nos guarde de todo mal durante este día.

Que sea Él quien, amoroso, nos frene
de gritos de contienda y palabras nocivas,
y envuelva y cierre nuestros ojos
ante las vanidades atractivas de la tierra.

Que ni en nuestro pecho more la ira,
ni los pensamientos que engendran vergüenza,
y que el ayuno doloroso domine
la soberbia de la carne voluptuosa;

para que cuando el día cansado cesare,
y la noche y el silencio vuelvan,
inmaculados y limpios del polvo del mundo
podamos repetir con gozo reverente

Al Dios Padre sea la gloria,
y a su Hijo Unigénito,
y al Espíritu, Uno y Trino,
mientras corren los siglos sin fin. Amén.


SALMO 54 (53)

Sálvame, oh Dios, por tu nombre, y hazme justicia con tu poder.
Escucha mi oración, oh Dios; presta oído a las palabras de mi boca.
Porque se levantaron hombres insolentes contra mí, y hombres violentos buscan mi vida; no ponen a Dios delante de sí.
Mira, Dios es mi auxiliador; el Señor sostiene mi vida.
Él devolverá el mal a mis enemigos; en tu fidelidad, acaba con ellos.
Con ofrenda voluntaria te sacrificaré; daré gracias a tu nombre, oh Señor, porque es bueno.
Porque me libraste de toda aflicción, y mis ojos verán la ruina de mis enemigos.
Gloria al Padre.


SALMO 118 (119): 1-32

Dichosos los que andan por el camino de la perfección, los que proceden conforme a la ley del Señor!
Dichosos los que guardan sus preceptos, y lo buscan de todo corazón,
y los que no proceden inicuamente, sino caminando por sus sendas!
Tú promulgaste tus mandatos, para que se cumplieran fielmente.
Ojalá se enmienden mis senderos, para guardar tus preceptos!
Entonces no me avergonzaré, al considerar todos tus mandamientos.
Te daré gracias con un corazón recto, cuando aprenda tus justos juicios.
Guardaré tus preceptos; no me abandones del todo.
¿Con qué purifica el joven su sendero? Con guardar según tu palabra.
De todo corazón te busco; no me dejes errar de tus mandamientos!
En mi corazón atesoro tus promesas, para no pecar contra ti.
Bendito eres, oh Señor; enséñame tus preceptos!
Con mis labios he contado todos los juicios de tu boca.
En la senda de tus preceptos me deleito más que en toda riqueza.
Meditaré sobre tus mandamientos, y miraré tus senderos.
Me deleitaré en tus preceptos; no olvidaré tu palabra.
Trata con generosidad a tu siervo, para que viva y guarde tu palabra.
Abre mis ojos, y contemplaré las maravillas de tu ley.
Soy forastero en la tierra; no escondas de mí tus mandamientos!
Mi alma se consume ansiando continuamente tus decretos.
Tú amenazas a los soberbios, malditos los que se desvían de tus mandamientos;
líbrame de su insulto y desprecio, porque guardo tus preceptos.
Aunque los príncipes se sentaron a hablar contra mí, tu siervo meditará tus preceptos;
pues tus preceptos son mi delicia, y mis consejeros tus preceptos.
Mi alma se pega al polvo: devuélveme a la vida según tu palabra!
Te manifesté mis senderos, y tú me respondiste; enséñame tus decretos!
Hazme penetrar en el sentido de tus preceptos, y meditaré tus maravillas.
Mi alma se consume de tristeza: confirma mis senderos con tu palabra!
Aparta de mí el sendero de la mentira; concédeme tu ley en tu gracia!
Elijo la vía de la fidelidad, ante mí pongo tus decretos.
Me adhiero a tus preceptos, oh Señor; no me avergüences!
Corro por el sendero de tus mandamientos, cuando dilatas mi corazón.
Gloria al Padre.


CAPÍTULO

Al Rey de los siglos, el Inmortal, el Invisible, el solo Dios, sean honor y gloria por los siglos de los siglos.
R. Loado sea Dios.


RESPONSORIO BREVE

Cristo, Hijo de Dios vivo, ten piedad de nosotros.
R. Cristo, Hijo de Dios vivo, ten piedad de nosotros.
V. Tú que estás sentado a la diestra del Padre.
R. Ten piedad de nosotros.
V. Gloria al Padre, y al Hijo, y al Espíritu Santo.
R. Cristo, Hijo de Dios vivo, ten piedad de nosotros.
V. Levántate, oh Cristo, y socórrenos.
R. Líbranos por tu nombre.


ORACIONES

V. Señor, escucha mi oración.
R. Y mi clamor llegue a Ti.
V. Dígnate, Señor, guardar este día
R. Sin pecado.
V. Ten piedad de nosotros, Señor.
R. Ten piedad de nosotros.
V. Sea tu misericordia, Señor, sobre nosotros.
R. Como hemos esperado en Ti.


COLECTA

Oh Señor Dios Todopoderoso, que nos has traído al comienzo de este día: que tu poder nos defienda en él, para que hoy no caigamos en pecado, y que todos nuestros pensamientos, palabras y obras se dirijan siempre a lo que es justo a tus ojos. Por nuestro Señor Jesucristo, tu Hijo, que vive y reina contigo en la unidad del Espíritu Santo, un solo Dios, por los siglos de los siglos. Amén.''',
    'Evening Prayer (Compline)':
        '''En el nombre del Padre, y del Hijo, y del Espíritu Santo. Amén.

V. Oh Dios, ven en mi auxilio.
R. Señor, apresúrate a socorrerme.
Gloria al Padre, y al Hijo, y al Espíritu Santo. Como era en el principio, ahora y siempre, y por los siglos de los siglos. Amén. Aleluya.


LECCIÓN BREVE

Sed sobrios, sed vigilantes. Tu adversario el diablo, como león rugiente, ronda buscando a quién devorar, al cual resistid firmes en la fe. Y que el Señor, oh Dios de los ejércitos, tenga misericordia de nosotros.
R. Loado sea Dios.

V. Nuestro auxilio está en el nombre del Señor.
R. Que hizo el cielo y la tierra.


SALMO 4 (3)

Cuando invoqué, me respondiste, Dios de mi justicia; en la tribulación me diste sosiego. Ten piedad de mí, y escucha mi oración!
Hijos de hombres, ¿hasta cuándo mi gloria sufrirá vergüenza? ¿Hasta cuándo amaréis la vanidad, y buscaréis la mentira?
Sabed que el Señor ha santificado a su propio fiel; el Señor escuchará cuando yo clamare a Él.
Temblad y no pequéis; hablad en vuestros corazones, en vuestros lechos, y callaos.
Ofreced sacrificios de justicia, y poned vuestra confianza en el Señor.
Muchos dicen: ¿Quién nos mostrará el bien? Se ha alzado sobre nosotros la luz de tu rostro, ¡Señor!
Multiplicaste la alegría en mi corazón más que en el tiempo de su trigo y su vino.
En paz me acostaré, y en seguida dormiré; porque Tú, Señor, me has hecho vivir en confianza.
Gloria al Padre.


SALMO 31 (30)

En Ti, Señor, busqué refugio; nunca quede confundido; en tu justicia, líbrame!
Inclina tu oído hacia mí; apresúrate a librarme! Sé mi roca, mi fortaleza, una fortaleza para salvarme!
Porque Tú eres mi roca y mi castillo; y por tu nombre me dirigirás y me guiarás.
Me sacarás de la red que ocultaron para mí, pues Tú eres mi refugio.
En tus manos encomiendo mi espíritu; Tú me has redimido, Señor, Dios fiel.
Gloria al Padre.


SALMO 91 (90)

Quien habita al abrigo del Altísimo, que mora bajo la sombra del Omnipotente, dirá al Señor: Refugio mío y fortaleza mía, mi Dios, en quien confío.
Pues Él te librará del lazo del cazador, y de la peste funesta.
Él te cubrirá con sus plumas, y bajo sus alas hallarás refugio; su fidelidad será tu escudo y pavesa.
No temerás el espanto nocturno, ni la flecha que vuela de día,
ni el contagio que acecha en las tinieblas, ni el mal que desola al mediodía.
Caerán mil a tu lado, diez mil a tu derecha, pero el mal no se te acercará.
Con tus ojos mirarás, y verás la recompensa de los impíos.
Porque dijiste: El Señor es mi refugio; he puesto al Altísimo por mi protección.
No se te acercará el mal, y ningún azote llegará a tu morada,
pues ha dado orden a sus Ángeles acerca de ti, para que te guarden en todos tus caminos.
En las manos te llevarán, para que tu pie no tropiece en piedra.
Sobre el león y el basilisco pisarás; pisotearás al leoncillo y al dragón.
Porque en mí ha puesto su amor, yo lo salvaré; lo pondré a salvo, porque ha conocido mi nombre.
Me invocará y yo lo responderé; con él estaré en el peligro; lo libraré y le daré gloria.
Con larga vida lo satisfaceré, y le mostraré mi salvación.
Gloria al Padre.


SALMO 134 (133)

He aquí, bendecid al Señor, todos vosotros los siervos del Señor, que estáis de noche en la casa del Señor!
Alzad vuestras manos hacia el santuario y bendecid al Señor!
Que el Señor te bendiga desde Sión, Él que hizo el cielo y la tierra!
Gloria al Padre.


HIMNO

Ahora que la luz del día muere,
por toda tu gracia y amor,
Te suplicamos, Hacedor del mundo,
que vigiles nuestro lecho.

Que los sueños se aparten y vuelen los fantasmas,
engendros de la noche;
guardanos, como santuarios, bajo tu Ojo,
puros frente a los enemigos.

Esta gracia confiere a tus redimidos,
Padre, Hijo Coigual,
y Espíritu Santo, el Consolador,
Uno y Trino eternamente. Amén.


CAPÍTULO

Tú, Señor, estás entre nosotros, y tu Santo Nombre es invocado sobre nosotros: no nos desampares, Señor Dios nuestro.
R. gracias a Dios.


RESPONSORIO

En tus manos, Señor, encomiendo mi espíritu.
R. En tus manos, Señor, encomiendo mi espíritu.
V. Tú nos has redimido, Señor, Dios de verdad.
R. Encomiendo mi espíritu.
V. Gloria al Padre, y al Hijo, y al Espíritu Santo.
R. En tus manos, Señor, encomiendo mi espíritu.
V. Guárdanos, Señor, como la pupila de tu ojo.
R. Protégenos bajo la sombra de tus alas.


CÁNTICO DE SIMEÓN (NUNC DIMITTIS)

Ant. Sálvanos, Señor, velando, guardanos durmiendo: que velemos con Cristo, y descansemos en paz.

Ahora, Señor, despedes a tu siervo irse en paz, según tu palabra;
porque mis ojos han visto tu salvación,
la que has preparado delante de todos los pueblos:
luz para iluminar a los gentiles, y gloria de tu pueblo Israel.
Gloria al Padre.


COLECTA

Visita, Te lo pedimos, Señor, esta morada, y aleja de ella todas las asechanzas del enemigo: que tus Santos Ángeles habiten en ella para conservarnos en paz, y que tu bendición permanezca siempre sobre nosotros. Por nuestro Señor Jesucristo, tu Hijo, que vive y reina contigo en la unidad del Espíritu Santo, un solo Dios, por los siglos de los siglos. Amén.


BENEDICIÓN

Que el Señor Todopoderoso y Misericordioso nos bendiga; el Padre, el Hijo, y el Espíritu Santo.
R. Amén.


ANTÍFONA MARIANA

Ver Salve Regina (Oraciones Marianas) o la antífona de cada estación:
• Alma Redemptoris Mater (Adviento hasta la Purificación)
• Ave Regina Caelorum (Purificación hasta la Semana Santa)
• Regina Caeli (Pascua hasta la Trinidad)
• Salve Regina (Trinidad hasta el Adviento)''',
    'Apostles\' Creed':
        'Creo en Dios, Padre todopoderoso, Creador del cielo y de la tierra. Creo en Jesucristo, su único Hijo, nuestro Señor, que fue concebido por obra y gracia del Espíritu Santo, nació de Santa María Virgen, padeció bajo el poder de Poncio Pilato, fue crucificado, muerto y sepultado, descendió a los infiernos, al tercer día resucitó de entre los muertos, subió a los cielos y está sentado a la derecha de Dios Padre todopoderoso. Desde allí ha de venir a juzgar a los vivos y a los muertos. Creo en el Espíritu Santo, la santa Iglesia católica, la comunión de los santos, el perdón de los pecados, la resurrección de la carne y la vida eterna. Amén.',
    'Nicene Creed':
        'Creo en un solo Dios, Padre todopoderoso, Creador del cielo y de la tierra, de todo lo visible y lo invisible.\n\nCreo en un solo Señor, Jesucristo, Hijo único de Dios, nacido del Padre antes de todos los siglos: Dios de Dios, Luz de Luz, Dios verdadero de Dios verdadero, engendrado, no creado, de la misma naturaleza del Padre; por quien todo fue hecho. Por nosotros los hombres, y por nuestra salvación, bajó del cielo, y por obra del Espíritu Santo se encarnó de María, la Virgen, y se hizo hombre; y por nuestra causa fue crucificado en tiempos de Poncio Pilato: padeció y fue sepultado, y resucitó al tercer día, según las Escrituras, y subió al cielo, y está sentado a la derecha del Padre; y de nuevo vendrá con gloria para juzgar a los vivos y a los muertos, y su reino no tendrá fin.\n\nCreo en el Espíritu Santo, Señor y dador de vida, que procede del Padre y del Hijo, que con el Padre y el Hijo recibe una misma adoración y gloria, y que habló por los profetas. Creo en la Iglesia, que es una, santa, católica y apostólica. Confieso un solo Bautismo para el perdón de los pecados. Espero la resurrección de los muertos y la vida del mundo futuro. Amén.',
    'Athanasian Creed':
        'Quien quiera salvarse, no tiene necesidad de ninguna otra cosa, sino que guarde íntegramente esta fe católica;\nLa cual, si alguien no la guardare íntegra e inviolablemente, sin duda perecerá eternamente.\nY esta es la fe católica: que adoremos a un solo Dios en la Trinidad, y a la Trinidad en la unidad;\nNo confundiendo las personas, ni separando las sustancias.\nPorque una es la persona del Padre, otra la del Hijo, otra la del Espíritu Santo;\nPero la divinidad del Padre, del Hijo y del Espíritu Santo es una sola: igual la gloria, coeterna la majestad.\nCual es el Padre, tal es el Hijo, tal es el Espíritu Santo.\nIncreado el Padre, increado el Hijo, increado el Espíritu Santo.\nInmenso el Padre, inmenso el Hijo, inmenso el Espíritu Santo.\nEterno el Padre, eterno el Hijo, eterno el Espíritu Santo.\nY sin embargo, no son tres eternos, sino un solo eterno;\nComo tampoco son tres increados, ni tres inmensos, sino un solo increado y un solo inmenso.\nAsimismo, el Padre es todopoderoso, el Hijo todopoderoso, el Espíritu Santo todopoderoso;\nY sin embargo, no son tres todopoderosos, sino un solo todopoderoso.\nAsí, el Padre es Dios, el Hijo es Dios, el Espíritu Santo es Dios;\nY sin embargo, no son tres dioses, sino un solo Dios.\nAsí, el Padre es Señor, el Hijo es Señor, el Espíritu Santo es Señor;\nY sin embargo, no son tres señores, sino un solo Señor.\nPorque así como somos obligados por la verdad cristiana a confesar que cada persona por sí es Dios y Señor;\nAsí nos prohíbe la religión católica decir tres dioses o tres señores.\nEl Padre no fue hecho por nadie, ni creado, ni engendrado.\nEl Hijo es solo del Padre: no hecho, ni creado, sino engendrado.\nEl Espíritu Santo es del Padre y del Hijo: no hecho, ni creado, ni engendrado, sino que procede.\nPor tanto, hay un solo Padre, no tres padres; un solo Hijo, no tres hijos; un solo Espíritu Santo, no tres espíritus santos.\nY en esta Trinidad, nada es anterior o posterior, nada es mayor o menor;\nSino que las tres personas son coeternas y coiguales entre sí;\nDe modo que, como ya se dijo, en todo se debe adorar la unidad en la Trinidad y la Trinidad en la unidad.\nPor tanto, quien quiera salvarse, así debe pensar de la Trinidad.\nPero es necesario para la salvación eterna que también crea fielmente en la encarnación de nuestro Señor Jesucristo.\nPor tanto, la fe recta es que creamos y confesemos que nuestro Señor Jesucristo, Hijo de Dios, es Dios y hombre.\nEs Dios, engendrado de la sustancia del Padre antes de los siglos; y es hombre, nacido de la sustancia de su madre en el mundo.\nDios perfecto, hombre perfecto: subsistente de alma racional y carne humana.\nIgual al Padre según la divinidad; menor que el Padre según la humanidad.\nEl cual, aunque es Dios y hombre, no son sin embargo dos, sino un solo Cristo;\nUno, no por conversión de la divinidad en carne, sino por asunción de la humanidad en Dios;\nUno absolutamente, no por confusión de sustancia, sino por unidad de persona.\nPorque así como el alma racional y la carne son un solo hombre, así Dios y hombre son un solo Cristo.\nEl cual padeció por nuestra salvación, descendió a los infiernos, al tercer día resucitó de entre los muertos;\nSubió a los cielos, está sentado a la derecha del Padre, Dios todopoderoso, desde donde vendrá a juzgar a los vivos y a los muertos.\nA cuyo advenimiento, todos los hombres han de resucitar con sus cuerpos, y han de dar cuenta de sus propios actos.\nY los que hicieron obras buenas irán a la vida eterna; los que hicieron malas, al fuego eterno.\nEsta es la fe católica, la cual, si alguien no la creyere fiel y firmemente, no podrá salvarse.',
    'Litany of the Most Holy Name of Jesus':
        'Señor, ten piedad de nosotros.\nCristo, ten piedad de nosotros.\nSeñor, ten piedad de nosotros.\nJesús, óyenos.\nJesús, óyenos con bondad.\n\nDios Padre del Cielo, ten piedad de nosotros.\nDios Hijo, Redentor del mundo, ten piedad de nosotros.\nDios Espíritu Santo, ten piedad de nosotros.\nSantísima Trinidad, un solo Dios, ten piedad de nosotros.\n\nJesús, Hijo de Dios vivo, ten piedad de nosotros.\nJesús, Resplandor del Padre, ten piedad de nosotros.\nJesús, Claridad de la luz eterna, ten piedad de nosotros.\nJesús, Rey de la gloria, ten piedad de nosotros.\nJesús, Sol de la justicia, ten piedad de nosotros.\nJesús, Hijo de la Virgen María, ten piedad de nosotros.\nJesús, amable en sumo grado, ten piedad de nosotros.\nJesús, admirable en sumo grado, ten piedad de nosotros.\nJesús, Dios fuerte, ten piedad de nosotros.\nJesús, Padre del siglo futuro, ten piedad de nosotros.\nJesús, Ángel del gran consejo, ten piedad de nosotros.\nJesús, poderosísimo, ten piedad de nosotros.\nJesús, pacientísimo, ten piedad de nosotros.\nJesús, obedientísimo, ten piedad de nosotros.\nJesús, manso y humilde de corazón, ten piedad de nosotros.\nJesús, amante de la castidad, ten piedad de nosotros.\nJesús, amante de nuestras almas, ten piedad de nosotros.\nJesús, Dios de la paz, ten piedad de nosotros.\nJesús, Autor de la vida, ten piedad de nosotros.\nJesús, Ejemplo de las virtudes, ten piedad de nosotros.\nJesús, celoso por las almas, ten piedad de nosotros.\nJesús, Dios vengador, ten piedad de nosotros.\nJesús, Padre de los pobres, ten piedad de nosotros.\nJesús, Tesoro de los fieles, ten piedad de nosotros.\nJesús, Buen Pastor, ten piedad de nosotros.\nJesús, Luz verdadera, ten piedad de nosotros.\nJesús, Sabiduría santa, ten piedad de nosotros.\nJesús, Dulzura de los corazones, ten piedad de nosotros.\nJesús, Esperanza nuestra, ten piedad de nosotros.\nJesús, Salvación nuestra, ten piedad de nosotros.\n\nCordero de Dios, que quitas los pecados del mundo, perdónanos, oh Jesús.\nCordero de Dios, que quitas los pecados del mundo, óyenos, oh Jesús.\nCordero de Dios, que quitas los pecados del mundo, ten piedad de nosotros, oh Jesús.\n\nJesús, óyenos.\nJesús, óyenos con bondad.\n\nOremos.\nOh Señor Jesucristo, que dijiste: "Pedid y recibiréis; buscad y hallaréis; llamad y se os abrirá": atiende misericordiosamente a nuestras súplicas y concédenos el don de tu divina caridad, para que te amemos con todo nuestro corazón, con todas nuestras palabras y obras, y nunca cesemos de alabarte. Danos, oh Señor, un continuo temor y amor de tu santo Nombre, porque jamás dejas de gobernar a los que instruyes en la solidez de tu amor. Tú que vives y reinas por los siglos de los siglos. Amén.',
    'Litany of St. Joseph':
        'Señor, ten piedad de nosotros.\nCristo, ten piedad de nosotros.\nSeñor, ten piedad de nosotros.\nCristo, óyenos.\nCristo, óyenos con bondad.\n\nDios Padre del Cielo, ten piedad de nosotros.\nDios Hijo, Redentor del mundo, ten piedad de nosotros.\nDios Espíritu Santo, ten piedad de nosotros.\nSantísima Trinidad, un solo Dios, ten piedad de nosotros.\n\nSanta María, ruega por nosotros.\nSan José, ruega por nosotros.\nNoble descendiente de David, ruega por nosotros.\nLuz de los Patriarcas, ruega por nosotros.\nEsposo de la Madre de Dios, ruega por nosotros.\nCustodio castísimo de la Virgen, ruega por nosotros.\nPadre nutricio del Hijo de Dios, ruega por nosotros.\nDiligente protector de Cristo, ruega por nosotros.\nCabeza de la Sagrada Familia, ruega por nosotros.\nJosé justísimo, ruega por nosotros.\nJosé castísimo, ruega por nosotros.\nJosé prudentísimo, ruega por nosotros.\nJosé fortísimo, ruega por nosotros.\nJosé obedientísimo, ruega por nosotros.\nJosé fidelísimo, ruega por nosotros.\nEspejo de paciencia, ruega por nosotros.\nAmante de la pobreza, ruega por nosotros.\nModelo de los obreros, ruega por nosotros.\nGloria de la vida doméstica, ruega por nosotros.\nCustodio de las vírgenes, ruega por nosotros.\nColumna de las familias, ruega por nosotros.\nConsuelo de los afligidos, ruega por nosotros.\nEsperanza de los enfermos, ruega por nosotros.\nPatrono de los moribundos, ruega por nosotros.\nTerror de los demonios, ruega por nosotros.\nProtector de la Santa Iglesia, ruega por nosotros.\n\nCordero de Dios, que quitas los pecados del mundo, perdónanos, oh Señor.\nCordero de Dios, que quitas los pecados del mundo, óyenos, oh Señor.\nCordero de Dios, que quitas los pecados del mundo, ten piedad de nosotros, oh Señor.\n\nLe hizo señor de su casa.\nY príncipe de toda su posesión.\n\nOremos.\nOh Dios, que en tu inefable providencia te dignaste elegir al bienaventurado José por Esposo de tu santísima Madre; concédenos, te lo pedimos, que tengamos en el cielo por intercesor al que en la tierra veneramos como protector. Tú que vives y reinas por los siglos de los siglos. Amén.',
    'Novena to Our Lady of La Leche':
        'Nuestra Señora de la Leche (Nuestra Señora de la Leche y Buen Parto) es venerada en el Santuario de la Misión Nombre de Dios en San Agustín, Florida — el santuario mariano más antiguo de los Estados Unidos. Su fiesta se celebra el 11 de octubre.\n\nEs costumbre que la novena se rece durante nueve días consecutivos. También puede rezarse un día determinado de la semana durante nueve semanas consecutivas (por ejemplo, los sábados), o un día determinado del mes durante nueve meses consecutivos (por ejemplo, los primeros sábados). En la Diócesis de San Agustín, la novena puede rezarse en preparación para la Fiesta de Nuestra Señora de la Leche, comenzando el 3 de octubre para que concluya el 11 de octubre.\n\nORACIÓN DE LA NOVENA (PRIMERA FORMA)\n\nAmable Señora de la Leche, amorosísima Madre de Jesús y madre mía, escucha mi humilde oración. Tu corazón maternal conoce cada uno de mis deseos, cada una de mis necesidades. Solo a ti, su Inmaculada Virgen Madre, te ha dado tu Divino Hijo el comprender los sentimientos que llenan mi alma. Tuya fue la sagrada dignidad de ser la Madre del Salvador.\n\nIntercede ahora ante él, madre mía amorosa, para que se haga conforme a su voluntad (menciona aquí tu petición). Esto te lo pido, oh Señora de la Leche, en el nombre de tu Divino Hijo, mi Señor y Salvador. Amén.\n\nV. Oh María, sin pecado concebida.\nR. Ruega por nosotros que recurrimos a ti.\nSeñora de la Leche, ruega por nosotros.\n\nORACIÓN DE LA NOVENA (SEGUNDA FORMA)\n\nAmable Señora de la Leche, amorosísima Madre de nuestro Salvador Jesucristo y madre mía, te ruego que escuches mi humilde oración. Tu corazón conoce cada uno de mis deseos, cada una de mis necesidades. Confío, querida Madre, en que me acogerás bajo tu manto protector, como acogiste a tu Hijo.\n\nIntercede ante él, te lo pido, para que tenga el valor y la fortaleza para vencer las dificultades que me rodeen. Concédeme la gracia de ser siempre fiel a ti, y sé mi inspiración luminosa ahora y para siempre.\n\nSi es conforme a la Divina Voluntad, te pido que obtengas para mí, por tu intercesión, el siguiente favor (menciona aquí tu petición).\n\nV. Oh María, sin pecado concebida.\nR. Ruega por nosotros que recurrimos a ti.\nSeñora de la Leche, ruega por nosotros.',
    'Litany of Our Lady of La Leche':
        'Señor, ten piedad de nosotros.\nSeñor, ten piedad de nosotros.\nCristo, ten piedad de nosotros.\nCristo, ten piedad de nosotros.\nSeñor, ten piedad de nosotros.\nSeñor, ten piedad de nosotros.\n\nDios, Padre nuestro en el cielo, ten piedad de nosotros.\nDios Hijo, Redentor del mundo, ten piedad de nosotros.\nDios Espíritu Santo, ten piedad de nosotros.\nSantísima Trinidad, un solo Dios, ten piedad de nosotros.\n\nSanta María, ruega por nosotros.\nHijísima casta del Padre, ruega por nosotros.\nCastísima Esposa del Espíritu Santo, ruega por nosotros.\nCastísima Madre del Hijo de Dios, ruega por nosotros.\nVaso de elección, ruega por nosotros.\nTrono de la divina Majestad, ruega por nosotros.\nTabernáculo del Verbo Divino, ruega por nosotros.\nCáliz de la Vida Divina, ruega por nosotros.\nSanta Madre de Dios, ruega por nosotros.\nSanta Madre del Niño Cristo, ruega por nosotros.\nConsagración de la feminidad, ruega por nosotros.\nEsperanza de la feminidad cristiana, ruega por nosotros.\nModelo de todas las madres cristianas, ruega por nosotros.\nBendecida en tu maternidad, ruega por nosotros.\nInspiración de la santidad maternal, ruega por nosotros.\nConsuelo de la maternidad, ruega por nosotros.\nProtectora de la maternidad, ruega por nosotros.\nBendición de toda la maternidad cristiana, ruega por nosotros.\nExaltación de la maternidad, ruega por nosotros.\nSantificación de la maternidad, ruega por nosotros.\nReina de la Santísima Familia, ruega por nosotros.\nReina de la casta vida familiar, ruega por nosotros.\nReina de las madres, ruega por nosotros.\nMadre de las madres, ruega por nosotros.\nMadre del parto feliz, ruega por nosotros.\n\nCordero de Dios, que quitas los pecados del mundo, ten piedad de nosotros.\nCordero de Dios, que quitas los pecados del mundo, ten piedad de nosotros.\nCordero de Dios, que quitas los pecados del mundo, ten piedad de nosotros.\n\nV. Señora de la Leche.\nR. Ruega por nosotros que recurrimos a ti.\n\nOremos.\n\nVirgen querida, Reina del cielo, elegida antes que todas las mujeres para ser madre del Hijo de Dios, María, madre mía, que en tu maternidad santificaste tanto el estado de la santa maternidad, vengo a ti implorando; humildemente te suplico; confiadamente confío en ti. Sé que, por tu poderosa intercesión, puedes ayudarme en mi necesidad. En ti me refugio, Virgen querida. Pobre y necesitado, me vuelvo devotamente a ti y pongo todas mis esperanzas confiadamente en tus manos. Acepta mi humilde confianza, escucha mis peticiones, y ven en mi auxilio, querida Madre de las madres. Amén.\n\nV. He aquí la esclava del Señor.\nR. Hágase en mí según tu palabra.',
  };

  /// Display names in Spanish (lookup keys stay English).
  static const Map<String, String> titlesEs = const {
    'The Lord\'s Prayer': 'Padre Nuestro',
    'Hail Mary': 'Dios te salve María',
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
    'Prayer to St. Michael the Archangel (Long)': 'Oración a San Miguel Arcángel (Versión larga)',
    'Prayer before a Crucifix': 'Oración ante un Crucifijo',
    'Apostles\' Creed': 'Credo Apostólico',
    'Nicene Creed': 'Credo Niceno',
    'Athanasian Creed': 'Credo Atanasiano',
    'Litany of the Most Holy Name of Jesus': 'Letanía del Santísimo Nombre de Jesús',
    'Litany of St. Joseph': 'Letanía de San José',
    'Novena to Our Lady of La Leche': 'Novena a Nuestra Señora de la Leche',
    'Litany of Our Lady of La Leche': 'Letanía de Nuestra Señora de la Leche',
  };

  /// Category display names in Spanish.
  static const Map<String, String> catEs = const {
    'Daily Prayers': 'Oraciones Diarias',
    'Morning & Evening Prayer': 'Oración Matutina y Vespertina',
    'Marian Prayers': 'Oraciones Marianas',
    'Litanies': 'Letanías',
    'Prayers for the Dead': 'Oraciones por los Difuntos',
    'Devotions': 'Devociones',
    'Creeds': 'Credos',
  };
}
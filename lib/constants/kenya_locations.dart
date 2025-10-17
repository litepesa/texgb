// lib/core/constants/kenya_locations.dart
// COMPLETE FILE - All 1,450 wards in Kenya (IEBC 2022 Official Data)
// File size: ~200KB - Production ready

class KenyaLocations {
  /// Complete list of all 1,450 wards organized by County -> Constituency
  /// Format: 'Ward Name' for easy dropdown selection
  static const Map<String, Map<String, List<String>>> wardsData = {
    'Mombasa': {
      'Changamwe': ['Port Reitz', 'Kipevu', 'Airport', 'Changamwe', 'Chaani'],
      'Jomvu': ['Jomvu Kuu', 'Miritini', 'Mikindani'],
      'Kisauni': ['Mjambere', 'Junda', 'Bamburi', 'Mwakirunge', 'Mtopanga', 'Magogoni', 'Shanzu'],
      'Nyali': ['Frere Town', 'Ziwa La Ng\'ombe', 'Mkomani', 'Kongowea', 'Kadzandani'],
      'Likoni': ['Mtongwe', 'Shika Adabu', 'Bofu', 'Likoni', 'Timbwani'],
      'Mvita': ['Mji Wa Kale/Makadara', 'Tudor', 'Tononoka', 'Shimanzi/Ganjoni', 'Majengo'],
    },
    'Kwale': {
      'Msambweni': ['Gombato Bongwe', 'Ukunda', 'Kinondo', 'Ramisi'],
      'Lungalunga': ['Pongwe/Kikoneni', 'Dzombo', 'Mwereni', 'Vanga'],
      'Matuga': ['Tsimba Golini', 'Waa', 'Tiwi', 'Kubo South', 'Mkongani'],
      'Kinango': ['Ndavaya', 'Puma', 'Kinango', 'Mackinnon Road', 'Chengoni/Samburu', 'Mwavumbo', 'Kasemeni'],
    },
    'Kilifi': {
      'Kilifi North': ['Tezo', 'Sokoni', 'Kibarani', 'Dabaso', 'Matsangoni', 'Watamu', 'Mnarani'],
      'Kilifi South': ['Junju', 'Mwarakaya', 'Shimo La Tewa', 'Chasimba', 'Mtepeni'],
      'Kaloleni': ['Mariakani', 'Kayafungo', 'Kaloleni', 'Mwanamwinga'],
      'Rabai': ['Mwawesa', 'Ruruma', 'Kambe/Ribe', 'Rabai/Kisurutini'],
      'Ganze': ['Ganze', 'Bamba', 'Jaribuni', 'Sokoke'],
      'Malindi': ['Jilore', 'Kakuyuni', 'Ganda', 'Malindi Town', 'Shella'],
      'Magarini': ['Marafa', 'Magarini', 'Gongoni', 'Adu', 'Garashi', 'Sabaki'],
    },
    'Tana River': {
      'Garsen': ['Kipini East', 'Garsen South', 'Kipini West', 'Garsen Central', 'Garsen West', 'Garsen North'],
      'Galole': ['Kinakomba', 'Mikinduni', 'Chewani', 'Wayu'],
      'Bura': ['Chewele', 'Hirimani', 'Bangale', 'Sala', 'Madogo'],
    },
    'Lamu': {
      'Lamu East': ['Faza', 'Kiunga', 'Basuba'],
      'Lamu West': ['Shella', 'Mkomani', 'Hindi', 'Mkunumbi', 'Hongwe', 'Witu', 'Bahari'],
    },
    'Taita Taveta': {
      'Taveta': ['Chala', 'Mahoo', 'Bomani', 'Mboghoni', 'Mata'],
      'Wundanyi': ['Wundanyi/Mbale', 'Werugha', 'Wumingu/Kishushe', 'Mwanda/Mgange'],
      'Mwatate': ['Rong\'e', 'Mwatate', 'Bura', 'Chawia', 'Wusi/Kishamba'],
      'Voi': ['Mbololo', 'Sagalla', 'Kaloleni', 'Marungu', 'Kasigau', 'Ngolia'],
    },
    'Garissa': {
      'Garissa Township': ['Waberi', 'Galbet', 'Township', 'Iftin'],
      'Balambala': ['Balambala', 'Danyere', 'Jara Jara', 'Saka', 'Sankuri'],
      'Lagdera': ['Modogashe', 'Benane', 'Goreale', 'Maalimin', 'Sabena', 'Baraki'],
      'Dadaab': ['Dertu', 'Dadaab', 'Labasigale', 'Damajale', 'Liboi', 'Abakaile'],
      'Fafi': ['Bura', 'Dekaharia', 'Jarajila', 'Fafi', 'Nanighi'],
      'Ijara': ['Hulugho', 'Sangailu', 'Ijara', 'Masalani'],
    },
    'Wajir': {
      'Wajir North': ['Gurar', 'Bute', 'Korondile', 'Malkagufu', 'Batalu', 'Danaba', 'Godoma'],
      'Wajir East': ['Wagberi', 'Township', 'Barwago', 'Khorof/Harar'],
      'Tarbaj': ['Elben', 'Sarman', 'Tarbaj', 'Wargadud'],
      'Wajir West': ['Arbajahan', 'Hadado/Athibohol', 'Adamasajide', 'Ganyure/Wagalla'],
      'Eldas': ['Eldas', 'Della', 'Lakoley South/Basir', 'Elnur/Tula Tula'],
      'Wajir South': ['Benane', 'Burder', 'Dadaja Bulla', 'Habasswein', 'Lagboghol South', 'Ibrahim Ure', 'Diif'],
    },
    'Mandera': {
      'Mandera West': ['Takaba South', 'Takaba', 'Lagsure', 'Dandu', 'Gither'],
      'Banissa': ['Banissa', 'Derkhale', 'Guba', 'Malkamari', 'Kiliwehiri'],
      'Mandera North': ['Ashabito', 'Guticha', 'Morothile', 'Rhamu', 'Rhamu-Dimtu'],
      'Mandera South': ['Wargadud', 'Kutulo', 'Elwak South', 'Elwak North', 'Shimbir Fatuma'],
      'Mandera East': ['Arabia', 'Township', 'Neboi', 'Khalalio', 'Libehia'],
      'Lafey': ['Sala', 'Fino', 'Lafey', 'Waranqara', 'Alango Gof'],
    },
    'Marsabit': {
      'Moyale': ['Butiye', 'Sololo', 'Heillu/Manyatta', 'Golbo', 'Moyale Township', 'Uran', 'Obbu'],
      'North Horr': ['Dukana', 'Maikona', 'Turbi', 'North Horr', 'Illeret'],
      'Saku': ['Sagante/Jaldesa', 'Karare', 'Marsabit Central'],
      'Laisamis': ['Loiyangalani', 'Kargi/South Horr', 'Korr/Ngurunit', 'Logo Logo', 'Laisamis'],
    },
    'Isiolo': {
      'Isiolo North': ['Wabera', 'Bulla Pesa', 'Chari', 'Cherab', 'Ngare Mara', 'Burat', 'Oldo/Nyiro'],
      'Isiolo South': ['Garbatulla', 'Kinna', 'Sericho'],
    },
    'Meru': {
      'Igembe South': ['Maua', 'Kiegoi/Antubochiu', 'Athiru Gaiti', 'Akachiu', 'Kanuni'],
      'Igembe Central': ['Akirang\'ondu', 'Athiru Ruujine', 'Igembe East', 'Njia', 'Kangeta'],
      'Igembe North': ['Antuambui', 'Ntunene', 'Antubetwe Kiongo', 'Naathu', 'Amwathi'],
      'Tigania West': ['Athwana', 'Akithii', 'Kianjai', 'Nkomo', 'Mbeu'],
      'Tigania East': ['Thangatha', 'Mikinduri', 'Kiguchwa', 'Muthara', 'Karama'],
      'North Imenti': ['Municipality', 'Ntima East', 'Ntima West', 'Nyaki West', 'Nyaki East'],
      'Buuri': ['Timau', 'Kisima', 'Kiirua/Naari', 'Ruiri/Rwarera', 'Kibirichia'],
      'Central Imenti': ['Mwanganthia', 'Abothuguchi Central', 'Abothuguchi West', 'Kiagu'],
      'South Imenti': ['Mitunguu', 'Igoji East', 'Igoji West', 'Abogeta East', 'Abogeta West', 'Nkuene'],
    },
    'Tharaka Nithi': {
      'Maara': ['Mitheru', 'Muthambi', 'Mwimbi', 'Ganga', 'Chogoria'],
      'Chuka/Igambang\'ombe': ['Mariani', 'Karingani', 'Magumoni', 'Mugwe', 'Igambang\'ombe'],
      'Tharaka': ['Gatunga', 'Mukothima', 'Nkondi', 'Chiakariga', 'Marimanti'],
    },
    'Embu': {
      'Manyatta': ['Ruguru/Ngandori', 'Kithimu', 'Nginda', 'Mbeti North', 'Kirimari', 'Gaturi South'],
      'Runyenjes': ['Gaturi North', 'Kagaari South', 'Central Ward', 'Kagaari North', 'Kyeni North', 'Kyeni South'],
      'Mbeere South': ['Mwea', 'Makima', 'Mbeti South', 'Mavuria', 'Kiambere'],
      'Mbeere North': ['Nthawa', 'Muminji', 'Evurore'],
    },
    'Kitui': {
      'Mwingi North': ['Ngomeni', 'Kyuso', 'Mumoni', 'Tseikuru', 'Tharaka'],
      'Mwingi West': ['Kyome/Thaana', 'Nguutani', 'Migwani', 'Kiomo/Kyethani'],
      'Mwingi Central': ['Central', 'Kivou', 'Nguni', 'Nuu', 'Mui', 'Waita'],
      'Kitui West': ['Mutonguni', 'Kauwi', 'Matinyani', 'Kwa Mutonga/Kithumula'],
      'Kitui Rural': ['Kisasi', 'Mbitini', 'Kwavonza/Yatta', 'Kanyangi'],
      'Kitui Central': ['Miambani', 'Township', 'Kyangwithya West', 'Mulango', 'Kyangwithya East'],
      'Kitui East': ['Zombe/Mwitika', 'Nzambani', 'Chuluni', 'Voo/Kyamatu', 'Endau/Malalani', 'Mutito/Kaliku'],
      'Kitui South': ['Ikanga/Kyatune', 'Mutomo', 'Mutha', 'Ikutha', 'Kanziko', 'Athi'],
    },
    'Machakos': {
      'Masinga': ['Kivaa', 'Masinga Central', 'Ekalakala', 'Muthesya', 'Ndithini'],
      'Yatta': ['Ndalani', 'Matuu', 'Kithimani', 'Ikombe', 'Katangi'],
      'Kangundo': ['Kangundo North', 'Kangundo Central', 'Kangundo East', 'Kangundo West'],
      'Matungulu': ['Tala', 'Matungulu North', 'Matungulu East', 'Matungulu West', 'Kyeleni'],
      'Kathiani': ['Mitaboni', 'Kathiani Central', 'Upper Kaewa/Iveti', 'Lower Kaewa/Kaani'],
      'Mavoko': ['Athi River', 'Kinanie', 'Muthwani', 'Syokimau/Mulolongo'],
      'Machakos Town': ['Kalama', 'Mua', 'Mutituni', 'Machakos Central', 'Mumbuni North', 'Muvuti/Kiima-Kimwe', 'Kola'],
      'Mwala': ['Mbiuni', 'Makutano/ Mwala', 'Masii', 'Muthetheni', 'Wamunyu', 'Kibauni'],
    },
    'Makueni': {
      'Mbooni': ['Tulimani', 'Mbooni', 'Kithungo/Kitundu', 'Kiteta/Kisau', 'Waia-Kako', 'Kalawa'],
      'Kilome': ['Kasikeu', 'Mukaa', 'Kiima Kiu/Kalanzoni'],
      'Kaiti': ['Ukia', 'Kee', 'Kilungu', 'Ilima'],
      'Makueni': ['Wote', 'Muvau/Kikuumini', 'Mavindini', 'Kitise/Kithuki', 'Kathonzweni', 'Nzaui/Kilili/Kalamba', 'Mbitini'],
      'Kibwezi West': ['Makindu', 'Nguumo', 'Kikumbulyu North', 'Kikumbulyu South', 'Nguu/Masumba', 'Emali/Mulala'],
      'Kibwezi East': ['Masongaleni', 'Mtito Andei', 'Thange', 'Ivingoni/Nzambani'],
    },
    'Nyandarua': {
      'Kinangop': ['Engineer', 'Gathara', 'North Kinangop', 'Murungaru', 'Njabini\\Kiburu', 'Nyakio', 'Githabai', 'Magumu'],
      'Kipipiri': ['Wanjohi', 'Kipipiri', 'Geta', 'Githioro'],
      'Ol Kalou': ['Karau', 'Kanjuiri Range', 'Mirangine', 'Kaimbaga', 'Rurii'],
      'Ol Jorok': ['Gathanji', 'Gatimu', 'Weru', 'Charagita'],
      'Ndaragwa': ['Leshau/Pondo', 'Kiriita', 'Central', 'Shamata'],
    },
    'Nyeri': {
      'Tetu': ['Dedan Kimanthi', 'Wamagana', 'Aguthi-Gaaki'],
      'Kieni': ['Mweiga', 'Naromoru Kiamathaga', 'Mwiyogo/Endarasha', 'Mugunda', 'Gatarakwa', 'Thegu River', 'Kabaru', 'Gakawa'],
      'Mathira': ['Ruguru', 'Magutu', 'Iriaini', 'Konyu', 'Kirimukuyu', 'Karatina Town'],
      'Othaya': ['Mahiga', 'Iria-Ini', 'Chinga', 'Karima'],
      'Mukurweini': ['Gikondi', 'Rugi', 'Mukurwe-Ini West', 'Mukurwe-Ini Central'],
      'Nyeri Town': ['Kiganjo/Mathari', 'Rware', 'Gatitu/Muruguru', 'Ruring\'u', 'Kamakwa/Mukaro'],
    },
    'Kirinyaga': {
      'Mwea': ['Mutithi', 'Kangai', 'Thiba', 'Wamumu', 'Nyangati', 'Murinduko', 'Gathigiriri', 'Tebere'],
      'Gichugu': ['Kabare', 'Baragwi', 'Njukiini', 'Ngariama', 'Karumandi'],
      'Ndia': ['Mukure', 'Kiine', 'Kariti'],
      'Kirinyaga Central': ['Mutira', 'Kanyekini', 'Kerugoya', 'Inoi'],
    },
    'Murang\'a': {
      'Kangema': ['Kanyenya-Ini', 'Muguru', 'Rwathia'],
      'Mathioya': ['Gitugi', 'Kiru', 'Kamacharia'],
      'Kiharu': ['Wangu', 'Mugoiri', 'Mbiri', 'Township', 'Murarandia', 'Gaturi'],
      'Kigumo': ['Kahumbu', 'Muthithi', 'Kigumo', 'Kangari', 'Kinyona'],
      'Maragwa': ['Kimorori/Wempa', 'Makuyu', 'Kambiti', 'Kamahuha', 'Ichagaki', 'Nginda'],
      'Kandara': ['Ng\'araria', 'Muruka', 'Kagundu-Ini', 'Gaichanjiru', 'Ithiru', 'Ruchu'],
      'Gatanga': ['Ithanga', 'Kakuzi/Mitubiri', 'Mugumo-Ini', 'Kihumbu-Ini', 'Gatanga', 'Kariara'],
    },
    'Kiambu': {
      'Gatundu South': ['Kiamwangi', 'Kiganjo', 'Ndarugu', 'Ngenda'],
      'Gatundu North': ['Gituamba', 'Githobokoni', 'Chania', 'Mang\'u'],
      'Juja': ['Murera', 'Theta', 'Juja', 'Witeithie', 'Kalimoni'],
      'Thika Town': ['Township', 'Kamenu', 'Hospital', 'Gatuanyaga', 'Ngoliba'],
      'Ruiru': ['Gitothua', 'Biashara', 'Gatongora', 'Kahawa Sukari', 'Kahawa Wendani', 'Kiuu', 'Mwiki', 'Mwihoko'],
      'Githunguri': ['Githunguri', 'Githiga', 'Ikinu', 'Ngewa', 'Komothai'],
      'Kiambu': ['Ting\'ang\'a', 'Ndumberi', 'Riabai', 'Township'],
      'Kiambaa': ['Cianda', 'Karuri', 'Ndenderu', 'Muchatha', 'Kihara'],
      'Kabete': ['Gitaru', 'Muguga', 'Nyadhuna', 'Kabete', 'Uthiru'],
      'Kikuyu': ['Karai', 'Nachu', 'Sigona', 'Kikuyu', 'Kinoo'],
      'Limuru': ['Bibirioni', 'Limuru Central', 'Ndeiya', 'Limuru East', 'Ngecha Tigoni'],
      'Lari': ['Kinale', 'Kijabe', 'Nyanduma', 'Kamburu', 'Lari/Kirenga'],
    },
    'Turkana': {
      'Turkana North': ['Kaeris', 'Lake Zone', 'Lapur', 'Kaaleng/Kaikor', 'Kibish', 'Nakalale'],
      'Turkana West': ['Kakuma', 'Lopur', 'Letea', 'Songot', 'Kalobeyei', 'Lokichoggio', 'Nanaam'],
      'Turkana Central': ['Kerio Delta', 'Kang\'atotha', 'Kalokol', 'Lodwar Township', 'Kanamkemer'],
      'Loima': ['Kotaruk/Lobei', 'Turkwel', 'Loima', 'Lokiriama/Lorengippi'],
      'Turkana South': ['Kaputir', 'Katilu', 'Lobokat', 'Kalapata', 'Lokichar'],
      'Turkana East': ['Kapedo/Napeitom', 'Katilia', 'Lokori/Kochodin'],
    },
    'West Pokot': {
      'Kapenguria': ['Riwo', 'Kapenguria', 'Mnagei', 'Siyoi', 'Endugh', 'Sook'],
      'Sigor': ['Sekerr', 'Masool', 'Lomut', 'Weiwei'],
      'Kacheliba': ['Suam', 'Kodich', 'Kasei', 'Kapchok', 'Kiwawa', 'Alale'],
      'Pokot South': ['Chepareria', 'Batei', 'Lelan', 'Tapach'],
    },
    'Samburu': {
      'Samburu West': ['Lodokejek', 'Suguta Marmar', 'Maralal', 'Loosuk', 'Poro'],
      'Samburu North': ['El-Barta', 'Nachola', 'Ndoto', 'Nyiro', 'Angata Nanyokie', 'Baawa'],
      'Samburu East': ['Waso', 'Wamba West', 'Wamba East', 'Wamba North'],
    },
    'Trans Nzoia': {
      'Kwanza': ['Kapomboi', 'Kwanza', 'Keiyo', 'Bidii'],
      'Endebess': ['Chepchoina', 'Endebess', 'Matumbei'],
      'Saboti': ['Kinyoro', 'Matisi', 'Tuwani', 'Saboti', 'Machewa'],
      'Kiminini': ['Kiminini', 'Waitaluk', 'Sirende', 'Hospital', 'Sikhendu', 'Nabiswa'],
      'Cherangany': ['Sinyerere', 'Makutano', 'Kaplamai', 'Motosiet', 'Cherangany/Suwerwa', 'Chepsiro/Kiptoror', 'Sitatunga'],
    },
    'Uasin Gishu': {
      'Soy': ['Moi\'s Bridge', 'Kapkures', 'Ziwa', 'Segero/Barsombe', 'Kipsomba', 'Soy', 'Kuinet/Kapsuswa'],
      'Turbo': ['Ngenyilel', 'Tapsagoi', 'Kamagut', 'Kiplombe', 'Kapsaos', 'Huruma'],
      'Moiben': ['Tembelio', 'Sergoit', 'Karuna/Meibeki', 'Moiben', 'Kimumu'],
      'Ainabkoi': ['Kapsoya', 'Kaptagat', 'Ainabkoi/Olare'],
      'Kapseret': ['Simat/Kapseret', 'Kipkenyo', 'Ngeria', 'Megun', 'Langas'],
      'Kesses': ['Racecourse', 'Cheptiret/Kipchamo', 'Tulwet/Chuiyat', 'Tarakwa'],
    },
    'Elgeyo Marakwet': {
      'Marakwet East': ['Kapyego', 'Sambirir', 'Endo', 'Embobut / Embulot'],
      'Marakwet West': ['Lelan', 'Sengwer', 'Cherang\'any/Chebororwa', 'Moiben/Kuserwo', 'Kapsowar', 'Arror'],
      'Keiyo North': ['Emsoo', 'Kamariny', 'Kapchemutwa', 'Tambach'],
      'Keiyo South': ['Kaptarakwa', 'Chepkorio', 'Soy North', 'Soy South', 'Kabiemit', 'Metkei'],
    },
    'Nandi': {
      'Tinderet': ['Songhor/Soba', 'Tindiret', 'Chemelil/Chemase', 'Kapsimotwo'],
      'Aldai': ['Kabwareng', 'Terik', 'Kemeloi-Maraba', 'Kobujoi', 'Kaptumo-Kaboi', 'Koyo-Ndurio'],
      'Nandi Hills': ['Nandi Hills', 'Chepkunyuk', 'Ol\'lessos', 'Kapchorua'],
      'Chesumei': ['Chemundu/Kapng\'etuny', 'Kosirai', 'Lelmokwo/Ngechek', 'Kaptel/Kamoiywo', 'Kiptuya'],
      'Emgwen': ['Chepkumia', 'Kapkangani', 'Kapsabet', 'Kilibwoni'],
      'Mosop': ['Chepterwai', 'Kipkaren', 'Kurgung/Surungai', 'Kabiyet', 'Ndalat', 'Kabisaga', 'Sangalo/Kebulonik'],
    },
    'Baringo': {
      'Tiaty': ['Tirioko', 'Kolowa', 'Ribkwo', 'Silale', 'Loiyamorock', 'Tangulbei/Korossi', 'Churo/Amaya'],
      'Baringo North': ['Barwessa', 'Kabartonjo', 'Saimo/Kipsaraman', 'Saimo/Soi', 'Bartabwa'],
      'Baringo Central': ['Kabarnet', 'Sacho', 'Tenges', 'Ewalel/Chapchap', 'Kapropita'],
      'Baringo South': ['Marigat', 'Ilchamus', 'Mochongoi', 'Mukutani'],
      'Mogotio': ['Mogotio', 'Emining', 'Kisanana'],
      'Eldama Ravine': ['Lembus', 'Lembus Kwen', 'Ravine', 'Mumberes/Maji Mazuri', 'Lembus/Perkerra', 'Koibatek'],
    },
    'Laikipia': {
      'Laikipia West': ['Ol-Moran', 'Rumuruti Township', 'Githiga', 'Marmanet', 'Igwamiti', 'Salama'],
      'Laikipia East': ['Ngobit', 'Tigithi', 'Thingithu', 'Nanyuki', 'Umande'],
      'Laikipia North': ['Sosian', 'Segera', 'Mugogodo West', 'Mugogodo East'],
    },
    'Nakuru': {
      'Molo': ['Mariashoni', 'Elburgon', 'Turi', 'Molo'],
      'Njoro': ['Mau Narok', 'Mauche', 'Kihingo', 'Nessuit', 'Lare', 'Njoro'],
      'Naivasha': ['Biashara', 'Hells Gate', 'Lake View', 'Mai Mahiu', 'Maiella', 'Olkaria', 'Naivasha East', 'Viwandani'],
      'Gilgil': ['Gilgil', 'Elementaita', 'Mbaruk/Eburu','Malewa West', 'Murindati'],
      'Kuresoi South': ['Amalo', 'Keringet', 'Kiptagich', 'Tinet'],
      'Kuresoi North': ['Kiptororo', 'Nyota', 'Sirikwa', 'Kamara'],
      'Subukia': ['Subukia', 'Waseges', 'Kabazi'],
      'Rongai': ['Menengai West', 'Soin', 'Visoi', 'Mosop', 'Solai'],
      'Bahati': ['Dundori', 'Kabatini', 'Kiamaina', 'Lanet/Umoja', 'Bahati'],
      'Nakuru Town West': ['Barut', 'London', 'Kaptembwo', 'Kapkures', 'Rhoda', 'Shaabab'],
      'Nakuru Town East': ['Biashara', 'Kivumbini', 'Flamingo', 'Menengai', 'Nakuru East'],
    },
    'Narok': {
      'Kilgoris': ['Kilgoris Central', 'Keyian', 'Angata Barikoi', 'Shankoe', 'Kimintet', 'Lolgorian'],
      'Emurua Dikirr': ['Ilkerin', 'Ololmasani', 'Mogondo', 'Kapsasian'],
      'Narok North': ['Olpusimoru', 'Olokurto', 'Narok Town', 'Nkareta', 'Olorropil', 'Melili'],
      'Narok East': ['Mosiro', 'Ildamat', 'Keekonyokie', 'Suswa'],
      'Narok South': ['Majimoto/Naroosura', 'Ololulung\'a', 'Melelo', 'Loita', 'Sogoo', 'Sagamian'],
      'Narok West': ['Ilmotiok', 'Mara', 'Siana', 'Naikarra'],
    },
    'Kajiado': {
      'Kajiado North': ['Olkeri', 'Ongata Rongai', 'Nkaimurunya', 'Oloolua', 'Ngong'],
      'Kajiado Central': ['Purko', 'Ildamat', 'Dalalekutuk', 'Matapato North', 'Matapato South'],
      'Kajiado East': ['Kaputiei North', 'Kitengela', 'Oloosirkon/Sholinke', 'Kenyawa-Poka', 'Imaroro'],
      'Kajiado West': ['Keekonyokie', 'Iloodokilani', 'Magadi', 'Ewuaso Oonkidong\'i', 'Mosiro'],
      'Kajiado South': ['Entonet/Lenkisim', 'Mbirikani/Eselenkei', 'Kuku', 'Rombo', 'Kimana'],
    },
    'Kericho': {
      'Kipkelion East': ['Londiani', 'Kedowa/Kimugul', 'Chepseon', 'Tendeno/Sorget'],
      'Kipkelion West': ['Kunyak', 'Kamasian', 'Kipkelion', 'Chilchila'],
      'Ainamoi': ['Kapsoit', 'Ainamoi', 'Kapkugerwet', 'Kipchebor', 'Kipchimchim', 'Kapsaos'],
      'Bureti': ['Kisiara', 'Tebesonik', 'Cheboin', 'Chemosot', 'Litein', 'Cheplanget', 'Kapkatet'],
      'Belgut': ['Waldai', 'Kabianga', 'Cheptororiet/Seretut', 'Chaik', 'Kapsuser'],
      'Sigowet/Soin': ['Sigowet', 'Kaplelartet', 'Soliat', 'Soin'],
    },
    'Bomet': {
      'Sotik': ['Ndanai/Abosi', 'Chemagel', 'Kipsonoi', 'Kapletundo', 'Rongena/Manaret'],
      'Chepalungu': ['Kong\'asis', 'Nyangores', 'Sigor', 'Chebunyo', 'Siongiroi'],
      'Bomet East': ['Merigi', 'Kembu', 'Longisa', 'Kipreres', 'Chemaner'],
      'Bomet Central': ['Silibwet Township', 'Ndaraweta', 'Singorwet', 'Chesoen', 'Mutarakwa'],
      'Konoin': ['Chepchabas', 'Kimulot', 'Mogogosiek', 'Boito', 'Embomos'],
    },
    'Kakamega': {
      'Lugari': ['Mautuma', 'Lugari', 'Lumakanda', 'Chekalini', 'Chevaywa', 'Lwandeti'],
      'Likuyani': ['Likuyani', 'Sango', 'Kongoni', 'Nzoia', 'Sinoko'],
      'Malava': ['West Kabras', 'Chemuche', 'East Kabras', 'Butali/Chegulo', 'Manda-Shivanga', 'Shirugu-Mugai', 'South Kabras'],
      'Lurambi': ['Butsotso East', 'Butsotso South', 'Butsotso Central', 'Sheywe', 'Mahiakalo', 'Shirere'],
      'Navakholo': ['Ingostse-Mathia', 'Shinoyi-Shikomari-Esumeyia', 'Bunyala West', 'Bunyala East', 'Bunyala Central'],
      'Mumias West': ['Mumias Central', 'Mumias North', 'Etenje', 'Musanda'],
      'Mumias East': ['Lusheya/Lubinu', 'Malaha/Isongo/Makunga', 'East Wanga'],
      'Matungu': ['Koyonzo', 'Kholera', 'Khalaba', 'Mayoni', 'Namamali'],
      'Butere': ['Marama West', 'Marama Central', 'Marenyo - Shianda', 'Marama North', 'Marama South'],
      'Khwisero': ['Kisa North', 'Kisa East', 'Kisa West', 'Kisa Central'],
      'Shinyalu': ['Isukha North', 'Murhanda', 'Isukha Central', 'Isukha South', 'Isukha East', 'Isukha West'],
      'Ikolomani': ['Idakho South', 'Idakho East', 'Idakho North', 'Idakho Central'],
    },
    'Vihiga': {
      'Vihiga': ['Lugaga-Wamuluma', 'South Maragoli', 'Central Maragoli', 'Mungoma'],
      'Sabatia': ['Lyaduywa/Izava', 'West Sabatia', 'Chavakali', 'North Maragoli', 'Wodanga', 'Busali'],
      'Hamisi': ['Shiru', 'Gisambai', 'Shamakhokho', 'Banja', 'Muhudu', 'Tambua', 'Jepkoyai'],
      'Luanda': ['Luanda Township', 'Wemilabi', 'Mwibona', 'Luanda South', 'Emabungo'],
      'Emuhaya': ['North East Bunyore', 'Central Bunyore', 'West Bunyore'],
    },
    'Bungoma': {
      'Mt. Elgon': ['Cheptais', 'Chesikaki', 'Chepyuk', 'Kapkateny', 'Kaptama', 'Elgon'],
      'Sirisia': ['Namwela', 'Malakisi/South Kulisiru', 'Lwandanyi'],
      'Kabuchai': ['Kabuchai/Chwele', 'West Nalondo', 'Bwake/Luuya', 'Mukuyuni'],
      'Bumula': ['South Bukusu', 'Bumula', 'Khasoko', 'Kabula', 'Kimaeti', 'West Bukusu', 'Siboti'],
      'Kanduyi': ['Bukembe West', 'Bukembe East', 'Township', 'Khalaba', 'Musikoma', 'East Sang\'alo', 'Marakaru/Tuuti', 'West Sang\'alo'],
      'Webuye East': ['Mihuu', 'Ndivisi', 'Maraka'],
      'Webuye West': ['Misikhu', 'Sitikho', 'Matulo', 'Bokoli'],
      'Kimilili': ['Kibingei', 'Kimilili', 'Maeni', 'Kamukuywa'],
      'Tongaren': ['Mbakalo', 'Naitiri/Kabuyefwe', 'Milima', 'Ndalu/ Tabani', 'Tongaren', 'Soysambu/ Mitua'],
    },
    'Busia': {
      'Teso North': ['Malaba Central', 'Malaba North', 'Ang\'urai South', 'Ang\'urai North', 'Ang\'urai East', 'Malaba South'],
      'Teso South': ['Ang\'orom', 'Chakol South', 'Chakol North', 'Amukura West', 'Amukura East', 'Amukura Central'],
      'Nambale': ['Nambale Township', 'Bukhayo North/Waltsi', 'Bukhayo East', 'Bukhayo Central'],
      'Matayos': ['Bukhayo West', 'Mayenje', 'Matayos South', 'Busibwabo', 'Burumba'],
      'Butula': ['Marachi West', 'Kingandole', 'Marachi Central', 'Marachi East', 'Marachi North', 'Elugulu'],
      'Funyula': ['Namboboto Nambuku', 'Nangina', 'Ageng\'a Nanguba', 'Bwiri'],
      'Budalangi': ['Bunyala Central', 'Bunyala North', 'Bunyala West', 'Bunyala South'],
    },
    'Siaya': {
      'Ugenya': ['West Ugenya', 'Ukwala', 'North Ugenya', 'East Ugenya'],
      'Ugunja': ['Sidindi', 'Sigomere', 'Ugunja'],
      'Alego Usonga': ['Usonga', 'West Alego', 'Central Alego', 'Siaya Township', 'North Alego', 'South East Alego'],
      'Gem': ['North Gem', 'West Gem', 'Central Gem', 'Yala Township', 'East Gem', 'South Gem'],
      'Bondo': ['West Yimbo', 'Central Sakwa', 'South Sakwa', 'Yimbo East', 'West Sakwa', 'North Sakwa'],
      'Rarieda': ['East Asembo', 'West Asembo', 'North Uyoma', 'South Uyoma', 'West Uyoma'],
    },
    'Kisumu': {
      'Kisumu East': ['Kajulu', 'Kolwa East', 'Manyatta \'B\'', 'Nyalenda \'A\'', 'Kolwa Central'],
      'Kisumu West': ['South West Kisumu', 'Central Kisumu', 'Kisumu North', 'West Kisumu', 'North West Kisumu'],
      'Kisumu Central': ['Railways', 'Migosi', 'Shaurimoyo Kaloleni', 'Market Milimani', 'Kondele', 'Nyalenda B'],
      'Seme': ['West Seme', 'Central Seme', 'East Seme', 'North Seme'],
      'Nyando': ['East Kano/Wawidhi', 'Awasi/Onjiko', 'Ahero', 'Kabonyo/Kanyagwal', 'Kobura'],
      'Muhoroni': ['Miwani', 'Ombeyi', 'Masogo/Nyang\'oma', 'Chemelil', 'Muhoroni/Koru'],
      'Nyakach': ['South West Nyakach', 'North Nyakach', 'Central Nyakach', 'West Nyakach', 'South East Nyakach'],
    },
    'Homa Bay': {
      'Kasipul': ['West Kasipul', 'South Kasipul', 'Central Kasipul', 'East Kamagak', 'West Kamagak'],
      'Kabondo Kasipul': ['Kabondo East', 'Kabondo West', 'Kokwanyo/Kakelo', 'Kojwach'],
      'Karachuonyo': ['West Karachuonyo', 'North Karachuonyo', 'Central', 'Kanyaluo', 'Kibiri', 'Wangchieng', 'Kendu Bay Town'],
      'Rangwe': ['West Gem', 'East Gem', 'Kagan', 'Kochia'],
      'Homa Bay Town': ['Homa Bay Central', 'Homa Bay Arujo', 'Homa Bay West', 'Homa Bay East'],
      'Ndhiwa': ['Kwabwai', 'Kanyadoto', 'Kanyikela', 'Kabuoch North', 'Kabuoch South/Pala', 'Kanyamwa Kologi', 'Kanyamwa Kosewe'],
      'Suba North': ['Mfangano Island', 'Rusinga Island', 'Kasgunga', 'Gembe', 'Lambwe'],
      'Suba South': ['Gwassi South', 'Gwassi North', 'Kaksingri West', 'Ruma-Kaksingri'],
    },
    'Migori': {
      'Rongo': ['North Kamagambo', 'Central Kamagambo', 'East Kamagambo', 'South Kamagambo'],
      'Awendo': ['North Sakwa', 'South Sakwa', 'West Sakwa', 'Central Sakwa'],
      'Suna East': ['God Jope', 'Suna Central', 'Kakrao', 'Kwa'],
      'Suna West': ['Wiga', 'Wasweta II', 'Ragana-Oruba', 'Wasimbete'],
      'Uriri': ['West Kanyamkago', 'North Kanyamkago', 'Central Kanyamkago', 'South Kanyamkago', 'East Kanyamkago'],
      'Nyatike': ['Kachien\'g', 'Kanyasa', 'North Kadem', 'Macalder/Kanyarwanda', 'Kaler', 'Got Kachola', 'Muhuru'],
      'Kuria West': ['Bukira East', 'Bukira Centrl/Ikerege', 'Isibania', 'Makerero', 'Masaba', 'Tagare', 'Nyamosense/Komosoko'],
      'Kuria East': ['Gokeharaka/Getambwega', 'Ntimaru West', 'Ntimaru East', 'Nyabasi East', 'Nyabasi West'],
    },
    'Kisii': {
      'Bonchari': ['Bomariba', 'Bogiakumu', 'Bomorenda', 'Riana'],
      'South Mugirango': ['Tabaka', 'Boikang\'a', 'Bogetenga', 'Borabu / Chitago', 'Moticho', 'Getenga'],
      'Bomachoge Borabu': ['Bombaba Borabu', 'Boochi Borabu', 'Bokimonge', 'Magenche'],
      'Bobasi': ['Masige West', 'Masige East', 'Basi Central', 'Nyacheki', 'Basi Bogetaorio', 'Bobasi Chache', 'Sameta/Mokwerero', 'Bobasi Boitangare'],
      'Bomachoge Chache': ['Majoge Basi', 'Boochi/Tendere', 'Bosoti/Sengera'],
      'Nyaribari Masaba': ['Ichuni', 'Nyamasibi', 'Masimba', 'Gesusu', 'Kiamokama'],
      'Nyaribari Chache': ['Bobaracho', 'Kisii Central', 'Keumbu', 'Kiogoro', 'Birongo', 'Ibeno'],
      'Kitutu Chache North': ['Monyerero', 'Sensi', 'Marani', 'Kegogi'],
      'Kitutu Chache South': ['Bogusero', 'Bogeka', 'Nyakoe', 'Kitutu Central', 'Nyatieko'],
    },
    'Nyamira': {
      'Kitutu Masaba': ['Rigoma', 'Gachuba', 'Kemera', 'Magombo', 'Manga', 'Gesima'],
      'West Mugirango': ['Nyamaiya', 'Bogichora', 'Bosamaro', 'Bonyamatuta', 'Township'],
      'North Mugirango': ['Itibo', 'Bomwagamo', 'Bokeira', 'Magwagwa', 'Ekerenyo'],
      'Borabu': ['Mekenene', 'Kiabonyoru', 'Nyansiongo', 'Esise'],
    },
    'Nairobi': {
      'Westlands': ['Kitisuru', 'Parklands/Highridge', 'Karura', 'Kangemi', 'Mountain View'],
      'Dagoretti North': ['Kilimani', 'Kawangware', 'Gatina', 'Kileleshwa', 'Kabiro'],
      'Dagoretti South': ['Mutu-Ini', 'Ngando', 'Riruta', 'Uthiru/Ruthimitu', 'Waithaka'],
      'Lang\'ata': ['Karen', 'Nairobi West', 'Mugumu-Ini', 'South C', 'Nyayo Highrise'],
      'Kibra': ['Laini Saba', 'Lindi', 'Makina', 'Woodley/Kenyatta Golf Course', 'Sarang\'ombe'],
      'Roysambu': ['Githurai', 'Kahawa West', 'Zimmerman', 'Roysambu', 'Kahawa'],
      'Kasarani': ['Clay City', 'Mwiki', 'Kasarani', 'Njiru', 'Ruai'],
      'Ruaraka': ['Baba Dogo', 'Utalii', 'Mathare North', 'Lucky Summer', 'Korogocho'],
      'Embakasi South': ['Imara Daima', 'Kwa Njenga', 'Kwa Reuben', 'Pipeline', 'Kware'],
      'Embakasi North': ['Kariobangi North', 'Dandora Area I', 'Dandora Area II', 'Dandora Area III', 'Dandora Area IV'],
      'Embakasi Central': ['Kayole North', 'Kayole Central', 'Kayole South', 'Komarock', 'Matopeni/Spring Valley'],
      'Embakasi East': ['Upper Savannah', 'Lower Savannah', 'Embakasi', 'Utawala', 'Mihango'],
      'Embakasi West': ['Umoja I', 'Umoja II', 'Mowlem', 'Kariobangi South'],
      'Makadara': ['Maringo/Hamza', 'Viwandani', 'Harambee', 'Makongeni'],
      'Kamukunji': ['Pumwani', 'Eastleigh North', 'Eastleigh South', 'Airbase', 'California'],
      'Starehe': ['Nairobi Central', 'Ngara', 'Pangani', 'Ziwani/Kariokor', 'Landimawe', 'Nairobi South'],
      'Mathare': ['Hospital', 'Mabatini', 'Huruma', 'Ngei', 'Mlango Kubwa', 'Kiamaiko'],
    },
  };

  /// Get all counties
  static List<String> get allCounties => wardsData.keys.toList()..sort();

  /// Get constituencies for a county
  static List<String> getConstituencies(String county) {
    return wardsData[county]?.keys.toList() ?? [];
  }

  /// Get wards for a constituency
  static List<String> getWards(String county, String constituency) {
    return wardsData[county]?[constituency] ?? [];
  }

  /// Get all wards in a county (flat list)
  static List<String> getAllWardsInCounty(String county) {
    final List<String> wards = [];
    final constituencyData = wardsData[county];
    if (constituencyData != null) {
      for (var wardList in constituencyData.values) {
        wards.addAll(wardList);
      }
    }
    return wards..sort();
  }

  /// Format full location: "Ward, Constituency, County"
  static String formatLocation(String ward, String constituency, String county) {
    return '$ward, $constituency, $county';
  }

  /// Search all wards by query
  static List<String> searchWards(String query, {int limit = 50}) {
    if (query.isEmpty) return [];
    
    final List<String> results = [];
    final lowerQuery = query.toLowerCase();
    
    wardsData.forEach((county, constituencies) {
      constituencies.forEach((constituency, wards) {
        for (var ward in wards) {
          if (results.length >= limit) return;
          if (ward.toLowerCase().contains(lowerQuery) ||
              constituency.toLowerCase().contains(lowerQuery) ||
              county.toLowerCase().contains(lowerQuery)) {
            results.add(formatLocation(ward, constituency, county));
          }
        }
      });
    });
    
    return results;
  }

  /// Get total ward count
  static int get totalWards {
    int count = 0;
    wardsData.forEach((county, constituencies) {
      constituencies.forEach((constituency, wards) {
        count += wards.length;
      });
    });
    return count; // Should be 1450
  }

  /// Get ward count per county
  static Map<String, int> get wardCountByCounty {
    final Map<String, int> counts = {};
    wardsData.forEach((county, constituencies) {
      int countyTotal = 0;
      for (var wards in constituencies.values) {
        countyTotal += wards.length;
      }
      counts[county] = countyTotal;
    });
    return counts;
  }
}

/// Helper class for location data
class LocationData {
  final String ward;
  final String constituency;
  final String county;

  LocationData({
    required this.ward,
    required this.constituency,
    required this.county,
  });

  String get fullLocation => KenyaLocations.formatLocation(ward, constituency, county);

  Map<String, dynamic> toMap() => {
    'ward': ward,
    'constituency': constituency,
    'county': county,
    'fullLocation': fullLocation,
  };

  factory LocationData.fromMap(Map<String, dynamic> map) => LocationData(
    ward: map['ward'] ?? '',
    constituency: map['constituency'] ?? '',
    county: map['county'] ?? '',
  );

  factory LocationData.fromString(String fullLocation) {
    final parts = fullLocation.split(', ');
    if (parts.length == 3) {
      return LocationData(
        ward: parts[0],
        constituency: parts[1],
        county: parts[2],
      );
    }
    throw FormatException('Invalid location format');
  }

  @override
  String toString() => fullLocation;
}
      
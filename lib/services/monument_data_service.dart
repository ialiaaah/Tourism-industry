import 'package:flutter/material.dart';
import '../models/ar_models.dart';

// Monument model + static database with aliases for Google Vision matching
// Add new monuments at the bottom of the `monuments` list.

class MonumentInfo {
  final String id;
  final String name;
  final String era;
  final String location;
  final String overview;
  final String history;
  final List<String> funFacts;
  final String emoji;
  /// All name variants Google Vision might return for this monument
  final List<String> aliases;

  final String? customCulturalSignificance;
  final String? customShortDescription;
  final List<TimelineEvent>? customTimeline;
  final List<ARHotspot>? customARHotspots;
  final List<TreasureHuntMission>? customTreasureHuntMissions;
  final String? customAudioNarrationText;

  String get assetImage => 'assets/monuments/$id.jpg';

  const MonumentInfo({
    required this.id,
    required this.name,
    required this.era,
    required this.location,
    required this.overview,
    required this.history,
    required this.funFacts,
    required this.emoji,
    this.aliases = const [],
    this.customCulturalSignificance,
    this.customShortDescription,
    this.customTimeline,
    this.customARHotspots,
    this.customTreasureHuntMissions,
    this.customAudioNarrationText,
  });

  // Getters with fallbacks
  String get shortDescription => customShortDescription ?? '$name is a legendary monument located in $location, dating back to $era.';
  String get culturalSignificance => customCulturalSignificance ?? '$name holds enormous cultural importance as a symbol of the $era, reflecting the exceptional creativity and craftsmanship of its builders.';
  String get audioNarrationText => customAudioNarrationText ?? 'Welcome to $name. $overview';

  List<TimelineEvent> get timeline {
    if (customTimeline != null && customTimeline!.isNotEmpty) {
      return customTimeline!;
    }
    return [
      TimelineEvent(year: 'Ancient Era', title: 'Carving & Creation', description: 'The grand structure of $name was conceived and built during the $era.'),
      TimelineEvent(year: 'Modern Era', title: 'Restoration', description: 'Excavation and major conservation projects helped preserve its structural integrity for future generations.'),
      TimelineEvent(year: 'Present', title: 'Unlocks in CulturaX', description: 'Interactive AR scanning brings $name directly to life for global explorers.'),
    ];
  }

  List<ARHotspot> get arHotspots {
    if (customARHotspots != null && customARHotspots!.isNotEmpty) {
      return customARHotspots!;
    }
    return [
      ARHotspot(
        id: '${id}_hotspot_1',
        title: 'Architectural Details',
        description: 'Observe the grand scale and structural precision characteristic of $era construction.',
        position: const Offset(0.3, 0.4),
        type: HotspotType.architecture,
        icon: Icons.account_balance,
      ),
      ARHotspot(
        id: '${id}_hotspot_2',
        title: 'Historical Origin',
        description: 'Dating back to the $era, this monument witnessed pivotal moments of ancient civilization.',
        position: const Offset(0.7, 0.35),
        type: HotspotType.history,
        icon: Icons.history_edu,
      ),
      ARHotspot(
        id: '${id}_hotspot_3',
        title: 'Cultural Legend',
        description: 'Legends suggest this site was of immense ritualistic or governmental significance.',
        position: const Offset(0.5, 0.65),
        type: HotspotType.story,
        icon: Icons.auto_stories,
      ),
      ARHotspot(
        id: '${id}_hotspot_4',
        title: 'Symbolic Significance',
        description: 'The location, alignment, and carving methods hold deep solar and celestial alignments.',
        position: const Offset(0.2, 0.7),
        type: HotspotType.symbol,
        icon: Icons.stars,
      ),
    ];
  }

  List<TreasureHuntMission> get treasureHuntMissions {
    if (customTreasureHuntMissions != null && customTreasureHuntMissions!.isNotEmpty) {
      return customTreasureHuntMissions!;
    }
    return [
      TreasureHuntMission(
        id: '${id}_mission_1',
        monumentId: id,
        title: 'Architectural Wonder',
        clue: 'Locate the primary architectural hotspot showcasing the structural design elements.',
        hint: 'Tap the building-like blue icon situated on the left side of the screen.',
        correctHotspotId: '${id}_hotspot_1',
        rewardPoints: 50,
        badgeReward: '',
        artifactReward: 'Ancient Blueprint',
      ),
      TreasureHuntMission(
        id: '${id}_mission_2',
        monumentId: id,
        title: 'Unlocking History',
        clue: 'Find the historical origin node to understand the deep cultural timelines of this site.',
        hint: 'Look for the scroll or pen icon near the upper right of the monument.',
        correctHotspotId: '${id}_hotspot_2',
        rewardPoints: 75,
        badgeReward: '',
        artifactReward: 'Scroll of $name',
      ),
    ];
  }
}


class MonumentDataService {
  // ── Egyptian monuments ────────────────────────────────────────────────────
  static const List<MonumentInfo> monuments = [
    MonumentInfo(
      id: 'sphinx',
      name: 'The Great Sphinx',
      era: 'Old Kingdom, c. 2500 BCE',
      location: 'Giza Plateau, Cairo',
      overview:
          'The Great Sphinx of Giza is the world\'s largest monolithic statue, carved from a single limestone outcrop. It has the body of a lion and the head of a human — believed to represent Pharaoh Khafre.',
      history:
          'Carved during the reign of Khafre, the Sphinx faces east toward the rising sun. For much of its history it was buried to the neck in sand. The "Dream Stele" between its paws records how Thutmose IV cleared the sand after a dream promised him the throne.',
      funFacts: [
        'It is 73 meters long and 20 meters tall — the world\'s largest monolithic statue.',
        'The nose was not shot off by Napoleon; it was already missing by the 15th century.',
        'It was once painted in bright colors: red, blue, and yellow.',
        'The Sphinx faces the rising sun, aligning with the spring and autumn equinoxes.',
      ],
      emoji: '🦁',
      aliases: [
        'Great Sphinx',
        'Great Sphinx of Giza',
        'The Great Sphinx',
        'The Sphinx',
        'Sphinx of Giza',
        'Sphinx',
      ],
    ),
    MonumentInfo(
      id: 'pyramids_giza',
      name: 'Pyramids of Giza',
      era: 'Old Kingdom, c. 2560–2510 BCE',
      location: 'Giza Plateau, Cairo',
      overview:
          'The Giza pyramid complex contains three main pyramids: Khufu (the Great Pyramid), Khafre, and Menkaure. Together they are the only surviving wonder of the ancient Seven Wonders of the World.',
      history:
          'Built over roughly 85 years, the pyramids served as royal tombs. The Great Pyramid of Khufu is the oldest and largest, originally standing 146.5 meters tall. Thousands of skilled workers built these monuments using copper tools, wooden sledges, and remarkable engineering.',
      funFacts: [
        'The Great Pyramid was the tallest man-made structure in the world for 3,800 years.',
        'Each stone block weighs between 2.5 and 15 tonnes.',
        'The pyramids are aligned almost perfectly to true north.',
        'Recent scans discovered hidden chambers inside the Great Pyramid.',
      ],
      emoji: '🔺',
      aliases: [
        'Pyramids of Giza',
        'Great Pyramid of Giza',
        'Giza Pyramids',
        'Giza Necropolis',
        'Great Pyramid',
        'Pyramid of Khufu',
        'Pyramid of Cheops',
        'Pyramid of Khafre',
        'Pyramid of Menkaure',
        'Khufu Pyramid',
      ],
    ),
    MonumentInfo(
      id: 'great_temple_ramesses',
      name: 'Abu Simbel',
      era: 'New Kingdom, c. 1264–1244 BCE',
      location: 'Abu Simbel, Aswan Governorate',
      overview:
          'The Great Temple of Abu Simbel is one of ancient Egypt\'s most spectacular monuments. Carved directly into a cliff face, its four colossal statues of Ramesses II stand 20 meters tall.',
      history:
          'Built to commemorate the victory at Kadesh. UNESCO relocated the entire temple — cut into 1,000+ blocks — to save it from Lake Nasser flooding between 1964–1968.',
      funFacts: [
        'Twice a year, sunlight illuminates the inner sanctuary on Feb 22 and Oct 22.',
        'The entire mountain temple was relocated 65 meters up and 200 meters back.',
        'Four statues each stand 20 meters (65 feet) tall.',
        'The smaller temple nearby is dedicated to Queen Nefertari.',
      ],
      emoji: '🌅',
      aliases: [
        'Abu Simbel',
        'Abu Simbel Temples',
        'Great Temple of Abu Simbel',
        'Great Temple of Ramesses II',
        'Temple of Ramesses II',
        'Ramesses II Temple',
      ],
    ),
    MonumentInfo(
      id: 'temple_isis_philae',
      name: 'Temple of Isis at Philae',
      era: 'Ptolemaic Period, c. 380–362 BCE',
      location: 'Agilkia Island, Aswan',
      overview:
          'The Temple of Isis at Philae is one of Egypt\'s most beautiful ancient temples. It was the last active temple of the ancient Egyptian religion, with worship continuing until the 6th century CE.',
      history:
          'Originally on Philae Island, the temple was dismantled stone by stone and moved to Agilkia Island by UNESCO between 1972–1980 to save it from the rising waters of Lake Nasser.',
      funFacts: [
        'It was the last temple where ancient Egyptian religion was actively practised.',
        'The entire temple was moved stone by stone to save it from flooding.',
        'Some walls still bear early Christian carvings over the hieroglyphs.',
        'The island setting makes it one of Egypt\'s most photogenic monuments.',
      ],
      emoji: '🌊',
      aliases: [
        'Temple of Philae',
        'Philae Temple',
        'Philae',
        'Temple of Isis',
        'Temple of Isis at Philae',
        'Isis Temple Philae',
      ],
    ),
    MonumentInfo(
      id: 'karnak_temple',
      name: 'Karnak Temple',
      era: 'Middle Kingdom to Ptolemaic Period, c. 2055–30 BCE',
      location: 'Luxor (ancient Thebes), Egypt',
      overview:
          'Karnak is the largest ancient religious site in the world — a vast complex of temples, pylons, obelisks, and chapels built by successive pharaohs over 2,000 years, primarily dedicated to the god Amun.',
      history:
          'Construction began in the Middle Kingdom and continued through the New Kingdom, when Karnak was the most important religious center in Egypt. Pharaohs like Thutmose I, Hatshepsut, and Ramesses II all left their mark. The Hypostyle Hall contains 134 massive columns.',
      funFacts: [
        'The Karnak complex covers more than 100 hectares — roughly the size of 10 city blocks.',
        'The Hypostyle Hall has 134 columns, some over 21 meters tall.',
        'It has been under continuous construction for over 2,000 years.',
        'The sacred lake within the complex was used for ritual purification.',
      ],
      emoji: '🏛️',
      aliases: [
        'Karnak',
        'Karnak Temple',
        'Karnak Temple Complex',
        'Temple of Karnak',
        'Karnak Temples',
        'Great Temple of Amun',
        'Temples of Karnak',
      ],
    ),
    MonumentInfo(
      id: 'luxor_temple',
      name: 'Luxor Temple',
      era: 'New Kingdom, c. 1400–1200 BCE',
      location: 'Luxor (ancient Thebes), Egypt',
      overview:
          'Luxor Temple is a large ancient Egyptian temple complex located on the east bank of the Nile. Unlike most Egyptian temples, it was not dedicated to a cult god or a deified pharaoh, but to the rejuvenation of kingship.',
      history:
          'Mainly built by Amenhotep III and Ramesses II, the temple served as the site of the annual Opet Festival where the pharaoh\'s divine power was renewed. An avenue of sphinxes once connected it to Karnak Temple 3 km away.',
      funFacts: [
        'A Roman chapel, early Christian church, and mosque were all built inside the temple over the centuries.',
        'The Avenue of Sphinxes connecting it to Karnak was 2.7 km long.',
        'One of its obelisks now stands in the Place de la Concorde in Paris.',
        'The temple was buried under Luxor city for centuries and rediscovered in the 19th century.',
      ],
      emoji: '🌙',
      aliases: [
        'Luxor Temple',
        'Temple of Luxor',
        'Luxor',
        'Luxor Temple Complex',
        'Temple of Amun Luxor',
      ],
    ),
    MonumentInfo(
      id: 'colossi_memnon',
      name: 'Colossi of Memnon',
      era: 'New Kingdom, c. 1350 BCE',
      location: 'Luxor (West Bank), Egypt',
      overview:
          'The Colossi of Memnon are two massive stone statues of Pharaoh Amenhotep III. Each stands about 18 meters high and weighs 720 tonnes. They have guarded the entrance to his mortuary temple for 3,400 years.',
      history:
          'In ancient times, the northern statue was famous for emitting a musical sound at dawn — Greeks attributed it to Memnon greeting his mother Eos. The sound stopped after a Roman restoration in 199 CE.',
      funFacts: [
        'The statues were once the tallest standing statues in the ancient world.',
        'The "singing" sound was likely caused by temperature changes cracking the damaged stone.',
        'The mortuary temple behind them was the largest in ancient Thebes.',
        'Emperor Hadrian visited them in 130 CE and heard the mysterious sound.',
      ],
      emoji: '👑',
      aliases: [
        'Colossi of Memnon',
        'Colossoi of Memnon',
        'Memnon Colossi',
        'Statues of Memnon',
        'Colossal Statues of Memnon',
      ],
    ),
    MonumentInfo(
      id: 'pyramid_djoser',
      name: 'Step Pyramid of Djoser',
      era: 'Old Kingdom, c. 2650 BCE',
      location: 'Saqqara, Egypt',
      overview:
          'The Step Pyramid of Djoser at Saqqara is the world\'s oldest monumental stone structure. Designed by the architect Imhotep, it revolutionized Egyptian architecture and paved the way for the Great Pyramids.',
      history:
          'Pharaoh Djoser commissioned Imhotep to build his burial complex. Starting as a mastaba, it was expanded six times to create the iconic stepped form, reaching 62 meters high.',
      funFacts: [
        'It is the oldest large-scale cut stone structure in the world.',
        'Its architect Imhotep was later deified as a god of medicine.',
        'It consists of six mastabas stacked on top of each other.',
        'The pyramid underwent a major 14-year restoration completed in 2020.',
      ],
      emoji: '📐',
      aliases: [
        'Step Pyramid',
        'Step Pyramid of Djoser',
        'Pyramid of Djoser',
        'Djoser Pyramid',
        'Zoser Pyramid',
        'Saqqara Step Pyramid',
        'Pyramid of Zoser',
      ],
    ),
    MonumentInfo(
      id: 'egyptian_museum',
      name: 'Egyptian Museum',
      era: 'Founded 1902 CE',
      location: 'Tahrir Square, Cairo',
      overview:
          'The Egyptian Museum in Cairo houses the world\'s most extensive collection of ancient Egyptian antiquities — over 120,000 items spanning 5,000 years, including the treasures of Tutankhamun.',
      history:
          'Opened in 1902, the museum was designed by French architect Marcel Dourgnon. It holds artefacts from the Predynastic era to the Greco-Roman period. The Grand Egyptian Museum near Giza is its modern successor.',
      funFacts: [
        'It holds over 120,000 ancient artefacts.',
        'The Tutankhamun collection alone fills an entire floor.',
        'The mummy room contains royal mummies including Ramesses II.',
        'The new Grand Egyptian Museum nearby is the largest archaeological museum in the world.',
      ],
      emoji: '🏺',
      aliases: [
        'Egyptian Museum',
        'Cairo Museum',
        'Museum of Egyptian Antiquities',
        'Egyptian Museum Cairo',
        'Grand Egyptian Museum',
        'GEM',
      ],
    ),
    MonumentInfo(
      id: 'citadel_saladin',
      name: 'Citadel of Saladin',
      era: 'Medieval Islamic, built 1183–1184 CE',
      location: 'Mokattam Hill, Cairo',
      overview:
          'The Citadel of Saladin is a medieval Islamic fortification in Cairo built by the great general Salah al-Din (Saladin). It served as the seat of Egyptian government for 700 years and dominates the Cairo skyline.',
      history:
          'Commissioned by Saladin to defend Cairo against Crusader attacks, the citadel was expanded by successive sultans and Ottoman rulers. The Muhammad Ali Mosque (Alabaster Mosque) inside the citadel is one of Cairo\'s most iconic landmarks.',
      funFacts: [
        'It served as Egypt\'s seat of government from the 13th to the 19th century.',
        'The Muhammad Ali Mosque inside took 18 years to build (1830–1848).',
        'The citadel\'s walls are up to 10 meters thick.',
        'Napoleon used the citadel as his headquarters during his Egyptian campaign.',
      ],
      emoji: '🏰',
      aliases: [
        'Citadel of Saladin',
        'Cairo Citadel',
        'Saladin Citadel',
        'The Citadel',
        'Citadel of Cairo',
        'Salah El-Din Citadel',
        'Muhammad Ali Mosque',
        'Alabaster Mosque',
        'Mosque of Muhammad Ali',
      ],
    ),
    MonumentInfo(
      id: 'tutankhamun_mask',
      name: 'Mask of Tutankhamun',
      era: '18th Dynasty, c. 1323 BCE',
      location: 'Grand Egyptian Museum, Cairo',
      overview:
          'The golden death mask of Tutankhamun is perhaps the most iconic object from ancient Egypt. Made of solid gold weighing 10.23 kg, it is a masterpiece of ancient craftsmanship.',
      history:
          'Found by Howard Carter in 1922 in the intact tomb KV62 in the Valley of the Kings. The discovery caused a worldwide sensation and revived global interest in Egyptology.',
      funFacts: [
        'The mask is made of 10 kg of solid gold.',
        'The eyes are crafted from quartz and obsidian.',
        'Tutankhamun died at approximately 19 years of age.',
        'The tomb\'s discovery sparked the worldwide "Tutmania" craze.',
      ],
      emoji: '🥇',
      aliases: [
        'Mask of Tutankhamun',
        'Tutankhamun Mask',
        'Golden Mask of Tutankhamun',
        'Death Mask of Tutankhamun',
        'King Tut Mask',
      ],
    ),
    MonumentInfo(
      id: 'nefertiti',
      name: 'Nefertiti Bust',
      era: '18th Dynasty, c. 1345 BCE',
      location: 'Neues Museum, Berlin',
      overview:
          'The painted limestone bust of Nefertiti is one of the most famous works of ancient Egyptian art. Nefertiti was the Great Royal Wife of Akhenaten.',
      history:
          'Created by the sculptor Thutmose around 1345 BCE, discovered in 1912 at his workshop in Amarna. It has been housed in Berlin since 1913.',
      funFacts: [
        'Her name means "the beautiful one has come" in ancient Egyptian.',
        'Egypt has repeatedly requested the return of the bust from Germany.',
        'She may have ruled as pharaoh after Akhenaten\'s death.',
        'The bust has been on continuous display since 1924.',
      ],
      emoji: '💎',
      aliases: [
        'Nefertiti',
        'Nefertiti Bust',
        'Bust of Nefertiti',
        'Queen Nefertiti',
      ],
    ),
    MonumentInfo(
      id: 'hatshepsut',
      name: 'Temple of Hatshepsut',
      era: '18th Dynasty, c. 1507–1458 BCE',
      location: 'Deir el-Bahari, Luxor',
      overview:
          'Hatshepsut\'s mortuary temple at Deir el-Bahari is considered a masterpiece of ancient architecture. She was one of the most successful pharaohs of ancient Egypt, ruling as king for over 20 years.',
      history:
          'After her husband Thutmose II died, Hatshepsut declared herself pharaoh, wearing the traditional male regalia. She organised a famous trading expedition to the land of Punt.',
      funFacts: [
        'After her death, Thutmose III erased her image from monuments.',
        'Her mummy was identified in 2007 from a single tooth.',
        'She sent an expedition to the mysterious land of Punt.',
        'Her temple features rare painted reliefs depicting her divine birth.',
      ],
      emoji: '👸',
      aliases: [
        'Hatshepsut',
        'Temple of Hatshepsut',
        'Deir el-Bahari',
        'Mortuary Temple of Hatshepsut',
        'Temple of Queen Hatshepsut',
      ],
    ),
    MonumentInfo(
      id: 'temple_kom_ombo',
      name: 'Temple of Kom Ombo',
      era: 'Ptolemaic Period, c. 180–47 BCE',
      location: 'Kom Ombo, Aswan Governorate',
      overview:
          'The Temple of Kom Ombo is unique in Egypt — a double temple dedicated to two gods: Sobek (the crocodile god) and Horus the Elder (the falcon god). Everything in the temple is perfectly symmetrical.',
      history:
          'Built mainly during the Ptolemaic period, the temple sits on a promontory at the bend of the Nile.',
      funFacts: [
        'It is the only temple in Egypt dedicated to two gods simultaneously.',
        'Mummified crocodiles found nearby are displayed in the on-site museum.',
        'Its walls show what appear to be ancient surgical instruments.',
        'It contains one of the earliest known calendars carved in stone.',
      ],
      emoji: '🐊',
      aliases: [
        'Temple of Kom Ombo',
        'Kom Ombo',
        'Kom Ombo Temple',
        'Double Temple of Kom Ombo',
      ],
    ),
    MonumentInfo(
      id: 'ramesseum',
      name: 'The Ramesseum',
      era: 'New Kingdom, c. 1279–1213 BCE',
      location: 'Luxor (West Bank), Egypt',
      overview:
          'The Ramesseum is the mortuary temple of Pharaoh Ramesses II. Its massive fallen granite statue inspired Percy Bysshe Shelley\'s famous poem "Ozymandias."',
      history:
          'Construction began shortly after Ramesses II\'s coronation and took about 20 years. The temple was dedicated to Amun.',
      funFacts: [
        'The poem "Ozymandias" by Shelley was inspired by this site.',
        'A fallen colossus of Ramesses II here once stood 17 meters tall.',
        'The temple granaries stored enough food to feed thousands.',
        '"Ozymandias" is a Greek rendering of Ramesses II\'s royal name.',
      ],
      emoji: '🏛️',
      aliases: [
        'Ramesseum',
        'The Ramesseum',
        'Mortuary Temple of Ramesses II',
        'Temple of Ramesses',
      ],
    ),
    MonumentInfo(
      id: 'bent_pyramid',
      name: 'Bent Pyramid',
      era: 'Old Kingdom, c. 2600 BCE',
      location: 'Dahshur, Egypt',
      overview:
          'The Bent Pyramid is a unique ancient Egyptian pyramid built under Pharaoh Sneferu. Its distinctive shape — angled at 54° then changing to 43° — makes it one of the most recognizable pyramids in Egypt.',
      history:
          'It is believed the angle was changed mid-construction due to structural concerns. The Bent Pyramid represents a transitional phase between step pyramids and true smooth-sided pyramids.',
      funFacts: [
        'It still retains much of its original white limestone casing.',
        'It has two entrances — one on the north face and one on the west.',
        'Its internal chambers are remarkably well preserved.',
        'It opened to the public for the first time in 2019.',
      ],
      emoji: '🔺',
      aliases: [
        'Bent Pyramid',
        'Bent Pyramid of Sneferu',
        'Rhomboidal Pyramid',
        'Southern Shining Pyramid',
      ],
    ),
    MonumentInfo(
      id: 'colossal_ramesses_ii',
      name: 'Colossal Statue of Ramesses II',
      era: 'New Kingdom, c. 1279–1213 BCE',
      location: 'Memphis / Grand Egyptian Museum, Cairo',
      overview:
          'This massive limestone statue of Ramesses II was originally at Memphis. Standing over 10 meters tall, it is one of the most celebrated examples of ancient Egyptian royal sculpture.',
      history:
          'Ramesses II, also known as Ramesses the Great, ruled for 66 years and commissioned more statues than any other pharaoh.',
      funFacts: [
        'The statue weighs approximately 83 tonnes.',
        'Ramesses II fathered over 100 children.',
        'He is thought to be the pharaoh of the Biblical Exodus.',
        'The statue originally stood at the entrance of the Temple of Ptah in Memphis.',
      ],
      emoji: '🗿',
      aliases: [
        'Colossal Statue of Ramesses II',
        'Ramesses II Statue',
        'Memphis Colossus',
      ],
    ),
    MonumentInfo(
      id: 'akhenaten',
      name: 'Akhenaten',
      era: '18th Dynasty, c. 1353–1336 BCE',
      location: 'Amarna, Egypt',
      overview:
          'Akhenaten was the "heretic pharaoh" who revolutionized Egyptian religion by promoting monotheistic worship of the Aten (sun disk).',
      history:
          'Born Amenhotep IV, he changed his name and moved the capital to Akhetaten (modern Amarna). His successors reversed nearly all his religious reforms.',
      funFacts: [
        'He is believed to be the father of Tutankhamun.',
        'His wife was the famous Queen Nefertiti.',
        'He introduced one of the earliest forms of monotheism in recorded history.',
        'His distinctive elongated artistic style is called the Amarna style.',
      ],
      emoji: '☀️',
      aliases: ['Akhenaten', 'Akhenaton', 'Amenhotep IV'],
    ),
    MonumentInfo(
      id: 'menkaure_pyramid',
      name: 'Pyramid of Menkaure',
      era: 'Old Kingdom, c. 2510 BCE',
      location: 'Giza Plateau, Cairo',
      overview:
          'The smallest of the three Giza pyramids, famous for its beautiful granite casing and stunning royal statue triads.',
      history:
          'Built by Pharaoh Menkaure, grandson of Khufu, the pyramid was originally cased in red Aswan granite at the bottom.',
      funFacts: [
        'Its bottom courses were cased in expensive red Aswan granite.',
        'Beautiful schist statue triads of Menkaure were found in its valley temple.',
        'An attempt to demolish it in 1196 CE failed after 8 months.',
        'It stands 65 meters tall.',
      ],
      emoji: '⛰️',
      aliases: [
        'Pyramid of Menkaure',
        'Menkaure Pyramid',
        'Mycerinus Pyramid',
        'Pyramid of Mycerinus',
      ],
    ),
  ];

  // ── Matching logic ────────────────────────────────────────────────────────

  /// Match a name returned by Google Vision API to a local monument.
  /// Tries: exact alias → partial alias → fuzzy word match.
  static MonumentInfo? findByDetectedName(String detectedName) {
    final query = detectedName.toLowerCase().trim();

    // Pass 1: exact alias match (case-insensitive)
    for (final m in monuments) {
      for (final alias in m.aliases) {
        if (alias.toLowerCase() == query) return m;
      }
    }

    // Pass 2: query contains alias OR alias contains query
    for (final m in monuments) {
      for (final alias in m.aliases) {
        final a = alias.toLowerCase();
        if (query.contains(a) || a.contains(query)) return m;
      }
    }

    // Pass 3: fuzzy — any significant word (>4 chars) from the monument name
    for (final m in monuments) {
      final words = m.name.toLowerCase().split(RegExp(r'\s+'));
      for (final word in words) {
        if (word.length > 4 && query.contains(word)) return m;
      }
    }

    // Pass 4: fuzzy — significant word from query found in any alias
    final queryWords = query.split(RegExp(r'\s+')).where((w) => w.length > 4);
    for (final m in monuments) {
      for (final alias in m.aliases) {
        for (final word in queryWords) {
          if (alias.toLowerCase().contains(word)) return m;
        }
      }
    }

    return null;
  }

  /// Legacy name lookup (used by old histogram scanner).
  static MonumentInfo? findByName(String name) => findByDetectedName(name);

  /// Alias for compatibility.
  static MonumentInfo? findByLabel(String label) => findByDetectedName(label);
}

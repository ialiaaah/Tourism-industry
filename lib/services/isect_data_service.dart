import 'package:flutter/material.dart';

enum EditionStatus { past, upcoming, announced }
enum SessionType { ceremony, keynote, session, workshop, panel, tour, social }

class ISECTEdition {
  final String id;
  final int year;
  final String flag;
  final String country;
  final String city;
  final String venue;
  final String theme;
  final String dates;
  final EditionStatus status;
  final int? attendees;
  final int? sessionCount;
  final String description;
  final Color accentColor;

  const ISECTEdition({
    required this.id, required this.year, required this.flag,
    required this.country, required this.city, required this.venue,
    required this.theme, required this.dates, required this.status,
    this.attendees, this.sessionCount,
    required this.description, required this.accentColor,
  });
}

class ISECTSpeaker {
  final String name;
  final String title;
  final String institution;
  final String country;
  final String flag;
  final String bio;
  final String specialty;
  final String emoji;

  const ISECTSpeaker({
    required this.name, required this.title, required this.institution,
    required this.country, required this.flag, required this.bio,
    required this.specialty, required this.emoji,
  });
}

class ISECTSession {
  final String title;
  final String speaker;
  final String time;
  final String day;
  final SessionType type;
  final String description;
  final String room;

  const ISECTSession({
    required this.title, required this.speaker, required this.time,
    required this.day, required this.type,
    required this.description, required this.room,
  });
}

class ISECTNewsItem {
  final String title;
  final String body;
  final String date;
  final String emoji;

  const ISECTNewsItem({
    required this.title, required this.body,
    required this.date, required this.emoji,
  });
}

class ISECTDataService {
  static const List<ISECTEdition> editions = [
    ISECTEdition(
      id: 'isect2025', year: 2025, flag: '🇪🇬',
      country: 'Egypt', city: 'Cairo',
      venue: 'Grand Egyptian Museum Congress Center',
      theme: 'Digital Heritage Preservation: Connecting Past and Future',
      dates: 'March 10–12, 2025',
      status: EditionStatus.past,
      attendees: 247, sessionCount: 34,
      description: 'The inaugural ISECT gathered leading experts from Egypt and Spain at the iconic Grand Egyptian Museum — setting the gold standard for Egyptian–Spanish cultural dialogue.',
      accentColor: Color(0xFFC8A44A),
    ),
    ISECTEdition(
      id: 'isect2026', year: 2026, flag: '🇪🇸',
      country: 'Spain', city: 'Granada',
      venue: 'Palacio de Congresos de Granada',
      theme: 'Shared Legacies, Shared Futures: Heritage as a Bridge',
      dates: 'June 15–17, 2026',
      status: EditionStatus.upcoming,
      sessionCount: 28,
      description: 'The second edition moves to breathtaking Granada — where Islamic, Roman and Andalusian heritage converge under the shadow of the Alhambra. Registration is now open.',
      accentColor: Color(0xFFB41E2D),
    ),
    ISECTEdition(
      id: 'isect2027', year: 2027, flag: '🇪🇬',
      country: 'Egypt', city: 'Luxor',
      venue: 'Luxor International Convention Center',
      theme: 'Innovation in Heritage Tourism: Technology Meets Tradition',
      dates: 'March 2027 · Dates TBA',
      status: EditionStatus.announced,
      description: 'ISECT returns to Egypt in the ancient capital Luxor — the world\'s greatest open-air museum. The third edition will focus on AR/VR and AI applications in archaeological heritage.',
      accentColor: Color(0xFFC8A44A),
    ),
  ];

  static const List<ISECTSpeaker> speakers = [
    ISECTSpeaker(
      name: 'Prof. Alejandro García Morales',
      title: 'Director of Heritage Studies',
      institution: 'Universidad de Granada',
      country: 'Spain', flag: '🇪🇸',
      bio: 'One of Europe\'s foremost authorities on Al-Andalus heritage and its connections with ancient Egyptian civilization. Author of 14 books on Mediterranean cultural exchange.',
      specialty: 'Andalusian–Egyptian Cultural Heritage',
      emoji: '🏛️',
    ),
    ISECTSpeaker(
      name: 'Dr. Yasmine Hassan',
      title: 'Chair of Digital Egyptology',
      institution: 'Cairo University',
      country: 'Egypt', flag: '🇪🇬',
      bio: 'Pioneer of digital documentation of Egyptian monuments. Led the 3D laser-scanning of over 200 sites in the Nile Valley and has partnered with Spanish universities on joint heritage digitization projects.',
      specialty: 'Digital Archaeology & Monument Documentation',
      emoji: '💻',
    ),
    ISECTSpeaker(
      name: 'Dr. Ricardo López Fernández',
      title: 'Director, World Heritage Division',
      institution: 'UNESCO, Paris',
      country: 'Spain', flag: '🇪🇸',
      bio: 'Oversees UNESCO\'s World Heritage programs across the Mediterranean and North Africa. Instrumental in the protection of both Egyptian and Andalusian UNESCO sites.',
      specialty: 'UNESCO Policy & World Heritage Law',
      emoji: '🌍',
    ),
    ISECTSpeaker(
      name: 'Prof. Nadia El-Sayyid',
      title: 'Chair of Archaeology',
      institution: 'American University in Cairo',
      country: 'Egypt', flag: '🇪🇬',
      bio: 'Specializes in community-based heritage preservation and has developed award-winning education programs connecting Egyptian youth with their ancient past through technology.',
      specialty: 'Community Heritage & Youth Engagement',
      emoji: '🎓',
    ),
    ISECTSpeaker(
      name: 'Dr. Cristina Vega Rodríguez',
      title: 'Director of Research',
      institution: 'Alhambra & Generalife Foundation',
      country: 'Spain', flag: '🇪🇸',
      bio: 'Leading expert on the Nasrid dynasty\'s artistic and architectural parallels with ancient Egypt. Has developed immersive AR tours of the Alhambra visited by millions.',
      specialty: 'Islamic Heritage & Immersive Technology',
      emoji: '🕌',
    ),
    ISECTSpeaker(
      name: 'H.E. Dr. Mohamed Selim',
      title: 'Deputy Minister of Tourism',
      institution: 'Egyptian Ministry of Tourism & Antiquities',
      country: 'Egypt', flag: '🇪🇬',
      bio: 'Leads Egypt\'s international tourism partnerships, including the Egypt–Spain Tourism Corridor initiative. Former director of the Grand Egyptian Museum project.',
      specialty: 'Heritage Tourism Policy & International Relations',
      emoji: '🤝',
    ),
    ISECTSpeaker(
      name: 'Prof. Carmen Torres Sánchez',
      title: 'Professor of Mediterranean Studies',
      institution: 'Universidad de Sevilla',
      country: 'Spain', flag: '🇪🇸',
      bio: 'Renowned scholar of ancient trade routes connecting the Iberian Peninsula with Egypt. Her research reveals how pharaonic aesthetic traditions influenced early Andalusian art.',
      specialty: 'Mediterranean Trade & Cultural Diffusion',
      emoji: '⛵',
    ),
    ISECTSpeaker(
      name: 'Dr. Ibrahim Fouad',
      title: 'Chief Curator',
      institution: 'Grand Egyptian Museum',
      country: 'Egypt', flag: '🇪🇬',
      bio: 'Oversees the largest collection of Egyptian antiquities in the world. Leading advocate for responsible international exhibition of Egyptian heritage and digital-first museum experiences.',
      specialty: 'Museum Curation & Heritage Exhibition',
      emoji: '🏺',
    ),
  ];

  static const List<ISECTSession> sessions = [
    // Day 1
    ISECTSession(
      title: 'Opening Ceremony & Welcome Address',
      speaker: 'ISECT Organizing Committee',
      time: '09:00 – 10:00',
      day: 'Day 1 · June 15',
      type: SessionType.ceremony,
      description: 'Official opening with welcome addresses from the Egyptian and Spanish co-presidents of ISECT, followed by a cultural performance.',
      room: 'Main Auditorium',
    ),
    ISECTSession(
      title: 'Keynote: Two Civilizations, One Heritage Vision',
      speaker: 'H.E. Dr. Mohamed Selim',
      time: '10:00 – 11:30',
      day: 'Day 1 · June 15',
      type: SessionType.keynote,
      description: 'The opening keynote explores the deep historical bonds between Egypt and Spain, from ancient Phoenician trade routes to modern cultural diplomacy, and the shared responsibility to preserve our common heritage.',
      room: 'Main Auditorium',
    ),
    ISECTSession(
      title: 'Egyptian Monuments in the Digital Era: From Papyrus to Pixels',
      speaker: 'Dr. Yasmine Hassan',
      time: '12:00 – 13:30',
      day: 'Day 1 · June 15',
      type: SessionType.session,
      description: 'How mobile AR, 3D scanning and AI are revolutionizing the documentation and visitor experience of Egyptian monuments. Live demonstration of AI monument recognition technology.',
      room: 'Hall A',
    ),
    ISECTSession(
      title: 'Al-Andalus and Pharaonic Egypt: Tracing Shared Aesthetic Heritage',
      speaker: 'Prof. Alejandro García Morales',
      time: '15:00 – 16:30',
      day: 'Day 1 · June 15',
      type: SessionType.session,
      description: 'A visual journey through the architectural and artistic parallels between Andalusian palaces and ancient Egyptian temple design — discovering the cultural bridges built over millennia.',
      room: 'Hall B',
    ),
    ISECTSession(
      title: 'Workshop: Hands-On AR/VR Applications in Heritage Sites',
      speaker: 'Dr. Cristina Vega Rodríguez',
      time: '17:00 – 18:30',
      day: 'Day 1 · June 15',
      type: SessionType.workshop,
      description: 'An interactive workshop where participants use AR devices to experience reconstructed versions of the Alhambra and Abu Simbel. No prior technical experience required.',
      room: 'Workshop Room 1',
    ),
    // Day 2
    ISECTSession(
      title: 'Keynote: Sustainable Tourism for World Heritage Sites',
      speaker: 'Dr. Ricardo López Fernández',
      time: '09:00 – 10:30',
      day: 'Day 2 · June 16',
      type: SessionType.keynote,
      description: 'UNESCO\'s framework for balancing tourist access with preservation of fragile heritage sites. Case studies from Luxor, Granada and Toledo.',
      room: 'Main Auditorium',
    ),
    ISECTSession(
      title: 'Community-Led Heritage Preservation: Lessons from the Nile Valley',
      speaker: 'Prof. Nadia El-Sayyid',
      time: '11:00 – 12:30',
      day: 'Day 2 · June 16',
      type: SessionType.session,
      description: 'How empowering local communities in Egypt\'s heritage villages creates sustainable tourism models while preserving living traditions. Replicable lessons for Spain\'s heritage towns.',
      room: 'Hall A',
    ),
    ISECTSession(
      title: 'Panel: The Future of Heritage Tourism 2026–2035',
      speaker: 'All keynote speakers',
      time: '15:00 – 16:30',
      day: 'Day 2 · June 16',
      type: SessionType.panel,
      description: 'An open panel discussion on the next decade of Egyptian-Spanish heritage tourism, featuring questions from the audience and live polling.',
      room: 'Main Auditorium',
    ),
    ISECTSession(
      title: 'Cultural Tour: Alhambra Palace & Generalife Gardens',
      speaker: 'Dr. Cristina Vega Rodríguez (guide)',
      time: '16:30 – 19:30',
      day: 'Day 2 · June 16',
      type: SessionType.tour,
      description: 'An exclusive guided tour of the Alhambra with special access to areas not open to the public. The tour will draw explicit parallels with Egyptian temple architecture.',
      room: 'Alhambra, Granada',
    ),
    // Day 3
    ISECTSession(
      title: 'Youth & Heritage: Digital Engagement Programmes',
      speaker: 'Prof. Nadia El-Sayyid & Prof. Carmen Torres Sánchez',
      time: '09:00 – 10:30',
      day: 'Day 3 · June 17',
      type: SessionType.session,
      description: 'Joint presentation on how Egypt and Spain are engaging younger generations with their ancient heritage through gamification, mobile apps and social media storytelling.',
      room: 'Hall B',
    ),
    ISECTSession(
      title: 'Egypt–Spain Tourism Exchange Programme: Official Launch',
      speaker: 'H.E. Dr. Mohamed Selim & Dr. Ricardo López Fernández',
      time: '11:00 – 12:00',
      day: 'Day 3 · June 17',
      type: SessionType.ceremony,
      description: 'The official signing and launch of the bilateral Egypt–Spain Heritage Tourism Exchange Programme, including visa facilitation and joint marketing campaigns.',
      room: 'Main Auditorium',
    ),
    ISECTSession(
      title: 'Mediterranean Trade Routes: Connecting Ancient Egypt and Iberia',
      speaker: 'Prof. Carmen Torres Sánchez',
      time: '12:00 – 13:30',
      day: 'Day 3 · June 17',
      type: SessionType.session,
      description: 'New archaeological evidence of ancient trade and cultural exchange between pharaonic Egypt and the Iberian Peninsula, challenging previous assumptions about ancient connectivity.',
      room: 'Hall A',
    ),
    ISECTSession(
      title: 'Closing Ceremony & ISECT 2027 Luxor Announcement',
      speaker: 'ISECT Organizing Committee',
      time: '16:00 – 17:30',
      day: 'Day 3 · June 17',
      type: SessionType.ceremony,
      description: 'Closing addresses, presentation of ISECT 2026 awards, and the official announcement and preview of ISECT 2027 in Luxor, Egypt.',
      room: 'Main Auditorium',
    ),
  ];

  static const List<ISECTNewsItem> news = [
    ISECTNewsItem(
      emoji: '📣',
      title: 'ISECT 2026 Registration Now Open',
      body: 'Early bird registration for ISECT 2026 Granada is now open. Secure your place at one of the most prestigious heritage conferences in the Mediterranean region.',
      date: 'May 1, 2026',
    ),
    ISECTNewsItem(
      emoji: '🏆',
      title: 'ISECT 2025 Cairo: Record Attendance',
      body: 'The inaugural ISECT in Cairo welcomed 247 delegates from 32 countries — exceeding all expectations and cementing the conference\'s status as a premier international forum.',
      date: 'March 15, 2025',
    ),
    ISECTNewsItem(
      emoji: '🤝',
      title: 'Egypt–Spain MOU on Heritage Tourism Signed',
      body: 'Egypt and Spain have signed a landmark Memorandum of Understanding on joint heritage tourism development, facilitated by the ISECT network.',
      date: 'April 10, 2026',
    ),
    ISECTNewsItem(
      emoji: '🏛️',
      title: 'New AR Tour of the Alhambra Launched',
      body: 'The Alhambra Foundation launches an AR-powered mobile tour drawing explicit parallels with Egyptian temple architecture — a direct outcome of ISECT 2025 collaborations.',
      date: 'February 20, 2026',
    ),
  ];

  static ISECTEdition get nextEdition =>
      editions.firstWhere((e) => e.status == EditionStatus.upcoming,
          orElse: () => editions.last);

  static List<ISECTSession> sessionsForDay(String day) =>
      sessions.where((s) => s.day.startsWith(day)).toList();

  static List<String> get sessionDays =>
      sessions.map((s) => s.day).toSet().toList();
}

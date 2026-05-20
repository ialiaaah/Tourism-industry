import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../tourist/ar_monument_scanner_screen.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});
  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> with SingleTickerProviderStateMixin {
  static const _navy = Color(0xFF0B1E35);
  static const _gold = Color(0xFFCBA153);

  late TabController _tabs;

  // Monument images tied to conference narrative
  static const _highlights2025 = [
    _GalleryItem('sphinx', 'EGY', 'The Great Sphinx', 'Iconic opening tour during ISECT 2025 Cairo'),
    _GalleryItem('tutankhamun_mask', 'EGY', 'Tutankhamun\'s Mask', 'Featured in the Digital Heritage Keynote, ISECT 2025'),
    _GalleryItem('nefertiti', 'EGY', 'Nefertiti Bust', 'Subject of the Egypt-Germany heritage repatriation panel'),
    _GalleryItem('great_temple_ramesses', 'EGY', 'Abu Simbel', 'Field trip to Abu Simbel during ISECT 2025'),
    _GalleryItem('temple_isis_philae', 'EGY', 'Temple of Isis, Philae', 'UNESCO rescue operation case study, ISECT 2025'),
    _GalleryItem('khafre_pyramid', 'EGY', 'Pyramid of Khafre', 'Giza plateau tour for international delegates'),
  ];

  static const _highlights2026 = [
    _GalleryItem('hatshepsut', 'EGY', 'Queen Hatshepsut', 'Keynote: "Women Who Shaped History" — ISECT 2026'),
    _GalleryItem('akhenaten', 'EGY', 'Akhenaten', 'Monotheism & the Mediterranean — comparative religion session'),
    _GalleryItem('temple_kom_ombo', 'EGY', 'Temple of Kom Ombo', 'Example of dual-god architecture in the AR workshop'),
    _GalleryItem('bent_pyramid', 'EGY', 'Bent Pyramid', 'Structural evolution of pyramids — engineering session'),
    _GalleryItem('colossi_memnon', 'EGY', 'Colossi of Memnon', 'Acoustic heritage — the "singing" statues panel'),
    _GalleryItem('sphinx', 'EGY', 'The Sphinx', 'Comparative iconography: Sphinx & Andalusian Lion motifs'),
  ];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _navy,
      appBar: AppBar(
        backgroundColor: _navy, foregroundColor: Colors.white, elevation: 0,
        title: Text('Gallery', style: GoogleFonts.playfairDisplay(color: _gold, fontSize: 20, fontWeight: FontWeight.bold)),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFF132038), borderRadius: BorderRadius.circular(12)),
            child: TabBar(
              controller: _tabs,
              indicator: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFCBA153), Color(0xFFE8C97A)]),
                  borderRadius: BorderRadius.circular(10)),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: const Color(0xFF0B1E35),
              unselectedLabelColor: Colors.white38,
              labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
              tabs: const [Tab(text: 'Egypt  ·  Cairo 2025'), Tab(text: 'Spain  ·  Granada 2026')],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_enhance_rounded, color: Color(0xFFCBA153)),
            tooltip: 'Heritage Scanner',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ARMonumentScannerScreen())),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _GalleryGrid(items: _highlights2025),
          _GalleryGrid(items: _highlights2026),
        ],
      ),
    );
  }
}

class _GalleryGrid extends StatelessWidget {
  final List<_GalleryItem> items;
  const _GalleryGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.78),
      itemCount: items.length,
      itemBuilder: (_, i) => _GalleryTile(item: items[i]),
    );
  }
}

class _GalleryTile extends StatelessWidget {
  final _GalleryItem item;
  const _GalleryTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDetail(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset('assets/monuments/${item.id}.jpg', fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: const Color(0xFF132038),
                    child: Center(child: Text(item.flag, style: const TextStyle(fontSize: 40))))),
            // Gradient overlay
            Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, Colors.black.withValues(alpha: 0.80)],
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
              ),
            ))),
            Positioned(
              bottom: 10, left: 10, right: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(item.caption, style: GoogleFonts.inter(color: Colors.white60, fontSize: 9, height: 1.3),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Image.asset('assets/monuments/${item.id}.jpg', fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(height: 300, color: const Color(0xFF132038),
                      child: Center(child: Text(item.flag, style: const TextStyle(fontSize: 60))))),
              Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.85)],
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                ),
              ))),
              Positioned(
                bottom: 20, left: 20, right: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name, style: GoogleFonts.playfairDisplay(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(item.caption, style: GoogleFonts.inter(color: Colors.white70, fontSize: 12, height: 1.4)),
                  ],
                ),
              ),
              Positioned(
                top: 10, right: 10,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                    child: const Icon(Icons.close, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GalleryItem {
  final String id;
  final String flag;
  final String name;
  final String caption;
  const _GalleryItem(this.id, this.flag, this.name, this.caption);
}

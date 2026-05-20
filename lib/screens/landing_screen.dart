import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import 'heritage_home_screen.dart';
import 'auth/signup_screen.dart';

// ── Theme constants ──────────────────────────────────────────────────────────
const kObsidian   = Color(0xFF1E1308);   // warm dark bg — noticeably lighter
const kDarkCard   = Color(0xFF2E1E0C);   // card — clearly contrast with bg
const kDark3      = Color(0xFF3E2E1A);   // hover / secondary card
const kGold       = Color(0xFFDFAF58);   // bright Egyptian gold
const kGoldLight  = Color(0xFFF0CC7A);   // light gold highlight
const kTerracotta = Color(0xFFD4581E);   // vivid terracotta
const kLapis      = Color(0xFF3A6499);   // lapis lazuli blue
const kSand       = Color(0xFFE0C896);   // warm sand
const kCream      = Color(0xFFF5EDD8);   // bright papyrus cream

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});
  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with SingleTickerProviderStateMixin {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _pwCtrl    = TextEditingController();
  bool _obscurePw  = true;
  String? _error;
  UserRole _role   = UserRole.tourist;
  bool _loading    = false;

  late AnimationController _fadeCtrl;
  late Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _emailCtrl.dispose();
    _pwCtrl.dispose();
    super.dispose();
  }

  void _toHome() {
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HeritageHomeScreen()), (_) => false);
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _error = null; _loading = true; });
    try {
      await Provider.of<AuthService>(context, listen: false).signInWithEmail(
        email: _emailCtrl.text.trim(),
        password: _pwCtrl.text,
        roleOverride: _role,
      );
      if (mounted) _toHome();
    } catch (e) {
      setState(() => _error = _clean(e.toString()));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _googleSignIn() async {
    setState(() { _error = null; _loading = true; });
    try {
      final u = await Provider.of<AuthService>(context, listen: false)
          .signInWithGoogle(roleOverride: _role);
      if (u != null && mounted) _toHome();
    } catch (e) {
      setState(() => _error = _clean(e.toString()));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _clean(String raw) {
    final b = raw.indexOf(']');
    return b != -1 && b + 2 < raw.length
        ? raw.substring(b + 2).trim()
        : raw.replaceAll('Exception: ', '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kObsidian,
      body: Stack(
        children: [
          // ── Faint pyramid background silhouette ──────────────────────────
          Positioned.fill(child: CustomPaint(painter: _BgPainter())),

          // ── Content ──────────────────────────────────────────────────────
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 26),
                child: Column(
                  children: [
                    const SizedBox(height: 36),

                    // ── Logo ───────────────────────────────────────────────
                    const CulturaXLogoWidget(size: 72),
                    const SizedBox(height: 14),
                    Text('CulturaX',
                        style: GoogleFonts.playfairDisplay(
                            color: kGold, fontSize: 42, fontWeight: FontWeight.bold,
                            letterSpacing: 2)),
                    const SizedBox(height: 6),
                    Text(
                      'A Smart Cultural Ecosystem Connecting\nHeritage, Tourism, and Global Conferences',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(color: kSand.withValues(alpha: 0.6), fontSize: 11, height: 1.6),
                    ),
                    const SizedBox(height: 32),

                    // ── Decorative divider ─────────────────────────────────
                    _Divider(),
                    const SizedBox(height: 28),

                    // ── Error ──────────────────────────────────────────────
                    if (_error != null) ErrorBanner(message: _error!),

                    // ── Role selector ──────────────────────────────────────
                    _RoleLabel(),
                    const SizedBox(height: 10),
                    _RoleRow(selected: _role, onChanged: (r) => setState(() => _role = r)),
                    const SizedBox(height: 22),

                    // ── Login form ─────────────────────────────────────────
                    _FormCard(
                      formKey: _formKey,
                      emailCtrl: _emailCtrl,
                      pwCtrl: _pwCtrl,
                      obscurePw: _obscurePw,
                      onToggleObscure: () => setState(() => _obscurePw = !_obscurePw),
                      loading: _loading,
                      onSignIn: _signIn,
                    ),
                    const SizedBox(height: 18),

                    // ── Or divider ─────────────────────────────────────────
                    const OrDivider(),
                    const SizedBox(height: 18),

                    // ── Google button ──────────────────────────────────────
                    _GoogleButton(loading: _loading, onTap: _googleSignIn),
                    const SizedBox(height: 20),

                    // ── Sign-up link ───────────────────────────────────────
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text("Don't have an account?",
                          style: GoogleFonts.inter(color: Colors.white38, fontSize: 13)),
                      TextButton(
                        onPressed: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const SignupScreen())),
                        child: Text('Register', style: GoogleFonts.inter(
                            color: kGold, fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ]),
                    const SizedBox(height: 10),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Logo widget ──────────────────────────────────────────────────────────────

class CulturaXLogoWidget extends StatelessWidget {
  final double size;
  const CulturaXLogoWidget({super.key, this.size = 60});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.22),
        color: kDarkCard,
        border: Border.all(color: kGold.withValues(alpha: 0.55), width: 1.5),
        boxShadow: [BoxShadow(color: kGold.withValues(alpha: 0.15), blurRadius: 20, spreadRadius: 2)],
      ),
      child: CustomPaint(painter: _LogoPainter()),
    );
  }
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Gold fill
    final fill = Paint()..color = kGold..style = PaintingStyle.fill..isAntiAlias = true;
    // Dark fill (for doorway cutout)
    final dark = Paint()..color = kDarkCard..style = PaintingStyle.fill..isAntiAlias = true;
    // Stroke
    final stroke = Paint()
      ..color = kGoldLight..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.035..isAntiAlias = true;

    // Sun circle
    canvas.drawCircle(Offset(w / 2, h * 0.21), w * 0.1, fill);
    // Sun rays (4 small lines)
    for (var angle in [0.0, 90.0, 180.0, 270.0]) {
      final rad = angle * 3.14159 / 180;
      final cx = w / 2 + (w * 0.16) * (angle == 90 || angle == 270 ? 0 : (angle == 0 ? 1 : -1));
      final cy = h * 0.21 + (h * 0.12) * (angle == 0 || angle == 180 ? 0 : (angle == 90 ? 1 : -1));
      final sx = w / 2 + (w * 0.12) * (angle == 90 || angle == 270 ? 0 : (angle == 0 ? 1 : -1));
      final sy = h * 0.21 + (h * 0.09) * (angle == 0 || angle == 180 ? 0 : (angle == 90 ? 1 : -1));
      final _ = rad; // keep angle in scope
      canvas.drawLine(Offset(sx, sy), Offset(cx, cy),
          Paint()..color = kGold..strokeWidth = w * 0.025..isAntiAlias = true);
    }

    // Pyramid body
    final pyramid = Path()
      ..moveTo(w / 2, h * 0.33)
      ..lineTo(w * 0.1, h * 0.84)
      ..lineTo(w * 0.9, h * 0.84)
      ..close();

    // Gradient shader for pyramid
    final grad = Paint()
      ..shader = LinearGradient(
        colors: [kGoldLight, kGold],
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill..isAntiAlias = true;

    canvas.drawPath(pyramid, grad);

    // Dark doorway/entrance
    final door = Path()
      ..moveTo(w / 2, h * 0.6)
      ..lineTo(w * 0.44, h * 0.84)
      ..lineTo(w * 0.56, h * 0.84)
      ..close();
    canvas.drawPath(door, dark);

    // Base line (Nile)
    canvas.drawLine(Offset(w * 0.05, h * 0.88), Offset(w * 0.95, h * 0.88), stroke);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: Container(height: 1, decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Colors.transparent, kGold.withValues(alpha: 0.4)])))),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Container(width: 6, height: 6,
            decoration: BoxDecoration(color: kGold.withValues(alpha: 0.6), shape: BoxShape.circle)),
      ),
      Expanded(child: Container(height: 1, decoration: BoxDecoration(
          gradient: LinearGradient(colors: [kGold.withValues(alpha: 0.4), Colors.transparent])))),
    ]);
  }
}

class OrDivider extends StatelessWidget {
  const OrDivider({super.key});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.1))),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Text('or', style: GoogleFonts.inter(color: Colors.white24, fontSize: 12)),
      ),
      Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.1))),
    ]);
  }
}

class _RoleLabel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 3, height: 14, color: kGold),
      const SizedBox(width: 8),
      Text('I am a...', style: GoogleFonts.inter(
          color: kSand, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
    ]);
  }
}

class _RoleRow extends StatelessWidget {
  final UserRole selected;
  final ValueChanged<UserRole> onChanged;
  const _RoleRow({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      _RoleCard(
        icon: Icons.explore_rounded, label: 'Tourist',
        sub: 'Explore heritage & join tours',
        role: UserRole.tourist, selected: selected, color: kTerracotta,
        onTap: () => onChanged(UserRole.tourist),
      ),
      const SizedBox(width: 10),
      _RoleCard(
        icon: Icons.tour_rounded, label: 'Tour Guide',
        sub: 'Create & manage heritage routes',
        role: UserRole.guide, selected: selected, color: kGold,
        onTap: () => onChanged(UserRole.guide),
      ),
    ]);
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final UserRole role;
  final UserRole selected;
  final Color color;
  final VoidCallback onTap;
  const _RoleCard({required this.icon, required this.label, required this.sub,
      required this.role, required this.selected, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == role;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.12) : kDarkCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? color.withValues(alpha: 0.7) : Colors.white.withValues(alpha: 0.07),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, color: isSelected ? color : Colors.white24, size: 22),
            const SizedBox(height: 8),
            Text(label, style: GoogleFonts.inter(
                color: isSelected ? color : Colors.white60,
                fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 3),
            Text(sub, style: GoogleFonts.inter(
                color: isSelected ? color.withValues(alpha: 0.7) : Colors.white24,
                fontSize: 10, height: 1.4)),
          ]),
        ),
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final TextEditingController pwCtrl;
  final bool obscurePw;
  final VoidCallback onToggleObscure;
  final bool loading;
  final VoidCallback onSignIn;

  const _FormCard({
    required this.formKey, required this.emailCtrl, required this.pwCtrl,
    required this.obscurePw, required this.onToggleObscure,
    required this.loading, required this.onSignIn,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kDarkCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kGold.withValues(alpha: 0.35)),
      ),
      child: Form(
        key: formKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          AncientField(controller: emailCtrl, label: 'Email', icon: Icons.email_outlined,
              type: TextInputType.emailAddress,
              validator: (v) => v == null || v.isEmpty ? 'Enter your email'
                  : !v.contains('@') ? 'Enter a valid email' : null),
          const SizedBox(height: 12),
          AncientField(
            controller: pwCtrl, label: 'Password', icon: Icons.lock_outline,
            obscure: obscurePw,
            suffix: IconButton(
              icon: Icon(obscurePw ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white24, size: 18),
              onPressed: onToggleObscure,
            ),
            validator: (v) => v == null || v.isEmpty ? 'Enter your password' : null,
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 50,
            child: loading
                ? const Center(child: CircularProgressIndicator(color: kGold))
                : ElevatedButton(
                    onPressed: onSignIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kGold, foregroundColor: kObsidian,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text('Sign In', style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
          ),
        ]),
      ),
    );
  }
}

class _GoogleButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;
  const _GoogleButton({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity, height: 50,
      child: OutlinedButton.icon(
        icon: Image.network(
          'https://developers.google.com/identity/images/g-logo.png', height: 20,
          errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata, color: Colors.white, size: 24),
        ),
        label: Text('Continue with Google', style: GoogleFonts.inter(color: Colors.white70, fontSize: 14)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: loading ? null : onTap,
      ),
    );
  }
}

class ErrorBanner extends StatelessWidget {
  final String message;
  const ErrorBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.35)),
      ),
      child: Row(children: [
        const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(message, style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 12))),
      ]),
    );
  }
}


// ── Ancient field ────────────────────────────────────────────────────────────

class AncientField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscure;
  final TextInputType type;
  final Widget? suffix;
  final String? Function(String?)? validator;

  const AncientField({
    required this.controller, required this.label, required this.icon,
    this.obscure = false, this.type = TextInputType.text,
    this.suffix, this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller, obscureText: obscure, keyboardType: type,
      style: GoogleFonts.inter(color: kCream, fontSize: 14),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(color: Colors.white38, fontSize: 13),
        prefixIcon: Icon(icon, color: kGold, size: 18),
        suffixIcon: suffix,
        filled: true,
        fillColor: kObsidian.withValues(alpha: 0.8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(11),
            borderSide: BorderSide(color: kGold.withValues(alpha: 0.15))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(11),
            borderSide: BorderSide(color: kGold.withValues(alpha: 0.3))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(11),
            borderSide: const BorderSide(color: kGold)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(11),
            borderSide: const BorderSide(color: Colors.redAccent)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(11),
            borderSide: const BorderSide(color: Colors.redAccent)),
      ),
    );
  }
}

// ── Background painter ───────────────────────────────────────────────────────

class _BgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Very faint giant pyramid silhouette in background
    final paint = Paint()
      ..color = kGold.withValues(alpha: 0.025)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2, size.height * 0.05)
      ..lineTo(-size.width * 0.3, size.height)
      ..lineTo(size.width * 1.3, size.height)
      ..close();

    canvas.drawPath(path, paint);

    // Faint horizontal lines (hieroglyph grid effect)
    final linePaint = Paint()
      ..color = kGold.withValues(alpha: 0.03)
      ..strokeWidth = 1;

    for (int i = 0; i < 20; i++) {
      final y = (size.height / 20) * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

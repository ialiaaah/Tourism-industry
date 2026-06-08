import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../services/auth_service.dart';
import '../home_screen.dart';
import '../landing_screen.dart' show CulturaXLogoWidget, kObsidian, kDarkCard, kGold, kGoldLight,
    kLapis, kSand, kCream, AncientField, ErrorBanner, OrDivider;
import '../auth/signup_screen.dart';

class ConferenceScreen extends StatefulWidget {
  const ConferenceScreen({super.key});
  @override
  State<ConferenceScreen> createState() => _ConferenceScreenState();
}

class _ConferenceScreenState extends State<ConferenceScreen>
    with SingleTickerProviderStateMixin {
  static const _spainRed = Color(0xFFB41E2D);

  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _pwCtrl    = TextEditingController();
  bool _obscurePw  = true;
  String? _error;
  UserRole _role   = UserRole.tourist; // tourist = Attendee, guide = Organizer
  bool _loading    = false;

  late AnimationController _fadeCtrl;
  late Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose(); _emailCtrl.dispose(); _pwCtrl.dispose();
    super.dispose();
  }

  void _toHome() => Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false);

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _error = null; _loading = true; });
    try {
      await Provider.of<AuthService>(context, listen: false).signInWithEmail(
        email: _emailCtrl.text.trim(), password: _pwCtrl.text, roleOverride: _role);
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
          // Lapis-tinted background overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kLapis.withValues(alpha: 0.08), Colors.transparent],
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 26),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // ── Back + Header ──────────────────────────────────────
                    Row(children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white38, size: 18),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                          Text('ISECT Conference', style: GoogleFonts.playfairDisplay(
                              color: kGold, fontSize: 20, fontWeight: FontWeight.bold)),
                          Text('2025 Cairo · 2026 Granada · 2027 Luxor',
                              style: GoogleFonts.inter(color: Colors.white24, fontSize: 10)),
                        ]),
                      ),
                      const SizedBox(width: 40),
                    ]),
                    const SizedBox(height: 20),

                    // ── CulturaX logo ──────────────────────────────────────
                    const CulturaXLogoWidget(size: 56),
                    const SizedBox(height: 10),
                    // ── Flag icons → Material icons ────────────────────────
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.account_balance_rounded, color: kGold.withValues(alpha: 0.7), size: 18),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text('·', style: TextStyle(color: Colors.white24, fontSize: 20)),
                      ),
                      Icon(Icons.account_balance_rounded, color: const Color(0xFFB41E2D).withValues(alpha: 0.7), size: 18),
                    ]),
                    const SizedBox(height: 6),
                    Text('International Spanish-Egyptian\nConference on Tourism & Heritage',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(color: Colors.white38, fontSize: 11, height: 1.5)),
                    const SizedBox(height: 28),

                    // ── Error ──────────────────────────────────────────────
                    if (_error != null) ErrorBanner(message: _error!),

                    // ── Role selector ──────────────────────────────────────
                    Row(children: [
                      Container(width: 3, height: 14, color: kGold),
                      const SizedBox(width: 8),
                      Text('I am a...', style: GoogleFonts.inter(
                          color: kSand, fontSize: 12, fontWeight: FontWeight.w600)),
                    ]),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: kDarkCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
                      ),
                      child: Row(children: [
                        _confRoleTab('Attendee', Icons.badge_rounded, UserRole.tourist, kGold),
                        _confRoleTab('Organizer', Icons.manage_accounts_rounded, UserRole.guide, _spainRed),
                      ]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _role == UserRole.tourist
                          ? 'Conference attendee, researcher, or global follower'
                          : 'ISECT organizing committee or conference staff',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(color: Colors.white24, fontSize: 11),
                    ),
                    const SizedBox(height: 22),

                    // ── Login form ─────────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: kDarkCard,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: kGold.withValues(alpha: 0.1)),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                          AncientField(
                            controller: _emailCtrl, label: 'Email', icon: Icons.email_outlined,
                            type: TextInputType.emailAddress,
                            validator: (v) => v == null || v.isEmpty ? 'Enter your email'
                                : !v.contains('@') ? 'Enter a valid email' : null,
                          ),
                          const SizedBox(height: 12),
                          AncientField(
                            controller: _pwCtrl, label: 'Password', icon: Icons.lock_outline,
                            obscure: _obscurePw,
                            suffix: IconButton(
                              icon: Icon(_obscurePw ? Icons.visibility_off : Icons.visibility,
                                  color: Colors.white24, size: 18),
                              onPressed: () => setState(() => _obscurePw = !_obscurePw),
                            ),
                            validator: (v) => v == null || v.isEmpty ? 'Enter your password' : null,
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 50,
                            child: _loading
                                ? const Center(child: CircularProgressIndicator(color: kGold))
                                : ElevatedButton(
                                    onPressed: _signIn,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: kGold, foregroundColor: kObsidian,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: Text('Access Conference', style: GoogleFonts.inter(
                                        fontWeight: FontWeight.bold, fontSize: 16)),
                                  ),
                          ),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 18),

                    const OrDivider(),
                    const SizedBox(height: 18),

                    // ── Google ─────────────────────────────────────────────
                    SizedBox(
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
                        onPressed: _loading ? null : _googleSignIn,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Register link ──────────────────────────────────────
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text("Don't have a conference account?",
                          style: GoogleFonts.inter(color: Colors.white38, fontSize: 12)),
                      TextButton(
                        onPressed: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const SignupScreen())),
                        child: Text('Register', style: GoogleFonts.inter(
                            color: kGold, fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ]),

                    Text('© 2025–2027 CulturaX · Powered by ISECT',
                        style: GoogleFonts.inter(color: Colors.white24, fontSize: 9)),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _confRoleTab(String label, IconData icon, UserRole role, Color color) {
    final selected = _role == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _role = role),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 17, color: selected ? kObsidian : Colors.white38),
            const SizedBox(width: 6),
            Text(label, style: GoogleFonts.inter(
                fontWeight: FontWeight.w700, fontSize: 13,
                color: selected ? kObsidian : Colors.white38)),
          ]),
        ),
      ),
    );
  }
}

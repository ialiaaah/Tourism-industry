import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../models/models.dart';
import '../heritage_home_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  static const _navy = Color(0xFF0B1E35);
  static const _gold = Color(0xFFCBA153);
  static const _spainRed = Color(0xFFB41E2D);

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  UserRole _role = UserRole.tourist;
  bool _obscurePw = true;
  bool _obscureConfirm = true;
  String? _error;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _pwCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _toHome() => Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HeritageHomeScreen()), (_) => false);

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _error = null);
    try {
      await Provider.of<AuthService>(context, listen: false).signUpWithEmail(
        name: _nameCtrl.text, email: _emailCtrl.text,
        password: _pwCtrl.text, role: _role,
      );
      if (mounted) _toHome();
    } catch (e) {
      setState(() => _error = _clean(e.toString()));
    }
  }

  Future<void> _googleRegister() async {
    setState(() => _error = null);
    try {
      final u = await Provider.of<AuthService>(context, listen: false)
          .signInWithGoogle(roleOverride: _role);
      if (u != null && mounted) _toHome();
    } catch (e) {
      setState(() => _error = _clean(e.toString()));
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
    final auth = Provider.of<AuthService>(context);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF060E1A), Color(0xFF0B1E35), Color(0xFF132038)],
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                children: [
                  // ── CulturaX Logo ────────────────────────────────────────────────
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.account_balance_rounded, color: Color(0xFFDFAF58), size: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text('✕', style: GoogleFonts.inter(color: Colors.white24, fontSize: 14)),
                    ),
                    const Icon(Icons.account_balance_rounded, color: Color(0xFFB41E2D), size: 20),
                  ]),
                  const SizedBox(height: 8),
                  Text('CulturaX',
                      style: GoogleFonts.playfairDisplay(
                          color: _gold, fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: 3)),
                  const SizedBox(height: 6),
                  Text('Create your CulturaX account',
                      style: GoogleFonts.inter(color: Colors.white54, fontSize: 13)),
                  const SizedBox(height: 28),

                  // ── Error ─────────────────────────────────────────────────────
                  if (_error != null)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 12))),
                      ]),
                    ),

                  // ── Role Picker ───────────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
                    ),
                    child: Row(children: [
                    _roleTab('Tourist', Icons.explore_rounded, UserRole.tourist),
                    _roleTab('Tour Guide', Icons.tour_rounded, UserRole.guide),
                    ]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _role == UserRole.tourist
                        ? 'Explore heritage sites and join guided tours'
                        : 'Create and manage heritage tour routes',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(color: Colors.white38, fontSize: 11),
                  ),
                  const SizedBox(height: 20),

                  // ── Form ──────────────────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        _field(controller: _nameCtrl, label: 'Full Name', icon: Icons.person_outline,
                            validator: (v) => v == null || v.isEmpty ? 'Enter your name' : null),
                        const SizedBox(height: 12),
                        _field(controller: _emailCtrl, label: 'Email', icon: Icons.email_outlined,
                            type: TextInputType.emailAddress,
                            validator: (v) => v == null || v.isEmpty ? 'Enter your email'
                                : !v.contains('@') ? 'Enter a valid email' : null),
                        const SizedBox(height: 12),
                        _field(
                          controller: _pwCtrl, label: 'Password', icon: Icons.lock_outline,
                          obscure: _obscurePw,
                          suffix: IconButton(
                            icon: Icon(_obscurePw ? Icons.visibility_off : Icons.visibility, color: Colors.white38, size: 18),
                            onPressed: () => setState(() => _obscurePw = !_obscurePw),
                          ),
                          validator: (v) => v == null || v.length < 6 ? 'Minimum 6 characters' : null,
                        ),
                        const SizedBox(height: 12),
                        _field(
                          controller: _confirmCtrl, label: 'Confirm Password', icon: Icons.lock_outline,
                          obscure: _obscureConfirm,
                          suffix: IconButton(
                            icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility, color: Colors.white38, size: 18),
                            onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                          ),
                          validator: (v) => v != _pwCtrl.text ? 'Passwords do not match' : null,
                        ),
                        const SizedBox(height: 22),
                        SizedBox(
                          height: 50,
                          child: auth.isLoading
                              ? const Center(child: CircularProgressIndicator(color: Color(0xFFCBA153)))
                              : ElevatedButton(
                                  onPressed: _register,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _gold, foregroundColor: _navy,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                                  ),
                                  child: Text('Create Account',
                                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15)),
                                ),
                        ),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Or ────────────────────────────────────────────────────────
                  Row(children: [
                    Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.15))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text('or', style: GoogleFonts.inter(color: Colors.white38, fontSize: 12)),
                    ),
                    Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.15))),
                  ]),
                  const SizedBox(height: 16),

                  // ── Google ────────────────────────────────────────────────────
                  SizedBox(
                    width: double.infinity, height: 50,
                    child: OutlinedButton.icon(
                      icon: Image.network(
                        'https://developers.google.com/identity/images/g-logo.png',
                        height: 20,
                        errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata, color: Colors.white, size: 24),
                      ),
                      label: Text('Register with Google', style: GoogleFonts.inter(color: Colors.white, fontSize: 14)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                      ),
                      onPressed: auth.isLoading ? null : _googleRegister,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Back to login ─────────────────────────────────────────────
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('Already have an account?', style: GoogleFonts.inter(color: Colors.white54, fontSize: 13)),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Sign In', style: GoogleFonts.inter(color: _gold, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ]),

                  Text('© 2025–2027 CulturaX · All rights reserved',
                      style: GoogleFonts.inter(color: Colors.white24, fontSize: 9)),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _roleTab(String label, IconData icon, UserRole role) {
    final selected = _role == role;
    final color = role == UserRole.guide ? _spainRed : _gold;
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
            Icon(icon, size: 17, color: selected ? _navy : Colors.white38),
            const SizedBox(width: 6),
            Text(label, style: GoogleFonts.inter(
                fontWeight: FontWeight.w700, fontSize: 13,
                color: selected ? _navy : Colors.white38)),
          ]),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    TextInputType type = TextInputType.text,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller, obscureText: obscure, keyboardType: type,
      style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.55), fontSize: 13),
        prefixIcon: Icon(icon, color: _gold, size: 18),
        suffixIcon: suffix, filled: true,
        fillColor: Colors.white.withValues(alpha: 0.04),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(11),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(11),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(11),
            borderSide: const BorderSide(color: _gold)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(11),
            borderSide: const BorderSide(color: Colors.redAccent)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(11),
            borderSide: const BorderSide(color: Colors.redAccent)),
      ),
    );
  }
}

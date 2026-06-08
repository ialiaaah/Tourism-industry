import 'package:flutter/material.dart';

/// CulturaX unified color palette — heritage-inspired modern design.
class AppColors {
  AppColors._();

  // ── Primary surfaces ──────────────────────────────────────────────────────
  static const Color bg          = Color(0xFF1E1308); // deep obsidian/sandstone
  static const Color surface     = Color(0xFF2E1E0C); // dark warm card
  static const Color surfaceAlt  = Color(0xFF3A2410); // slightly lighter card

  // ── Accents ───────────────────────────────────────────────────────────────
  static const Color gold        = Color(0xFFDFAF58); // warm Egyptian gold
  static const Color goldLight   = Color(0xFFF0CB7A); // lighter gold highlight
  static const Color terra       = Color(0xFFD4581E); // terracotta accent
  static const Color terraLight  = Color(0xFFE07040); // lighter terracotta

  // ── Text & foreground ─────────────────────────────────────────────────────
  static const Color cream       = Color(0xFFF5EDD8); // off-white / cream text
  static const Color sand        = Color(0xFFE0C896); // muted sand text
  static const Color muted       = Color(0xFF8A7560); // muted secondary text
  static const Color hint        = Color(0xFF5A4A38); // hint / placeholder

  // ── Feedback ──────────────────────────────────────────────────────────────
  static const Color success     = Color(0xFF4CD87A); // green success
  static const Color error       = Color(0xFFEF5350); // red error
  static const Color warning     = Color(0xFFFFB74D); // amber warning

  // ── Scanner / AR ─────────────────────────────────────────────────────────
  static const Color scanDark    = Color(0xFF0D1420); // scanner background
  static const Color hotspot     = Color(0xFF00E5FF); // AR hotspot cyan

  // ── Dividers & borders ────────────────────────────────────────────────────
  static const Color divider     = Color(0xFF3A2A18); // subtle divider
  static const Color border      = Color(0xFF4A3520); // card border
}

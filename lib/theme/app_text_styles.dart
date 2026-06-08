import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// CulturaX unified typography.
class AppTextStyles {
  AppTextStyles._();

  // ── Display / Hero ────────────────────────────────────────────────────────
  static TextStyle get display => GoogleFonts.playfairDisplay(
        fontSize: 32, fontWeight: FontWeight.bold,
        color: AppColors.cream, height: 1.2);

  static TextStyle get heroTitle => GoogleFonts.playfairDisplay(
        fontSize: 24, fontWeight: FontWeight.bold,
        color: AppColors.cream, height: 1.2);

  // ── Headings ──────────────────────────────────────────────────────────────
  static TextStyle get h1 => GoogleFonts.playfairDisplay(
        fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.cream);

  static TextStyle get h2 => GoogleFonts.playfairDisplay(
        fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.cream);

  static TextStyle get h3 => GoogleFonts.inter(
        fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.cream);

  // ── Body ──────────────────────────────────────────────────────────────────
  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 15, color: AppColors.sand, height: 1.5);

  static TextStyle get body => GoogleFonts.inter(
        fontSize: 13, color: AppColors.sand, height: 1.5);

  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 11, color: AppColors.muted, height: 1.4);

  // ── Labels ────────────────────────────────────────────────────────────────
  static TextStyle get label => GoogleFonts.inter(
        fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.cream);

  static TextStyle get labelSmall => GoogleFonts.inter(
        fontSize: 10, fontWeight: FontWeight.w600,
        color: AppColors.muted, letterSpacing: 0.8);

  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 11, color: AppColors.muted);

  // ── Button ────────────────────────────────────────────────────────────────
  static TextStyle get button => GoogleFonts.inter(
        fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.bg);

  static TextStyle get buttonOutline => GoogleFonts.inter(
        fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.gold);

  // ── Gold accent ───────────────────────────────────────────────────────────
  static TextStyle get goldTitle => GoogleFonts.playfairDisplay(
        fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.gold);

  static TextStyle get goldLabel => GoogleFonts.inter(
        fontSize: 12, fontWeight: FontWeight.bold,
        color: AppColors.gold, letterSpacing: 1.0);

  // ── Badge / tag ───────────────────────────────────────────────────────────
  static TextStyle get badge => GoogleFonts.inter(
        fontSize: 9, fontWeight: FontWeight.bold,
        color: AppColors.gold, letterSpacing: 1.2);
}

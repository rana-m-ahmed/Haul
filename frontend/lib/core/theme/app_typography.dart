import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  static const String _syne = 'Syne';
  static const String _inter = 'Inter';

  static TextStyle displayXL = GoogleFonts.getFont(_syne, fontSize: 32, fontWeight: FontWeight.w800, height: 1.2);
  static TextStyle displayLG = GoogleFonts.getFont(_syne, fontSize: 26, fontWeight: FontWeight.w800);
  static TextStyle displayMD = GoogleFonts.getFont(_syne, fontSize: 22, fontWeight: FontWeight.w700);
  static TextStyle displaySM = GoogleFonts.getFont(_syne, fontSize: 18, fontWeight: FontWeight.w700);
  static TextStyle titleLG = GoogleFonts.getFont(_syne, fontSize: 16, fontWeight: FontWeight.w600);
  static TextStyle titleMD = GoogleFonts.getFont(_syne, fontSize: 14, fontWeight: FontWeight.w600);
  static TextStyle titleSM = GoogleFonts.getFont(_syne, fontSize: 12, fontWeight: FontWeight.w600);
  static TextStyle bodyLG = GoogleFonts.getFont(_inter, fontSize: 15, fontWeight: FontWeight.w400);
  static TextStyle bodyMD = GoogleFonts.getFont(_inter, fontSize: 13, fontWeight: FontWeight.w400);
  static TextStyle bodySM = GoogleFonts.getFont(_inter, fontSize: 12, fontWeight: FontWeight.w400);
  static TextStyle labelLG = GoogleFonts.getFont(_syne, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.06, textBaseline: TextBaseline.alphabetic);
  static TextStyle labelMD = GoogleFonts.getFont(_syne, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.1);
  static TextStyle labelSM = GoogleFonts.getFont(_syne, fontSize: 9, fontWeight: FontWeight.w600);
  static TextStyle monoMD = GoogleFonts.getFont(_inter, fontSize: 12, fontWeight: FontWeight.w500);
  static TextStyle monoSM = GoogleFonts.getFont(_inter, fontSize: 11, fontWeight: FontWeight.w400);
}

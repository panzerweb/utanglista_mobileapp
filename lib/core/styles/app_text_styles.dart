import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/*
  DEFINED THE TEXT STYLES

  To use with colors:

  style: AppTextStyles.displayLarge.copyWith(
    color: Colors.white,
  )

  Font Family Chosen:

  Poppins: Headings, Product Titles
  Inter: Body, Prices, Buttons
*/

class AppTextStyles {
  AppTextStyles._();

  // ===========================
  // Headline - 28
  // ===========================

  static TextStyle heading1 = GoogleFonts.poppins(
    textStyle: TextStyle(fontSize: 28, height: 1.2),
  );

  // ===========================
  // Title - 22
  // ===========================
  static TextStyle title1 = GoogleFonts.poppins(
    textStyle: TextStyle(fontSize: 22, height: 1.2),
  );
  // ===========================
  // Subtitle - 18
  // ===========================
  static TextStyle subtitle1 = GoogleFonts.inter(
    textStyle: TextStyle(fontSize: 18, height: 1.2),
  );
  // ===========================
  // Body - 16
  // ===========================
  static TextStyle body1 = GoogleFonts.inter(
    textStyle: TextStyle(fontSize: 16, height: 1.2),
  );
  // ===========================
  // Caption - 13
  // ===========================
  static TextStyle caption1 = GoogleFonts.inter(
    textStyle: TextStyle(fontSize: 13, height: 1.2),
  );
}

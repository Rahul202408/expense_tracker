import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static final heading = GoogleFonts.poppins(
    fontSize: 30,
    fontWeight: FontWeight.bold,
    color: AppColors.black,
  );

  static final title = GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.black,
  );

  static final subtitle = GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: AppColors.black,
  );

  static final body = GoogleFonts.poppins(fontSize: 16, color: AppColors.grey);

  static final button = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static final small = GoogleFonts.poppins(fontSize: 13, color: AppColors.grey);
}

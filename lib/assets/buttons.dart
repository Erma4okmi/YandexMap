import 'package:flutter/material.dart';
import 'brand_colors.dart';

final ButtonStyle flatButtonStyle = TextButton.styleFrom(
  foregroundColor: Colors.white,
  backgroundColor: BrandColors.colorGreen,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(25)),
  ),
);
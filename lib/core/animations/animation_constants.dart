import 'package:flutter/material.dart';

class Anim {
  const Anim._();

  // Duraciones — regla Apple HIG: 150-300ms micro, ≤400ms complejo
  static const Duration micro = Duration(milliseconds: 180);
  static const Duration normal = Duration(milliseconds: 280);
  static const Duration page = Duration(milliseconds: 350);
  static const Duration celebration = Duration(milliseconds: 500);

  // Stagger — 50ms de diferencia entre cada item
  static const Duration stagger = Duration(milliseconds: 55);
  static const int staggerStart = 80; // ms antes del primer item

  // Curvas
  static const Curve enter = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;
  static const Curve spring = Curves.elasticOut; // bouncy natural
  static const Curve smooth = Curves.easeInOutCubic;

  // Escala de presión
  static const double pressScale = 0.96;

  // Shimmer
  static const Duration shimmerDuration = Duration(milliseconds: 1400);
  static const Color shimmerBase = Color(0xFFE8EEF4);
  static const Color shimmerHighlight = Color(0xFFF5F8FC);
}

import 'package:flutter/material.dart';
import 'package:adondeamos/core/animations/animation_constants.dart';

class SlideUpRoute<T> extends PageRouteBuilder<T> {
  SlideUpRoute({required this.builder, super.settings})
    : super(
        transitionDuration: Anim.page,
        reverseTransitionDuration: Anim.normal,
        pageBuilder: (context, animation, secondaryAnimation) =>
            builder(context),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Anim.enter,
            reverseCurve: Anim.exit,
          );
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.08),
              end: Offset.zero,
            ).animate(curved),
            child: FadeTransition(
              opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
                ),
              ),
              child: child,
            ),
          );
        },
      );

  final WidgetBuilder builder;
}

class FadeThroughRoute<T> extends PageRouteBuilder<T> {
  FadeThroughRoute({required this.builder, super.settings})
    : super(
        transitionDuration: const Duration(milliseconds: 250),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (context, animation, secondaryAnimation) =>
            builder(context),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ),
            child: child,
          );
        },
      );

  final WidgetBuilder builder;
}

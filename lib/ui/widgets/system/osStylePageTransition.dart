import 'package:flutter/material.dart';

class OsStylePageTransition<T> extends PageRouteBuilder<T> {
  final Widget page;

  OsStylePageTransition({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Elegant slide transition from right to left
            final slideTween = Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).chain(CurveTween(curve: Curves.easeInOutCubic));

            // Subtle scale transition
            final scaleTween = Tween<double>(
              begin: 0.98,
              end: 1.0,
            ).chain(CurveTween(curve: Curves.easeInOutCubic));

            // Fade transition
            final fadeTween = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).chain(CurveTween(curve: Curves.easeInOutCubic));

            return SlideTransition(
              position: animation.drive(slideTween),
              child: ScaleTransition(
                scale: animation.drive(scaleTween),
                child: FadeTransition(
                  opacity: animation.drive(fadeTween),
                  child: child,
                ),
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 380),
          reverseTransitionDuration: const Duration(milliseconds: 300),
        );
}

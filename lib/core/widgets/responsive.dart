import 'package:flutter/material.dart';

import '../constants/breakpoints.dart';

class Responsive extends StatelessWidget {
  const Responsive({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (Breakpoints.isDesktop(constraints.maxWidth)) return desktop;
        if (!Breakpoints.isMobile(constraints.maxWidth)) {
          return tablet ?? desktop;
        }
        return mobile;
      },
    );
  }
}

class PageWidth extends StatelessWidget {
  const PageWidth({super.key, required this.child, this.maxWidth = 1120});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

import 'package:flutter/widgets.dart';

/// Lucide glyphs from the `lucide_icons` font.
///
/// The published package subclasses [IconData]. Current Flutter marks that
/// class final, so these constants call the [IconData] constructor directly
/// and still load `fontPackage: lucide_icons`.
class AppIcons {
  const AppIcons._();

  static const _family = 'Lucide';
  static const _package = 'lucide_icons';

  static const arrowDown = IconData(
    0xf13c,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const arrowUp = IconData(
    0xf15b,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const calendar = IconData(
    0xf1d2,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const chevronLeft = IconData(
    0xf1f9,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const chevronRight = IconData(
    0xf1fb,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const clipboardList = IconData(
    0xf21c,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const edit3 = IconData(
    0xf292,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const fileText = IconData(
    0xf2d3,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const home = IconData(
    0xf35e,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const plus = IconData(
    0xf45e,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const search = IconData(
    0xf4ad,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const settings = IconData(
    0xf4b9,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const stethoscope = IconData(
    0xf505,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const trash2 = IconData(
    0xf546,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const user = IconData(
    0xf564,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const users = IconData(
    0xf574,
    fontFamily: _family,
    fontPackage: _package,
  );
}

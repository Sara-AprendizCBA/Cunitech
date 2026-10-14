import 'package:flutter/widgets.dart';

/// Breakpoints compartidos para los layouts responsive de la aplicación.
abstract final class ResponsiveBreakpoints {
  static const double mobile = 700;
  static const double desktop = 1100;
}

extension ResponsiveBuildContext on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;

  bool get isMobile => screenWidth < ResponsiveBreakpoints.mobile;

  bool get isTablet =>
      screenWidth >= ResponsiveBreakpoints.mobile &&
      screenWidth < ResponsiveBreakpoints.desktop;

  bool get isDesktop => screenWidth >= ResponsiveBreakpoints.desktop;

  double get adaptivePadding => isMobile ? 16 : (isTablet ? 24 : 32);

  double get adaptivePaddingH => adaptivePadding;
}

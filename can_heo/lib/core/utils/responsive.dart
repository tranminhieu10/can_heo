import 'package:flutter/material.dart';

/// Responsive utility class for auto-scaling UI based on screen size
/// Base design: 1920x1080 (Full HD)
class Responsive {
  static const double baseWidth = 1920.0;
  static const double baseHeight = 1080.0;

  static late MediaQueryData _mediaQueryData;
  static late double screenWidth;
  static late double screenHeight;
  static late double scaleWidth;
  static late double scaleHeight;
  static late double scaleFactor;
  static late double textScaleFactor;

  /// Initialize responsive values - call this in build method
  static void init(BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    screenWidth = _mediaQueryData.size.width;
    screenHeight = _mediaQueryData.size.height;

    // Calculate scale factors
    scaleWidth = screenWidth / baseWidth;
    scaleHeight = screenHeight / baseHeight;
    
    // Use the smaller scale to maintain aspect ratio
    scaleFactor = scaleWidth < scaleHeight ? scaleWidth : scaleHeight;
    
    // Text scale - slightly less aggressive scaling for readability
    textScaleFactor = scaleFactor.clamp(0.8, 1.2);
  }

  /// Scale width based on design width (1920px base)
  static double w(double width) {
    return width * scaleWidth;
  }

  /// Scale height based on design height (1080px base)
  static double h(double height) {
    return height * scaleHeight;
  }

  /// Scale based on smaller dimension (maintains aspect ratio)
  static double s(double size) {
    return size * scaleFactor;
  }

  /// Scale font size
  static double sp(double fontSize) {
    return fontSize * textScaleFactor;
  }

  /// Get screen type based on width
  static ScreenType get screenType {
    if (screenWidth >= 1920) return ScreenType.desktop27; // 27" or larger
    if (screenWidth >= 1600) return ScreenType.desktop24; // 24"
    if (screenWidth >= 1366) return ScreenType.laptop15;  // 15.6"
    if (screenWidth >= 1024) return ScreenType.laptop13;  // 13"
    return ScreenType.tablet;
  }

  /// Check if current screen is at least Full HD
  static bool get isFullHD => screenWidth >= 1920;

  /// Get adaptive padding based on screen size
  static EdgeInsets get screenPadding {
    switch (screenType) {
      case ScreenType.desktop27:
        return const EdgeInsets.all(24);
      case ScreenType.desktop24:
        return const EdgeInsets.all(16);
      case ScreenType.laptop15:
        return const EdgeInsets.all(12);
      case ScreenType.laptop13:
        return const EdgeInsets.all(8);
      case ScreenType.tablet:
        return const EdgeInsets.all(4);
    }
  }

  /// Get adaptive font size for body text
  static double get bodyFontSize {
    switch (screenType) {
      case ScreenType.desktop27:
        return 14;
      case ScreenType.desktop24:
        return 13;
      case ScreenType.laptop15:
        return 12;
      case ScreenType.laptop13:
        return 11;
      case ScreenType.tablet:
        return 10;
    }
  }

  /// Get adaptive font size for headers
  static double get headerFontSize {
    switch (screenType) {
      case ScreenType.desktop27:
        return 18;
      case ScreenType.desktop24:
        return 16;
      case ScreenType.laptop15:
        return 14;
      case ScreenType.laptop13:
        return 13;
      case ScreenType.tablet:
        return 12;
    }
  }

  /// Get adaptive icon size
  static double get iconSize {
    switch (screenType) {
      case ScreenType.desktop27:
        return 24;
      case ScreenType.desktop24:
        return 22;
      case ScreenType.laptop15:
        return 20;
      case ScreenType.laptop13:
        return 18;
      case ScreenType.tablet:
        return 16;
    }
  }

  /// Get adaptive button height
  static double get buttonHeight {
    switch (screenType) {
      case ScreenType.desktop27:
        return 44;
      case ScreenType.desktop24:
        return 40;
      case ScreenType.laptop15:
        return 36;
      case ScreenType.laptop13:
        return 32;
      case ScreenType.tablet:
        return 28;
    }
  }

  /// Get adaptive spacing
  static double get spacing {
    switch (screenType) {
      case ScreenType.desktop27:
        return 16;
      case ScreenType.desktop24:
        return 12;
      case ScreenType.laptop15:
        return 8;
      case ScreenType.laptop13:
        return 6;
      case ScreenType.tablet:
        return 4;
    }
  }
}

enum ScreenType {
  tablet,    // < 1024px
  laptop13,  // 1024 - 1365px
  laptop15,  // 1366 - 1599px (15.6")
  desktop24, // 1600 - 1919px (24")
  desktop27, // >= 1920px (27" Full HD+)
}

/// Extension for easier access
extension ResponsiveExtension on num {
  double get w => Responsive.w(toDouble());
  double get h => Responsive.h(toDouble());
  double get s => Responsive.s(toDouble());
  double get sp => Responsive.sp(toDouble());
}

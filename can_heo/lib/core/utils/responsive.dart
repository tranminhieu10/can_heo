import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Responsive utility class for auto-scaling UI based on screen size
/// Supports: Mobile (phones), Tablet, Laptop, Desktop
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
  static late Orientation orientation;
  static late double devicePixelRatio;

  /// Initialize responsive values - call this in build method
  static void init(BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    screenWidth = _mediaQueryData.size.width;
    screenHeight = _mediaQueryData.size.height;
    orientation = _mediaQueryData.orientation;
    devicePixelRatio = _mediaQueryData.devicePixelRatio;

    // Calculate scale factors
    scaleWidth = screenWidth / baseWidth;
    scaleHeight = screenHeight / baseHeight;
    
    // Use the smaller scale to maintain aspect ratio
    scaleFactor = math.min(scaleWidth, scaleHeight);
    
    // Text scale - adaptive for different screen sizes
    if (isMobile) {
      textScaleFactor = (screenWidth / 375).clamp(0.85, 1.15); // Base: iPhone SE
    } else if (isTablet) {
      textScaleFactor = (screenWidth / 768).clamp(0.9, 1.1); // Base: iPad
    } else {
      textScaleFactor = scaleFactor.clamp(0.8, 1.2);
    }
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

  /// Responsive value - returns different values based on screen type
  static T value<T>({
    required T mobile,
    T? tablet,
    T? laptop,
    T? desktop,
  }) {
    if (isDesktop) return desktop ?? laptop ?? tablet ?? mobile;
    if (isLaptop) return laptop ?? tablet ?? mobile;
    if (isTablet) return tablet ?? mobile;
    return mobile;
  }

  /// Get screen type based on width
  static ScreenType get screenType {
    if (screenWidth >= 1920) return ScreenType.desktop27;
    if (screenWidth >= 1600) return ScreenType.desktop24;
    if (screenWidth >= 1366) return ScreenType.laptop15;
    if (screenWidth >= 1024) return ScreenType.laptop13;
    if (screenWidth >= 768) return ScreenType.tablet;
    if (screenWidth >= 480) return ScreenType.mobileLarge;
    return ScreenType.mobile;
  }

  /// Quick checks for screen categories
  static bool get isMobile => screenWidth < 768;
  static bool get isMobileLarge => screenWidth >= 480 && screenWidth < 768;
  static bool get isTablet => screenWidth >= 768 && screenWidth < 1024;
  static bool get isLaptop => screenWidth >= 1024 && screenWidth < 1600;
  static bool get isDesktop => screenWidth >= 1600;
  static bool get isFullHD => screenWidth >= 1920;
  static bool get isLandscape => orientation == Orientation.landscape;
  static bool get isPortrait => orientation == Orientation.portrait;

  /// Get number of columns for grid layouts
  static int get gridColumns {
    if (screenWidth >= 1920) return 4;
    if (screenWidth >= 1366) return 3;
    if (screenWidth >= 768) return 2;
    return 1;
  }

  /// Get adaptive padding based on screen size
  static EdgeInsets get screenPadding {
    switch (screenType) {
      case ScreenType.desktop27:
        return const EdgeInsets.all(24);
      case ScreenType.desktop24:
        return const EdgeInsets.all(20);
      case ScreenType.laptop15:
        return const EdgeInsets.all(16);
      case ScreenType.laptop13:
        return const EdgeInsets.all(12);
      case ScreenType.tablet:
        return const EdgeInsets.all(12);
      case ScreenType.mobileLarge:
        return const EdgeInsets.all(12);
      case ScreenType.mobile:
        return const EdgeInsets.all(8);
    }
  }

  /// Get horizontal padding (for content containers)
  static double get horizontalPadding {
    if (screenWidth >= 1920) return 24;
    if (screenWidth >= 1366) return 16;
    if (screenWidth >= 768) return 12;
    return 8;
  }

  /// Get adaptive font size for body text
  static double get bodyFontSize {
    switch (screenType) {
      case ScreenType.desktop27:
        return 14;
      case ScreenType.desktop24:
        return 13;
      case ScreenType.laptop15:
        return 13;
      case ScreenType.laptop13:
        return 12;
      case ScreenType.tablet:
        return 14;
      case ScreenType.mobileLarge:
        return 14;
      case ScreenType.mobile:
        return 13;
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
        return 15;
      case ScreenType.laptop13:
        return 14;
      case ScreenType.tablet:
        return 16;
      case ScreenType.mobileLarge:
        return 16;
      case ScreenType.mobile:
        return 15;
    }
  }

  /// Get adaptive font size for titles (larger headers)
  static double get titleFontSize {
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
        return 20;
      case ScreenType.mobileLarge:
        return 18;
      case ScreenType.mobile:
        return 16;
    }
  }

  /// Get adaptive font size for small/caption text
  static double get captionFontSize {
    switch (screenType) {
      case ScreenType.desktop27:
        return 12;
      case ScreenType.desktop24:
        return 11;
      case ScreenType.laptop15:
        return 11;
      case ScreenType.laptop13:
        return 10;
      case ScreenType.tablet:
        return 12;
      case ScreenType.mobileLarge:
        return 12;
      case ScreenType.mobile:
        return 11;
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
        return 20;
      case ScreenType.tablet:
        return 22;
      case ScreenType.mobileLarge:
        return 22;
      case ScreenType.mobile:
        return 20;
    }
  }

  /// Get small icon size
  static double get iconSizeSmall {
    switch (screenType) {
      case ScreenType.desktop27:
        return 18;
      case ScreenType.desktop24:
        return 16;
      case ScreenType.laptop15:
        return 16;
      case ScreenType.laptop13:
        return 14;
      case ScreenType.tablet:
        return 16;
      case ScreenType.mobileLarge:
        return 16;
      case ScreenType.mobile:
        return 14;
    }
  }

  /// Get large icon size
  static double get iconSizeLarge {
    switch (screenType) {
      case ScreenType.desktop27:
        return 32;
      case ScreenType.desktop24:
        return 28;
      case ScreenType.laptop15:
        return 26;
      case ScreenType.laptop13:
        return 24;
      case ScreenType.tablet:
        return 28;
      case ScreenType.mobileLarge:
        return 26;
      case ScreenType.mobile:
        return 24;
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
        return 38;
      case ScreenType.laptop13:
        return 36;
      case ScreenType.tablet:
        return 44;
      case ScreenType.mobileLarge:
        return 48;
      case ScreenType.mobile:
        return 44;
    }
  }

  /// Get adaptive input field height
  static double get inputHeight {
    switch (screenType) {
      case ScreenType.desktop27:
        return 48;
      case ScreenType.desktop24:
        return 44;
      case ScreenType.laptop15:
        return 40;
      case ScreenType.laptop13:
        return 38;
      case ScreenType.tablet:
        return 48;
      case ScreenType.mobileLarge:
        return 50;
      case ScreenType.mobile:
        return 48;
    }
  }

  /// Get adaptive spacing (general purpose)
  static double get spacing {
    switch (screenType) {
      case ScreenType.desktop27:
        return 16;
      case ScreenType.desktop24:
        return 14;
      case ScreenType.laptop15:
        return 12;
      case ScreenType.laptop13:
        return 10;
      case ScreenType.tablet:
        return 12;
      case ScreenType.mobileLarge:
        return 12;
      case ScreenType.mobile:
        return 8;
    }
  }

  /// Get small spacing
  static double get spacingSmall {
    switch (screenType) {
      case ScreenType.desktop27:
        return 8;
      case ScreenType.desktop24:
        return 8;
      case ScreenType.laptop15:
        return 6;
      case ScreenType.laptop13:
        return 6;
      case ScreenType.tablet:
        return 6;
      case ScreenType.mobileLarge:
        return 6;
      case ScreenType.mobile:
        return 4;
    }
  }

  /// Get large spacing
  static double get spacingLarge {
    switch (screenType) {
      case ScreenType.desktop27:
        return 24;
      case ScreenType.desktop24:
        return 20;
      case ScreenType.laptop15:
        return 16;
      case ScreenType.laptop13:
        return 14;
      case ScreenType.tablet:
        return 16;
      case ScreenType.mobileLarge:
        return 16;
      case ScreenType.mobile:
        return 12;
    }
  }

  /// Get card border radius
  static double get cardRadius {
    if (isMobile) return 12;
    if (isTablet) return 12;
    return 8;
  }

  /// Get button border radius
  static double get buttonRadius {
    if (isMobile) return 8;
    return 6;
  }

  /// Get dialog max width
  static double get dialogMaxWidth {
    if (isMobile) return screenWidth * 0.9;
    if (isTablet) return 500;
    return 600;
  }

  /// Get bottom sheet max height
  static double get bottomSheetMaxHeight {
    return screenHeight * 0.85;
  }

  /// Get navigation rail width (for sidebar)
  static double get navRailWidth {
    if (screenWidth >= 1600) return 250;
    if (screenWidth >= 1024) return 200;
    return 72; // Icon only
  }

  /// Check if should use bottom navigation (for mobile)
  static bool get useBottomNav => isMobile;

  /// Check if should use drawer navigation
  static bool get useDrawer => isTablet || isMobile;

  /// Check if should show sidebar
  static bool get showSidebar => isLaptop || isDesktop;

  /// Get table row height
  static double get tableRowHeight {
    if (isMobile) return 52;
    if (isTablet) return 48;
    return 44;
  }

  /// Get DataTable column spacing
  static double get tableColumnSpacing {
    if (screenWidth >= 1600) return 56;
    if (screenWidth >= 1024) return 40;
    if (screenWidth >= 768) return 24;
    return 16;
  }

  /// Get max content width (for centered layouts)
  static double get maxContentWidth {
    if (screenWidth >= 1920) return 1600;
    if (screenWidth >= 1600) return 1400;
    if (screenWidth >= 1366) return 1200;
    return screenWidth;
  }
}

enum ScreenType {
  mobile,      // < 480px (small phones)
  mobileLarge, // 480 - 767px (large phones)
  tablet,      // 768 - 1023px (tablets)
  laptop13,    // 1024 - 1365px (13" laptops)
  laptop15,    // 1366 - 1599px (15.6" laptops)
  desktop24,   // 1600 - 1919px (24" monitors)
  desktop27,   // >= 1920px (27" Full HD+)
}

/// Extension for easier access
extension ResponsiveExtension on num {
  double get w => Responsive.w(toDouble());
  double get h => Responsive.h(toDouble());
  double get s => Responsive.s(toDouble());
  double get sp => Responsive.sp(toDouble());
}

/// Responsive Builder Widget - builds different layouts based on screen size
class ResponsiveBuilder extends StatelessWidget {
  final Widget mobile;
  final Widget? mobileLarge;
  final Widget? tablet;
  final Widget? laptop;
  final Widget? desktop;

  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.mobileLarge,
    this.tablet,
    this.laptop,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        Responsive.init(context);
        
        if (Responsive.isDesktop && desktop != null) {
          return desktop!;
        }
        if (Responsive.isLaptop && laptop != null) {
          return laptop!;
        }
        if (Responsive.isTablet && tablet != null) {
          return tablet!;
        }
        if (Responsive.isMobileLarge && mobileLarge != null) {
          return mobileLarge!;
        }
        return mobile;
      },
    );
  }
}

/// Orientation Builder Widget
class ResponsiveOrientationBuilder extends StatelessWidget {
  final Widget portrait;
  final Widget landscape;

  const ResponsiveOrientationBuilder({
    super.key,
    required this.portrait,
    required this.landscape,
  });

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        Responsive.init(context);
        return orientation == Orientation.landscape ? landscape : portrait;
      },
    );
  }
}

/// Responsive SizedBox for spacing
class ResponsiveSpacing extends StatelessWidget {
  final double? width;
  final double? height;
  final bool small;
  final bool large;

  const ResponsiveSpacing({
    super.key,
    this.width,
    this.height,
  }) : small = false, large = false;

  const ResponsiveSpacing.small({super.key})
      : width = null, height = null, small = true, large = false;

  const ResponsiveSpacing.large({super.key})
      : width = null, height = null, small = false, large = true;

  @override
  Widget build(BuildContext context) {
    double spacing;
    if (small) {
      spacing = Responsive.spacingSmall;
    } else if (large) {
      spacing = Responsive.spacingLarge;
    } else {
      spacing = Responsive.spacing;
    }

    return SizedBox(
      width: width ?? spacing,
      height: height ?? spacing,
    );
  }
}

/// Responsive Padding Widget
class ResponsivePadding extends StatelessWidget {
  final Widget child;
  final EdgeInsets? customPadding;

  const ResponsivePadding({
    super.key,
    required this.child,
    this.customPadding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: customPadding ?? Responsive.screenPadding,
      child: child,
    );
  }
}

/// Responsive Container that centers content with max width
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsets? padding;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? Responsive.maxContentWidth,
        ),
        padding: padding ?? Responsive.screenPadding,
        child: child,
      ),
    );
  }
}

/// Responsive Grid that auto-adjusts columns
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final int? columns;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.spacing = 16,
    this.runSpacing = 16,
    this.columns,
  });

  @override
  Widget build(BuildContext context) {
    final cols = columns ?? Responsive.gridColumns;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - (cols - 1) * spacing) / cols;
        
        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: children.map((child) {
            return SizedBox(
              width: itemWidth,
              child: child,
            );
          }).toList(),
        );
      },
    );
  }
}

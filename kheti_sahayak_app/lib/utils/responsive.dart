// Responsive layout utilities for Kheti Sahayak
// Adapts UI for different screen sizes and platforms

import 'package:flutter/material.dart';
import 'platform_utils.dart';

/// Responsive widget that adapts to different screen sizes
class Responsive extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;
  final Widget? web;

  const Responsive({
    Key? key,
    required this.mobile,
    this.tablet,
    this.desktop,
    this.web,
  }) : super(key: key);

  // Screen size breakpoints
  static const double mobileMaxWidth = 650;
  static const double tabletMaxWidth = 1100;

  // Check if mobile screen
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileMaxWidth;

  // Check if tablet screen
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobileMaxWidth &&
      MediaQuery.of(context).size.width < tabletMaxWidth;

  // Check if desktop screen
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= tabletMaxWidth;

  // Get screen width
  static double screenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;

  // Get screen height
  static double screenHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;

  @override
  Widget build(BuildContext context) {
    // Use web-specific layout if on web and provided
    if (PlatformUtils.isWeb && web != null) {
      return web!;
    }
    
    // Use desktop layout for large screens
    if (isDesktop(context) && desktop != null) {
      return desktop!;
    }
    
    // Use tablet layout for medium screens
    if (isTablet(context) && tablet != null) {
      return tablet!;
    }
    
    // Default to mobile layout
    return mobile;
  }
}

/// Responsive value based on screen size
class ResponsiveValue<T> {
  final T mobile;
  final T? tablet;
  final T? desktop;

  const ResponsiveValue({
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  T getValue(BuildContext context) {
    if (Responsive.isDesktop(context) && desktop != null) {
      return desktop!;
    }
    if (Responsive.isTablet(context) && tablet != null) {
      return tablet!;
    }
    return mobile;
  }
}

/// Responsive padding helper
class ResponsivePadding {
  static EdgeInsets all(BuildContext context) {
    if (PlatformUtils.isMobile) {
      return const EdgeInsets.all(16.0);
    } else if (PlatformUtils.isDesktop) {
      return const EdgeInsets.all(24.0);
    }
    return const EdgeInsets.all(20.0);
  }

  static EdgeInsets horizontal(BuildContext context) {
    if (PlatformUtils.isMobile) {
      return const EdgeInsets.symmetric(horizontal: 16.0);
    } else if (PlatformUtils.isDesktop) {
      return const EdgeInsets.symmetric(horizontal: 32.0);
    }
    return const EdgeInsets.symmetric(horizontal: 24.0);
  }

  static EdgeInsets vertical(BuildContext context) {
    if (PlatformUtils.isMobile) {
      return const EdgeInsets.symmetric(vertical: 12.0);
    } else if (PlatformUtils.isDesktop) {
      return const EdgeInsets.symmetric(vertical: 16.0);
    }
    return const EdgeInsets.symmetric(vertical: 14.0);
  }
}

/// Responsive font sizes
class ResponsiveFontSize {
  static double title(BuildContext context) {
    if (Responsive.isDesktop(context)) return 32.0;
    if (Responsive.isTablet(context)) return 28.0;
    return 24.0;
  }

  static double heading(BuildContext context) {
    if (Responsive.isDesktop(context)) return 24.0;
    if (Responsive.isTablet(context)) return 22.0;
    return 20.0;
  }

  static double body(BuildContext context) {
    if (Responsive.isDesktop(context)) return 16.0;
    if (Responsive.isTablet(context)) return 15.0;
    return 14.0;
  }

  static double caption(BuildContext context) {
    if (Responsive.isDesktop(context)) return 14.0;
    if (Responsive.isTablet(context)) return 13.0;
    return 12.0;
  }
}

/// Responsive layout configuration
class ResponsiveLayout {
  // Maximum content width for large screens
  static double get maxContentWidth => 1200.0;

  // Grid column count based on screen size
  static int gridColumnCount(BuildContext context) {
    if (Responsive.isDesktop(context)) return 4;
    if (Responsive.isTablet(context)) return 3;
    return 2;
  }

  // Sidebar width for desktop
  static double get sidebarWidth => 250.0;

  // App bar height
  static double appBarHeight(BuildContext context) {
    if (PlatformUtils.isDesktop) return 64.0;
    return 56.0;
  }
}


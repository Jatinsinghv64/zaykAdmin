

import 'package:flutter/material.dart';

class Permissions {
  static const String canViewDashboard = 'canViewDashboard';
  static const String canManageInventory = 'canManageInventory';
  static const canViewAnalytics = 'canViewAnalytics';
  static const String canManageOrders = 'canManageOrders';
  static const String canManageRiders = 'canManageRiders';
  static const String canManageSettings = 'canManageSettings';
  static const String canManageStaff = 'canManageStaff';
  static const String canManageCoupons = 'canManageCoupons';
}

class AppScreen {
  final AppTab tab;
  final String permissionKey;
  final Widget screen;
  final BottomNavigationBarItem navItem;
  AppScreen({
    required this.tab,
    required this.permissionKey,
    required this.screen,
    required this.navItem,
  });
}

enum AppTab { dashboard, inventory, orders, riders, analytics, settings }
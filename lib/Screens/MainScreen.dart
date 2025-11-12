import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';

import '../Widgets/RestaurantStatusService.dart';
import '../Widgets/RiderAssignment.dart';
import '../Widgets/placeholders.dart';
import '../main.dart';
import 'AnalyticsScreen.dart';
import 'DashboardScreen.dart';
import 'MenuManagement.dart';
import 'OrdersScreen.dart';
import 'RidersScreen.dart';
import 'SettingsScreen.dart';

import '../Widgets/notification.dart' as notif;





class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  List<Widget> _screens = [];
  List<BottomNavigationBarItem> _navItems = [];
  late Map<AppTab, AppScreen> _allScreens;
  StreamSubscription? _backgroundServiceSubscription;

  // Dialog management
  bool _isDialogShowing = false;
  final Set<String> _processedOrderIds = {};

  // Restaurant status
  bool _isRestaurantStatusInitialized = false;
  bool _isBuildingNavItems = false;

  // Callback method for tab changes from Dashboard
  void _onTabChange(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();

    // Initialize screens here after the instance is created
    _allScreens = {
      AppTab.dashboard: AppScreen(
        tab: AppTab.dashboard,
        permissionKey: Permissions.canViewDashboard,
        screen: DashboardScreen(onTabChange: _onTabChange),
        navItem: const BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined),
          activeIcon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
      ),
      AppTab.inventory: AppScreen(
        tab: AppTab.inventory,
        permissionKey: Permissions.canManageInventory,
        screen: const InventoryScreen(),
        navItem: const BottomNavigationBarItem(
          icon: Icon(Icons.inventory_2_outlined),
          activeIcon: Icon(Icons.inventory_2),
          label: 'Inventory',
        ),
      ),
      AppTab.orders: AppScreen(
        tab: AppTab.orders,
        permissionKey: Permissions.canManageOrders,
        screen: const OrdersScreen(),
        navItem: const BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long_outlined),
          activeIcon: Icon(Icons.receipt_long),
          label: 'Orders',
        ),
      ),
      AppTab.riders: AppScreen(
        tab: AppTab.riders,
        permissionKey: Permissions.canManageRiders,
        screen: const RidersScreen(),
        navItem: const BottomNavigationBarItem(
          icon: Icon(Icons.delivery_dining_outlined),
          activeIcon: Icon(Icons.delivery_dining),
          label: 'Riders',
        ),
      ),
    };

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _buildNavItems();
      _listenToBackgroundService();
      _initializeRestaurantStatus();
    });
  }

  void _initializeRestaurantStatus() {
    final scopeService = context.read<UserScopeService>();
    final statusService = context.read<RestaurantStatusService>();

    if (scopeService.branchId.isNotEmpty && !_isRestaurantStatusInitialized) {
      String restaurantName = "Branch ${scopeService.branchId}";
      if (scopeService.userEmail.isNotEmpty) {
        restaurantName = "Restaurant (${scopeService.userEmail.split('@').first})";
      }

      statusService.initialize(scopeService.branchId, restaurantName: restaurantName);
      _isRestaurantStatusInitialized = true;
    }
  }

  void _listenToBackgroundService() {
    try {
      final service = FlutterBackgroundService();

      _backgroundServiceSubscription = service.on('new_order').listen((event) {
        debugPrint('🎯 HomeScreen: Received order from background service');

        if (event != null && mounted) {
          try {
            final data = Map<String, dynamic>.from(event);
            final orderId = data['id']?.toString() ?? 'unknown';
            final orderNumber = data['dailyOrderNumber']?.toString() ?? 'N/A';

            debugPrint('🎯 HomeScreen: Order data received - ID: $orderId, Number: $orderNumber');

            // Use WidgetsBinding to ensure we're in the right context
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _showInAppOrderDialog(data);
              }
            });
          } catch (e) {
            debugPrint('❌ HomeScreen: Error processing order data: $e');
          }
        }
      });

      debugPrint('✅ HomeScreen: Background service listener initialized');

    } catch (e) {
      debugPrint('❌ HomeScreen: Error setting up background service listener: $e');
    }
  }

  void _showInAppOrderDialog(Map<String, dynamic> data) {
    final orderId = data['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();

    // Prevent duplicate dialogs
    if (_isDialogShowing) {
      debugPrint('🚫 Dialog already showing, skipping order: $orderId');
      return;
    }

    if (_processedOrderIds.contains(orderId)) {
      debugPrint('🚫 Order already processed: $orderId');
      return;
    }

    _processedOrderIds.add(orderId);
    _isDialogShowing = true;

    debugPrint('🔄 Preparing to show dialog for order: $orderId');

    // Extract order details with null safety
    final orderNumber = data['dailyOrderNumber']?.toString() ??
        orderId.substring(0, 6).toUpperCase();
    final customerName = data['customerName']?.toString() ?? 'N/A';
    final addressMap = data['deliveryAddress'] as Map<String, dynamic>?;
    final address = addressMap?['street']?.toString() ?? 'N/A';
    final itemsList = (data['items'] as List<dynamic>?) ?? [];
    final orderType = data['Order_type']?.toString() ?? 'Unknown';

    final items = itemsList.map((item) {
      final itemMap = item as Map<String, dynamic>? ?? {};
      final itemName = itemMap['name']?.toString() ?? 'Unknown';
      final qty = itemMap['quantity']?.toString() ?? '1';
      return '$qty x $itemName';
    }).toList();

    final itemsString = items.join('\n');

    debugPrint('🎯 Showing dialog for order: $orderNumber');

    // Use a slight delay to ensure context is ready
    Future.delayed(Duration(milliseconds: 100), () {
      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return notif.NewOrderDialog(
            orderNumber: orderNumber,
            customerName: customerName,
            address: address,
            itemsString: itemsString,
            orderType: orderType,
            onAccept: () {
              debugPrint('✅ Order accepted: $orderId');
              Navigator.of(dialogContext).pop();
              _handleOrderAcceptance(orderId);
              _isDialogShowing = false;
            },
            onReject: () {
              debugPrint('❌ Order rejected: $orderId');
              Navigator.of(dialogContext).pop();
              _updateOrderStatus(orderId, 'cancelled');
              _isDialogShowing = false;
            },
            onAutoAccept: () {
              debugPrint('🤖 Order auto-accepted: $orderId');
              Navigator.of(dialogContext).pop();
              _handleOrderAcceptance(orderId);
              _isDialogShowing = false;
            },
          );
        },
      ).then((_) {
        // Ensure flag is reset when dialog is closed by other means
        _isDialogShowing = false;
        debugPrint('✅ Dialog closed for order: $orderId');
      }).catchError((error) {
        _isDialogShowing = false;
        debugPrint('❌ Dialog error: $error');
      });
    });
  }

  Future<void> _handleOrderAcceptance(String orderId) async {
    try {
      final db = FirebaseFirestore.instance;

      // Update order status
      await db.collection('Orders').doc(orderId).update({
        'status': 'preparing',
        'timestamps.preparing': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Order $orderId accepted and status updated to preparing');

      // Auto-assign rider if needed
      final userScope = context.read<UserScopeService>();
      if (userScope.branchId.isNotEmpty) {
        await RiderAssignmentService.autoAssignRider(
          orderId: orderId,
          branchId: userScope.branchId,
        );
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order #$orderId accepted successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }

    } catch (e) {
      debugPrint('❌ Error accepting order: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error accepting order: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _updateOrderStatus(String orderId, String status) async {
    try {
      final db = FirebaseFirestore.instance;
      final Map<String, dynamic> updateData = {'status': status};

      if (status == 'cancelled') {
        updateData['timestamps.cancelled'] = FieldValue.serverTimestamp();
      }

      await db.collection('Orders').doc(orderId).update(updateData);

      debugPrint('📝 Order $orderId status updated to $status');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order #$orderId $status'),
            backgroundColor: status == 'cancelled' ? Colors.orange : Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }

    } catch (e) {
      debugPrint('❌ Error updating order status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating order: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  // Restaurant status methods
  Widget _buildRestaurantToggle(RestaurantStatusService statusService) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Toggle background with loading state
        if (statusService.isLoading)
          Container(
            width: 50,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else
          Switch(
            value: statusService.isOpen,
            onChanged: (newValue) {
              _showStatusChangeConfirmation(newValue);
            },
            activeColor: Colors.green,
            activeTrackColor: Colors.green[100],
            inactiveThumbColor: Colors.red,
            inactiveTrackColor: Colors.red[100],
          ),
      ],
    );
  }

  void _showStatusChangeConfirmation(bool newValue) {
    final statusService = context.read<RestaurantStatusService>();
    final userScope = context.read<UserScopeService>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(
              newValue ? Icons.storefront : Icons.storefront_outlined,
              color: newValue ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 12),
            Text(
              newValue ? 'Open Restaurant?' : 'Close Restaurant?',
              style: TextStyle(
                color: newValue ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          newValue
              ? 'The restaurant will be opened for business. New orders will be accepted and notifications will be enabled.'
              : 'The restaurant will be closed. No new orders will be accepted and background services will be stopped.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              try {
                await statusService.toggleRestaurantStatus(newValue);

                // Show success message
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        newValue
                            ? '✅ Restaurant is now OPEN - Background service started'
                            : '🛑 Restaurant is now CLOSED - Background service stopped',
                      ),
                      backgroundColor: newValue ? Colors.green : Colors.red,
                    ),
                  );
                }
              } catch (e) {
                // Show error message
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ Failed to update restaurant status: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: newValue ? Colors.green : Colors.red,
            ),
            child: Text(
              newValue ? 'Open Restaurant' : 'Close Restaurant',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
  void _buildNavItems() {
    if (_isBuildingNavItems) return;
    _isBuildingNavItems = true;

    final userScope = context.read<UserScopeService>();
    final List<AppScreen> allowedScreens = [];

    if (userScope.can(Permissions.canViewDashboard)) {
      allowedScreens.add(_allScreens[AppTab.dashboard]!);
    }
    if (userScope.can(Permissions.canManageInventory)) {
      allowedScreens.add(_allScreens[AppTab.inventory]!);
    }
    if (userScope.can(Permissions.canManageOrders)) {
      allowedScreens.add(_allScreens[AppTab.orders]!);
    }
    if (userScope.can(Permissions.canManageRiders)) {
      allowedScreens.add(_allScreens[AppTab.riders]!);
    }

    // Use WidgetsBinding to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _screens = allowedScreens.map((s) => s.screen).toList();
          _navItems = allowedScreens.map((s) => s.navItem).toList();
          if (_currentIndex >= _screens.length) {
            _currentIndex = 0;
          }
          _isBuildingNavItems = false;
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Only rebuild nav items if user scope changes and we're not already building
    final userScope = context.watch<UserScopeService>();
    if (!_isBuildingNavItems) {
      _buildNavItems();
    }

    // Re-initialize restaurant status if needed
    if (!_isRestaurantStatusInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeRestaurantStatus();
      });
    }
  }

  @override
  void dispose() {
    _backgroundServiceSubscription?.cancel();
    _processedOrderIds.clear();
    debugPrint('🛑 HomeScreen disposed');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userScope = context.watch<UserScopeService>();
    final statusService = context.watch<RestaurantStatusService>();
    final String appBarTitle = userScope.isSuperAdmin
        ? 'Super Admin'
        : userScope.branchId.isNotEmpty
        ? userScope.branchId.replaceAll('_', ' ')
        : 'Admin Panel';

    if (_screens.isEmpty || _navItems.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_currentIndex >= _screens.length) {
      _currentIndex = 0;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        actions: [
          // Restaurant Status Toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                // Status text with better visibility
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusService.isOpen ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: statusService.isOpen ? Colors.green : Colors.red,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    statusService.isOpen ? 'OPEN' : 'CLOSED',
                    style: TextStyle(
                      color: statusService.isOpen ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _buildRestaurantToggle(statusService),
                const SizedBox(width: 8),
              ],
            ),
          ),

          // Settings button only
          if (userScope.can(Permissions.canManageSettings))
            IconButton(
              tooltip: 'Settings',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
              icon: Icon(
                Icons.settings_rounded,
                size: 22,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: _navItems,
      ),
    );
  }
}
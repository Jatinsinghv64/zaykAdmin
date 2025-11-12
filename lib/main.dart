
// ❌ REMOVED: import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
// ❌ REMOVED: import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
// ❌ REMOVED: import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_background_service/flutter_background_service.dart'; // Import service

// Import your screens
import 'Screens/LoginScreen.dart';
import 'Screens/MainScreen.dart';
import 'Widgets/Authorization.dart';
import 'Widgets/BackgroundOrderService.dart';
import 'Widgets/RestaurantStatusService.dart';
import 'Widgets/notification.dart';
import 'firebase_options.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// ❌ REMOVED: flutterLocalNotificationsPlugin
// ❌ REMOVED: AndroidNotificationChannel
// ❌ REMOVED: _firebaseMessagingBackgroundHandler
// ❌ REMOVED: _showNotification
// ❌ REMOVED: _onNotificationTap
// ❌ REMOVED: showInAppOrderDialog

void _navigateToOrder(String orderId) {
  // This function is still used by notification.dart (via the dialog)
  final context = navigatorKey.currentContext;
  if (context != null) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => HomeScreen()),
          (route) => false,
    );
    debugPrint("Should navigate to order: $orderId");
  } else {
    debugPrint("❌ Cannot navigate! Navigator context is null.");
  }
}

// ❌ REMOVED: _initializeLocalNotifications

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // --- START: ROBUST SERVICE LAUNCH ---
  final service = FlutterBackgroundService();

  // ✅ ALWAYS initialize (configure) the service first.
  await BackgroundOrderService.initializeService();

  // Now, check if it's running.
  bool isRunning = await service.isRunning();

  if (!isRunning) {
    debugPrint(
        "🚀 MAIN: Service is not running. Starting it.");
    await BackgroundOrderService.startService();
  } else {
    debugPrint(
        "✅ MAIN: Service is already running. Initialization complete.");
  }
  // --- END: ROBUST SERVICE LAUNCH ---

  // ❌ REMOVED: await _initializeLocalNotifications();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
        ChangeNotifierProvider<UserScopeService>(
          create: (_) => UserScopeService(),
        ),
        ChangeNotifierProvider<OrderNotificationService>(
          create: (_) => OrderNotificationService(),
        ),
        ChangeNotifierProvider<RestaurantStatusService>(
          create: (_) => RestaurantStatusService(),
        ),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'Branch Admin App',
        theme: ThemeData(
          // ... Your theme data ...
          primarySwatch: Colors.deepPurple,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          scaffoldBackgroundColor: Colors.grey[50],
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.deepPurple),
            titleTextStyle: TextStyle(
              color: Colors.deepPurple,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          bottomNavigationBarTheme: BottomNavigationBarThemeData(
            backgroundColor: Colors.white,
            selectedItemColor: Colors.deepPurple,
            unselectedItemColor: Colors.grey[600],
            elevation: 10,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
            ),
          ),
        ),
        home: const AuthWrapper(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}







// ScopeLoader
class ScopeLoader extends StatefulWidget {
  final User user;
  const ScopeLoader({super.key, required this.user});

  @override
  State<ScopeLoader> createState() => _ScopeLoaderState();
}

// ✅ ADDED WidgetsBindingObserver to track app lifecycle
class _ScopeLoaderState extends State<ScopeLoader> with WidgetsBindingObserver {
  final _service = FlutterBackgroundService();

  @override
  void initState() {
    super.initState();
    // ✅ Tell the service the app is in the foreground
    WidgetsBinding.instance.addObserver(this);
    _service.invoke('appInForeground');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadScope();
    });
  }

  // ✅ ADDED LIFECYCLE HANDLER
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _service.invoke('appInForeground');
    } else {
      // Treat inactive, paused, detached as background
      _service.invoke('appInBackground');
    }
    debugPrint('App changed state: $state');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _loadScope() async {
    final scopeService = context.read<UserScopeService>();
    final notificationService = context.read<OrderNotificationService>();
    final statusService = context.read<RestaurantStatusService>();

    final bool isSuccess = await scopeService.loadUserScope(widget.user);

    if (isSuccess && mounted) {
      // Initialize restaurant status service
      if (scopeService.branchId.isNotEmpty) {
        String restaurantName = "Branch ${scopeService.branchId}";
        if (scopeService.userEmail.isNotEmpty) {
          restaurantName =
          "Restaurant (${scopeService.userEmail.split('@').first})";
        }

        statusService.initialize(scopeService.branchId,
            restaurantName: restaurantName);

        // Wait for status to load
        await Future.delayed(const Duration(seconds: 2));
      }

      // ✅ Initialize notification service (now listens to background service)
      notificationService.init(scopeService, navigatorKey);

      debugPrint(
          '🎯 OrderNotificationService initialized (listening to background service).');

      debugPrint(
          '🟡 Background service will be controlled by restaurant status');
    } else {
      debugPrint('❌ Failed to load user scope');
    }
  }

  @override
  Widget build(BuildContext context) {
    final scopeService = context.watch<UserScopeService>();

    if (!scopeService.isLoaded) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("Verifying credentials..."),
            ],
          ),
        ),
      );
    }

    return const HomeScreen();
  }
}

// User Scope Service
class UserScopeService with ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String _role = 'unknown';
  List<String> _branchIds = [];
  Map<String, bool> _permissions = {};
  bool _isLoaded = false;
  String _userEmail = '';

  String get role => _role;
  List<String> get branchIds => _branchIds;
  String get branchId => _branchIds.isNotEmpty ? _branchIds.first : '';
  String get userEmail => _userEmail;
  bool get isLoaded => _isLoaded;
  bool get isSuperAdmin => _role == 'super_admin';
  Map<String, bool> get permissions => _permissions;

  bool can(String permissionKey) {
    if (isSuperAdmin) return true;
    return _permissions[permissionKey] ?? false;
  }

  Future<bool> loadUserScope(User user) async {
    if (_isLoaded) return true;

    try {
      _userEmail = user.email ?? '';
      if (_userEmail.isEmpty) {
        throw Exception('User email is null.');
      }

      debugPrint('🎯 Loading user scope for: $_userEmail');

      final staffSnap = await _db.collection('staff').doc(_userEmail).get();

      if (!staffSnap.exists) {
        debugPrint(
            '❌ Scope Error: No staff document found for $_userEmail.');
        await clearScope();
        return false;
      }

      final data = staffSnap.data();
      final bool isActive = data?['isActive'] ?? false;

      if (!isActive) {
        debugPrint(
            '❌ Scope Error: Staff member $_userEmail is not active.');
        await clearScope();
        return false;
      }

      _role = data?['role'] as String? ?? 'unknown';
      _branchIds = List<String>.from(data?['branchIds'] ?? []);
      _permissions = Map<String, bool>.from(data?['permissions'] ?? {});
      _isLoaded = true;

      debugPrint(
          '✅ Scope Loaded: $_userEmail | Role: $_role | Branches: $_branchIds | Permissions: $_permissions');
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Error loading user scope: $e');
      await clearScope();
      return false;
    }
  }

  Future<void> clearScope() async {
    _role = 'unknown';
    _branchIds = [];
    _permissions = {};
    _isLoaded = false;
    _userEmail = '';
    notifyListeners();
  }
}



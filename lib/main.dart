import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_background_service/flutter_background_service.dart'; // Import service

// Import your screens
import 'Screens/MainScreen.dart';
import 'Widgets/BackgroundOrderService.dart';
import 'Widgets/RestaurantStatusService.dart';
import 'Widgets/notification.dart';
import 'firebase_options.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Initialize flutter_local_notifications
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel', // ID
  'High Importance Notifications', // Title
  description: 'This channel is used for important order notifications.', // Description
  importance: Importance.max,
  playSound: true,
  enableVibration: true,
);

// ✅ ENHANCED BACKGROUND HANDLER - WORKS WHEN APP IS TERMINATED
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("BACKGROUND HANDLER: App was TERMINATED or in BACKGROUND");
  // ... (rest of your handler)
}


// ✅ UNIVERSAL NOTIFICATION DISPLAY METHOD
Future<void> _showNotification(RemoteMessage message) async {
  String title = 'New Order';
  String body = 'You have a new order';
  Map<String, dynamic> data = {};

  if (message.notification != null) {
    title = message.notification?.title ?? title;
    body = message.notification?.body ?? body;
  }

  if (message.data.isNotEmpty) {
    data = message.data;
    title = data['title'] ?? title;
    body = data['body'] ?? body;
  }

  debugPrint("Showing notification: $title - $body");

  const AndroidNotificationDetails androidPlatformChannelSpecifics =
  AndroidNotificationDetails(
    'high_importance_channel',
    'High Importance Notifications',
    channelDescription:
    'This channel is used for important order notifications.',
    importance: Importance.max,
    priority: Priority.high,
    showWhen: true,
    autoCancel: true,
    enableVibration: true,
    playSound: true,
    visibility: NotificationVisibility.public,
  );

  const DarwinNotificationDetails iosPlatformChannelSpecifics =
  DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );

  const NotificationDetails platformChannelSpecifics = NotificationDetails(
    android: androidPlatformChannelSpecifics,
    iOS: iosPlatformChannelSpecifics,
  );

  final int notificationId =
  DateTime.now().millisecondsSinceEpoch.remainder(100000);

  await flutterLocalNotificationsPlugin.show(
    notificationId,
    title,
    body,
    platformChannelSpecifics,
    payload: jsonEncode(data),
  );

  debugPrint("✅ NOTIFICATION DISPLAYED: $title");
}

// ✅ HANDLE NOTIFICATION TAP
void _onNotificationTap(String? payload) {
  debugPrint("Notification tapped with payload: $payload");
  if (payload != null) {
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final orderId = data['orderId'];
      if (orderId != null) {
        _navigateToOrder(orderId);
      }
    } catch (e) {
      debugPrint("Error parsing notification payload: $e");
    }
  }
}

// ADD THIS NEW GLOBAL FUNCTION (Corrected Version)
void showInAppOrderDialog(Map<String, dynamic> data) {
  final context = navigatorKey.currentContext;
  if (context == null) {
    debugPrint("Cannot show dialog, navigator context is null");
    return;
  }
  final String orderNumber = data['dailyOrderNumber']?.toString() ?? 'N/A';
  final String customerName = data['customerName']?.toString() ?? 'Unknown';
  final String orderId = data['orderId']?.toString() ?? '';
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('🎉 New Order Received!'),
        content: Text('Order #${orderNumber} from $customerName'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Dismiss'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (orderId.isNotEmpty) {
                _navigateToOrder(orderId);
              }
            },
            child: const Text('View Order'),
          ),
        ],
      );
    },
  );
}

void _navigateToOrder(String orderId) {
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

// ✅ COMPLETE LOCAL NOTIFICATIONS INITIALIZATION
Future<void> _initializeLocalNotifications() async {
  const AndroidInitializationSettings androidInitializationSettings =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  const DarwinInitializationSettings iosInitializationSettings =
  DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  const InitializationSettings initializationSettings =
  InitializationSettings(
    android: androidInitializationSettings,
    iOS: iosInitializationSettings,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
  );

  try {
    final bool? granted = await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    debugPrint("Android 13+ Notification Permission Granted: $granted");
  } on PlatformException catch (e) {
    debugPrint("Error requesting Android 13+ notification permission: $e");
  } catch (e) {
    debugPrint("Generic error requesting notification permission: $e");
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // --- START: ROBUST SERVICE LAUNCH ---
  // This is the fix for the app hanging on launch
  final service = FlutterBackgroundService();

  // ✅ FIX: ALWAYS initialize (configure) the service first.
  // This links the new app instance to the existing background process.
  await BackgroundOrderService.initializeService();

  // Now, check if it's running.
  bool isRunning = await service.isRunning();

  if (!isRunning) {
    debugPrint(
        "🚀 MAIN: Service is not running. Starting it.");
    // If not running, start it.
    await BackgroundOrderService.startService();
  } else {
    debugPrint(
        "✅ MAIN: Service is already running. Initialization complete.");
  }
  // --- END: ROBUST SERVICE LAUNCH ---

  await _initializeLocalNotifications(); // For the main app's notifications

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  // ... (rest of your MyApp class is correct) ...
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
        // ✅ ADD RESTAURANT STATUS SERVICE
        ChangeNotifierProvider<RestaurantStatusService>(
          create: (_) => RestaurantStatusService(),
        ),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'Branch Admin App',
        theme: ThemeData(
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

// ... (Rest of your file (Permissions, AppScreen, AuthService, AuthWrapper, LoginScreen, ScopeLoader, UserScopeService, etc.) is correct and does not need changes) ...

// Permission constants
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

// Auth Service
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Stream<User?> get userStream => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<String?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        return 'Invalid email or password.';
      } else {
        return 'An error occurred. Please try again.';
      }
    } catch (e) {
      return 'An unexpected error occurred.';
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    return StreamBuilder<User?>(
      stream: authService.userStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          final User? user = snapshot.data;
          if (user == null) {
            return const LoginScreen();
          }
          return ScopeLoader(user: user);
        }
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authService = context.read<AuthService>();
    final error = await authService.signInWithEmailAndPassword(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (error != null && mounted) {
      setState(() {
        _isLoading = false;
        _errorMessage = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.store_mall_directory,
                    size: 80,
                    color: Colors.deepPurple,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Branch Admin Login',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) =>
                    (value == null || !value.contains('@'))
                        ? 'Please enter a valid email'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Please enter your password'
                        : null,
                  ),
                  const SizedBox(height: 24),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        _errorMessage!,
                        style:
                        const TextStyle(color: Colors.red, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton.icon(
                    onPressed: _login,
                    icon: const Icon(Icons.login),
                    label: const Text('Login'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ScopeLoader with FCM initialization
// ScopeLoader with OrderNotificationService initialization
class ScopeLoader extends StatefulWidget {
  final User user;
  const ScopeLoader({super.key, required this.user});

  @override
  State<ScopeLoader> createState() => _ScopeLoaderState();
}

class _ScopeLoaderState extends State<ScopeLoader> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadScope();
    });
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

        // Wait for status to load - DO NOT auto-start background service here
        // Let the RestaurantStatusService handle it based on isOpen status
        await Future.delayed(const Duration(seconds: 2));
      }

      // Initialize notification service (for foreground listening)
      notificationService.init(scopeService, navigatorKey);

      debugPrint(
          '🎯 OrderNotificationService initialized with branches: ${scopeService.branchIds}');

      // ❌ REMOVED: Background service auto-start
      // The RestaurantStatusService will handle starting/stopping based on isOpen status
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

// Access Denied Widget
class AccessDeniedWidget extends StatelessWidget {
  final String permission;
  const AccessDeniedWidget({super.key, required this.permission});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.red[50],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lock_outline,
              size: 60,
              color: Colors.red[700],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Access Denied',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.red[900],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            "Your account does not have the required permission to '$permission'.\n\nPlease contact your super administrator if you believe this is an error.",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Professional Error Widget
class ProfessionalErrorWidget extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final VoidCallback? onRetry;

  const ProfessionalErrorWidget({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.error_outline,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.red[50],
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 60,
              color: Colors.red[700],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.red[900],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.red[700],
              ),
            ),
          ],
        ],
      ),
    );
  }
}


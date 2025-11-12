// import 'dart:convert';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
//
// // Import the global variables/widgets from main.dart and other screens
// // These are NOT private, so this import works.
// import '../main.dart'; // For navigatorKey, flutterLocalNotificationsPlugin
// import '../Screens/MainScreen.dart'; // For HomeScreen
//
// // -------------------------------------------------------------------
// // [FIX]: The functions _showNotification and _navigateToOrder
// // have been moved from main.dart into this file.
// // Now, FcmService can see them because they are in the same file.
// // -------------------------------------------------------------------
//
// /// ✅ [MOVED FROM MAIN.DART]
// /// UNIVERSAL NOTIFICATION DISPLAY METHOD
// Future<void> _showNotification(RemoteMessage message) async {
//   String title = 'New Order';
//   String body = 'You have a new order';
//   Map<String, dynamic> data = {};
//
//   // Extract title and body from either notification or data payload
//   if (message.notification != null) {
//     title = message.notification?.title ?? title;
//     body = message.notification?.body ?? body;
//   }
//
//   // Data payload overrides notification payload if both exist
//   if (message.data.isNotEmpty) {
//     data = message.data;
//     title = data['title'] ?? title;
//     body = data['body'] ?? body;
//   }
//
//   debugPrint("Showing notification: $title - $body");
//
//   const AndroidNotificationDetails androidPlatformChannelSpecifics =
//   AndroidNotificationDetails(
//     'high_importance_channel', // ✅ MUST MATCH CLOUD FUNCTION
//     'High Importance Notifications',
//     channelDescription: 'This channel is used for important order notifications.',
//     importance: Importance.max,
//     priority: Priority.high,
//     showWhen: true,
//     autoCancel: true,
//     enableVibration: true,
//     playSound: true,
//     visibility: NotificationVisibility.public,
//   );
//
//   const DarwinNotificationDetails iosPlatformChannelSpecifics =
//   DarwinNotificationDetails(
//     presentAlert: true,
//     presentBadge: true,
//     presentSound: true,
//   );
//
//   const NotificationDetails platformChannelSpecifics = NotificationDetails(
//     android: androidPlatformChannelSpecifics,
//     iOS: iosPlatformChannelSpecifics,
//   );
//
//   // Generate unique ID for notification
//   final int notificationId =
//   DateTime.now().millisecondsSinceEpoch.remainder(100000);
//
//   // Use the global plugin instance from main.dart
//   await flutterLocalNotificationsPlugin.show(
//     notificationId,
//     title,
//     body,
//     platformChannelSpecifics,
//     payload: jsonEncode(data), // Pass all data as payload
//   );
//
//   debugPrint("✅ NOTIFICATION DISPLAYED: $title");
// }
//
// /// ✅ [MOVED FROM MAIN.DART]
// /// NAVIGATES TO THE ORDER SCREEN
// void _navigateToOrder(String orderId) {
//   // Use the global navigator key from main.dart
//   final context = navigatorKey.currentContext;
//   if (context != null) {
//     Navigator.of(context).pushAndRemoveUntil(
//       MaterialPageRoute(builder: (context) => HomeScreen()), // Or your order screen
//           (route) => false,
//     );
//
//     debugPrint("Should navigate to order: $orderId");
//   } else {
//     debugPrint("❌ Cannot navigate! Navigator context is null.");
//   }
// }
//
// // -------------------------------------------------------------------
// // Your FcmService class (Now it can find the functions above)
// // -------------------------------------------------------------------
//
// class FcmService {
//   final FirebaseMessaging _fcm = FirebaseMessaging.instance;
//   final FirebaseFirestore _db = FirebaseFirestore.instance;
//   bool _isInitialized = false;
//
//   Future<void> init(String adminEmail) async {
//     if (_isInitialized) return;
//
//     try {
//       // 1. Request permissions
//       NotificationSettings settings = await _fcm.requestPermission(
//         alert: true,
//         badge: true,
//         sound: true,
//         provisional: false,
//       );
//
//       debugPrint('FCM Permission: ${settings.authorizationStatus}');
//
//       // 2. Configure for all states
//       await _fcm.setForegroundNotificationPresentationOptions(
//         alert: true,
//         badge: true,
//         sound: true,
//       );
//
//       // 3. Get and save token
//       final token = await _fcm.getToken();
//       debugPrint("FCM Token: $token");
//
//       if (token != null && adminEmail.isNotEmpty) {
//         await _saveTokenToDatabase(adminEmail, token);
//
//         _fcm.onTokenRefresh.listen((newToken) async {
//           await _saveTokenToDatabase(adminEmail, newToken);
//         });
//       }
//
//       // 4. Setup message handlers for ALL states
//       await _setupUniversalMessageHandlers();
//
//       _isInitialized = true;
//       debugPrint("FCM Service: Universal initialization complete");
//     } catch (e) {
//       debugPrint("FCM Init error: $e");
//     }
//   }
//
//   Future<void> _setupUniversalMessageHandlers() async {
//     // ✅ 1. FOREGROUND MESSAGES (App open and visible)
//     FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
//       debugPrint('🔵 FOREGROUND MESSAGE RECEIVED');
//       debugPrint('Message Data: ${message.data}');
//
//       // Show notification immediately
//       // This will now correctly call the _showNotification function above
//       await _showNotification(message);
//
//       // Also show in-app dialog if needed
//       _handleInAppNotification(message);
//     });
//
//     // ✅ 2. BACKGROUND MESSAGES (App in background but not terminated)
//     FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
//       debugPrint('🟡 BACKGROUND MESSAGE OPENED APP');
//       debugPrint('Message Data: ${message.data}');
//
//       // App was in background and user tapped notification
//       _handleNotificationTap(message.data);
//     });
//
//     // ✅ 3. TERMINATED STATE (App completely closed)
//     final initialMessage = await _fcm.getInitialMessage();
//     if (initialMessage != null) {
//       debugPrint('🔴 APP LAUNCHED FROM TERMINATED STATE BY NOTIFICATION');
//
//       // Delay to ensure app is fully initialized
//       Future.delayed(const Duration(seconds: 2), () {
//         _handleNotificationTap(initialMessage.data);
//       });
//     }
//
//     debugPrint("✅ Universal message handlers registered for ALL app states");
//   }
//
//   void _handleInAppNotification(RemoteMessage message) {
//     // Show dialog or update UI when app is in foreground
//     final data = message.data;
//     if (data['type'] == 'new_order') {
//       _showNewOrderDialog(data);
//     }
//   }
//
//   void _showNewOrderDialog(Map<String, dynamic> data) {
//     // Uses the global navigatorKey from main.dart
//     final context = navigatorKey.currentContext;
//     if (context == null) return;
//
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: const Text('🎉 New Order Received!'),
//           content:
//           Text('Order #${data['orderNumber']} from ${data['customerName']}'),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.of(context).pop(),
//               child: const Text('Dismiss'),
//             ),
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//                 // This will now correctly call the _navigateToOrder function above
//                 _navigateToOrder(data['orderId']);
//               },
//               child: const Text('View Order'),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   void _handleNotificationTap(Map<String, dynamic> data) {
//     final orderId = data['orderId'];
//     if (orderId != null) {
//       // This will now correctly call the _navigateToOrder function above
//       _navigateToOrder(orderId);
//     }
//   }
//
//   Future<void> _saveTokenToDatabase(String adminEmail, String token) async {
//     try {
//       await _db.collection('staff').doc(adminEmail).set({
//         'fcmToken': token,
//         'fcmTokenUpdated': FieldValue.serverTimestamp(),
//       }, SetOptions(merge: true));
//
//       debugPrint("✅ FCM Token saved for $adminEmail");
//     } catch (e) {
//       debugPrint('❌ Error saving FCM token: $e');
//     }
//   }
// }
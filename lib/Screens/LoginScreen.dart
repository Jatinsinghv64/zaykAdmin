// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../Widgets/Authorization.dart';
// import '../main.dart';
// import 'MainScreen.dart';
//
// class LoginScreen extends StatefulWidget {
//   const LoginScreen({super.key});
//
//   @override
//   State<LoginScreen> createState() => _LoginScreenState();
// }
//
// class _LoginScreenState extends State<LoginScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   bool _isLoading = false;
//
//   @override
//   void dispose() {
//     _emailController.dispose();
//     _passwordController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _login() async {
//     if (_formKey.currentState!.validate()) {
//       setState(() => _isLoading = true);
// // Ensure AuthService is provided in your widget tree (e.g., using Provider)
//       final auth = Provider.of<AuthService>(context, listen: false);
//
//       try {
//         final user = await auth.signInWithEmailAndPassword(
//           _emailController.text.trim(),
//           _passwordController.text.trim(),
//         );
//
//         if (user != null) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text('Logged in as ${user.email}'),
//               backgroundColor: Colors.green,
//             ),
//           );
// // Navigate to the next screen or home page
//           Navigator.of(context).pushAndRemoveUntil(
//             MaterialPageRoute(builder: (context) => const MainScreen()),
//                 (Route<dynamic> route) => false,
//           );
//         }
// // If user is null here, it means an exception was caught earlier,
// // and a snackbar was already shown.
//       } on FirebaseAuthException catch (e) {
//         String errorMessage;
//         if (e.code == 'user-not-found') {
//           errorMessage = 'No user found for that email.';
//         } else if (e.code == 'wrong-password') {
//           errorMessage = 'Wrong password provided for that user.';
//         } else if (e.code == 'invalid-email') {
//           errorMessage = 'The email address is not valid.';
//         } else if (e.code == 'channel-error') {
//           errorMessage =
//           'Missing credentials. Please enter email and password.';
//         } else {
//           errorMessage = 'Login failed: ${e.message}';
//         }
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(errorMessage),
//             backgroundColor: Colors.red,
//           ),
//         );
//       } catch (e) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('An unexpected error occurred: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       } finally {
//         setState(() => _isLoading = false);
//       }
//     }
//   }
//
//   Future<void> _signInWithGoogle() async {
//     setState(() => _isLoading = true);
//     final auth = Provider.of<AuthService>(context, listen: false);
//
//     try {
//       final user = await auth.signInWithGoogle();
//
//       if (user != null) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Logged in with Google as ${user.email}'),
//             backgroundColor: Colors.green,
//           ),
//         );
// // Navigate to the next screen or home page
//         Navigator.of(context).pushAndRemoveUntil(
//           MaterialPageRoute(builder: (context) => const MainScreen()),
//               (Route<dynamic> route) => false,
//         );
//       } else {
// // This case might be hit if the user cancels the Google sign-in flow
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Google Sign-In cancelled or failed.'),
//             backgroundColor: Colors.orange,
//           ),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Google Sign-In failed: $e'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFF0B2546),
//       body: Center(
//         child: SingleChildScrollView(
// // Allows scrolling if keyboard appears
//           padding: const EdgeInsets.all(24.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
// // Your app logo or a prominent icon
//               Image.asset(
//                 'assets/admin.jpg',
//                 height: 100,
//                 width: 100,
//                 fit: BoxFit.contain,
//               ),
//               const SizedBox(height: 32),
//               Text(
//                 'Welcome Back!',
//                 style: Theme.of(context).textTheme.headlineMedium?.copyWith(
//                   fontWeight: FontWeight.bold,
//                   color: Colors.white,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 'Login to manage your restaurant',
//                 style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                   color: Colors.white,
//                 ),
//               ),
//               const SizedBox(height: 48),
//               Form(
//                 key: _formKey,
//                 child: Column(
//                   children: [
//                     TextFormField(
//                       controller: _emailController,
//                       decoration: InputDecoration(
//                         labelText: 'Email',
//                         hintText: 'Enter your email',
//                         prefixIcon: const Icon(Icons.email),
//                         labelStyle: const TextStyle(color: Colors.black),
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         enabledBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                           borderSide: BorderSide(color: Colors.grey.shade300),
//                         ),
//                         focusedBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                           borderSide: const BorderSide(
//                               color: Color(0xffdcde6b), width: 2),
//                         ),
//                         filled: true,
//                         fillColor: Colors.grey[50],
//                       ),
//                       keyboardType: TextInputType.emailAddress,
//                       validator: (value) {
//                         if (value == null || value.isEmpty) {
//                           return 'Please enter your email';
//                         }
//                         if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
//                           return 'Please enter a valid email';
//                         }
//                         return null;
//                       },
//                     ),
//                     const SizedBox(height: 20),
//                     TextFormField(
//                       controller: _passwordController,
//                       decoration: InputDecoration(
//                         labelText: 'Password',
//                         labelStyle: const TextStyle(color: Colors.black),
//                         hintText: 'Enter your password',
//                         prefixIcon: const Icon(Icons.lock),
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         enabledBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                           borderSide: BorderSide(color: Colors.grey.shade300),
//                         ),
//                         focusedBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                           borderSide: const BorderSide(
//                               color: Color(0xffdcde6b), width: 2),
//                         ),
//                         filled: true,
//                         fillColor: Colors.grey[50],
//                       ),
//                       obscureText: true,
//                       validator: (value) {
//                         if (value == null || value.isEmpty) {
//                           return 'Please enter your password';
//                         }
//                         if (value.length < 6) {
//                           return 'Password must be at least 6 characters';
//                         }
//                         return null;
//                       },
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 24),
//               SizedBox(
//                 width: double.infinity,
//                 child: _isLoading
//                     ? const Center(child: CircularProgressIndicator())
//                     : ElevatedButton(
//                   onPressed: _login,
//                   style: ElevatedButton.styleFrom(
//                     padding: const EdgeInsets.symmetric(vertical: 16),
//                     backgroundColor:
//                     const Color(0xffffffff), // Modern button color
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     elevation: 5,
//                   ),
//                   child: Text(
//                     'Login',
//                     style:
//                     Theme.of(context).textTheme.titleLarge?.copyWith(
//                       color: Colors.black,
// // backgroundColor: Color(0xffffffff), // backgroundColor is for Text widget, not ElevatedButton's child
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 24),
//               Text(
//                 'OR',
//                 style: Theme.of(context).textTheme.titleSmall?.copyWith(
//                   color: Colors.grey[500],
//                 ),
//               ),
//               const SizedBox(height: 24),
//               SizedBox(
//                 width: double.infinity,
//                 child: OutlinedButton.icon(
//                   onPressed: _isLoading ? null : _signInWithGoogle,
//                   icon: Image.asset(
//                     'assets/google_logo.png', // You'll need to add a Google logo asset
//                     height: 24.0,
//                   ),
//                   label: Text(
//                     'Continue with Google',
//                     style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                       color: Colors.white,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                   style: OutlinedButton.styleFrom(
//                     padding: const EdgeInsets.symmetric(vertical: 16),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     side:
//                     const BorderSide(color: Color(0xffffffff), width: 1.5),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 32),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
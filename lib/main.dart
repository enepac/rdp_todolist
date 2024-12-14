import 'package:flutter/material.dart'; // Import Material package for UI components.
import 'package:firebase_core/firebase_core.dart'; // Import Firebase Core for initialization.
import 'package:rdp_todolist/screens/home_page.dart'; // Import HomePage screen.
import 'firebase_options.dart'; // Import Firebase options for platform-specific configuration.

// Main function for the app.
void main() async {
  WidgetsFlutterBinding
      .ensureInitialized(); // Ensure proper binding before running the app.

  await Firebase.initializeApp(
    // Initialize Firebase with platform options.
    options:
        DefaultFirebaseOptions.currentPlatform, // Get current platform options.
  );

  runApp(const MainApp()); // Run the app starting with MainApp widget.
}

// MainApp widget for the app.
class MainApp extends StatelessWidget {
  // Main widget for the app.
  const MainApp({super.key}); // Constructor with optional key.

  @override
  Widget build(BuildContext context) {
    // Build the app's UI.
    return const MaterialApp(
      home: HomePage(), // Set HomePage as the home screen.
    );
  }
}

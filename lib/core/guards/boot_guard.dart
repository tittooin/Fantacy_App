import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// BootGuard prevents the "Death Loop" (Infinite Browser Reloads)
/// by detecting rapid consecutive restarts.
class BootGuard {
  static const String _keyBootTime = 'bg_last_boot';
  static const String _keyBootCount = 'bg_boot_count';
  
  static const int _thresholdSeconds = 10;
  static const int _maxRetries = 3;

  /// Checks if the app is safe to boot.
  /// Returns [true] if safe, [false] if blocked.
  static Future<bool> checkSafety(SharedPreferences prefs) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final lastBoot = prefs.getInt(_keyBootTime) ?? 0;
    int bootCount = prefs.getInt(_keyBootCount) ?? 0;

    final diff = (now - lastBoot) / 1000; // Seconds

    if (diff < _thresholdSeconds) {
      // Rapid Reboot Detected
      bootCount++;
      await prefs.setInt(_keyBootCount, bootCount);
      await prefs.setInt(_keyBootTime, now);

      if (bootCount >= _maxRetries) {
        // Block Boot
        return false;
      }
    } else {
      // Safe Reboot (Reset Counter)
      await prefs.setInt(_keyBootCount, 0);
      await prefs.setInt(_keyBootTime, now);
    }
    
    return true;
  }

  /// Clears the block (e.g., after a manual fix or timeout)
  static Future<void> reset(SharedPreferences prefs) async {
     await prefs.remove(_keyBootCount);
     await prefs.remove(_keyBootTime);
  }
}

/// A simple screen to show when Boot is blocked
class BootBlockedScreen extends StatelessWidget {
  final VoidCallback onReset;

  const BootBlockedScreen({super.key, required this.onReset});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.red.shade900,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.warning_amber_rounded, size: 80, color: Colors.white),
                const SizedBox(height: 24),
                const Text(
                  "Safety Lock Active",
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text(
                  "We detected an infinite reload loop. The app has been paused to protect your data and quota.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: onReset,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.red.shade900),
                  child: const Text("RESET & TRY AGAIN"),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

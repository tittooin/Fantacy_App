
import 'package:axevora11/core/constants/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class VersionCheckService {
  static final VersionCheckService _instance = VersionCheckService._internal();
  factory VersionCheckService() => _instance;
  VersionCheckService._internal();

  /// Checks Firestore `app_config/general` for `latest_version`.
  /// If remote > local, shows a dialog.
  Future<void> checkVersion(BuildContext context) async {
    if (kIsWeb) return; // Web doesn't need update checks (auto-updates)

    try {
      // 1. Get Local Version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      // 2. Get Remote Version
      final doc = await FirebaseFirestore.instance.collection('app_config').doc('general').get();
      if (!doc.exists) return;

      final data = doc.data();
      final latestVersion = data?['latest_version'] as String?;
      final forceUpdate = data?['force_update'] as bool? ?? false;
      final updateUrl = data?['update_url'] as String? ?? 'https://axevora11.in';

      if (latestVersion != null && _isUpdateAvailable(currentVersion, latestVersion)) {
        if (context.mounted) {
           _showUpdateDialog(context, latestVersion, forceUpdate, updateUrl);
        }
      }
    } catch (e) {
      debugPrint("Version Check Failed: $e");
    }
  }

  bool _isUpdateAvailable(String current, String latest) {
    // Simple string comparison for MVP (Assumes format x.y.z)
    // A better approach splits by '.' and compares integers.
    // E.g. 1.0.0 vs 1.0.1
    return current != latest; 
    // In production, use pub_semver or split logic.
  }

  void _showUpdateDialog(BuildContext context, String version, bool force, String url) {
    showDialog(
      context: context,
      barrierDismissible: !force,
      builder: (context) => WillPopScope(
        onWillPop: () async => !force,
        child: AlertDialog(
          backgroundColor: AppColors.secondaryBackground,
          title: const Text("New Update Available! 🚀", style: TextStyle(color: Colors.white)),
          content: Text(
            "A newer version ($version) of Axevora11 is available with better features and bug fixes.",
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            if (!force)
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Later", style: TextStyle(color: Colors.white38)),
              ),
            ElevatedButton(
              onPressed: () {
                launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentGreen),
              child: const Text("Update Now", style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }
}

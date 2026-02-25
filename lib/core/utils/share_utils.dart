import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class ShareUtils {
  static Future<void> shareMatchRoom({
    required String matchId,
    required String matchTitle,
    BuildContext? context,
  }) async {
    final String shareText = 
        "Join me on AxevoraLabs to discuss the live match: $matchTitle! 🏟️💬\n\n"
        "Enter the Global Room here: https://axevoralabs.com/room/$matchId\n\n"
        "#AxevoraLabs #SocialInteraction #LiveDiscussion";
    
    // Web-stable share: use mailto or simply copy to clipboard
    final Uri mailUri = Uri(
      scheme: 'mailto',
      queryParameters: {
        'subject': 'Join the Discussion on AxevoraLabs!',
        'body': shareText,
      },
    );

    if (await canLaunchUrl(mailUri)) {
      await launchUrl(mailUri);
    } else {
      // Fallback: Copy to clipboard
      await Clipboard.setData(ClipboardData(text: shareText));
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Link copied to clipboard! Share it with your friends.")),
        );
      }
    }
  }

  static Future<void> shareApp({BuildContext? context}) async {
    const String shareText = 
        "Check out AxevoraLabs – A Social Interaction Platform for live event discussions! 🚀✨\n"
        "Link: https://axevoralabs.com\n\n"
        "No betting, just pure social fun!";
    
    await Clipboard.setData(const ClipboardData(text: shareText));
    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("App link copied to clipboard!")),
      );
    }
  }

  static Widget shareButton({required VoidCallback onPressed}) {
    return IconButton(
      icon: const Icon(Icons.share_rounded, color: Colors.white),
      onPressed: onPressed,
      tooltip: 'Share',
    );
  }
}

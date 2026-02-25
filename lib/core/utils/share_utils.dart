import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';

class ShareUtils {
  static Future<void> shareMatchRoom({
    required String matchId,
    required String matchTitle,
    required BuildContext context,
  }) async {
    final String shareUrl = "https://axevoralabs.com/room/$matchId";
    final String shareText = 
        "Join me on AxevoraLabs to discuss the live match: $matchTitle! 🏟️💬\n\n"
        "Enter the Global Room here: $shareUrl\n\n"
        "#AxevoraLabs #SocialInteraction #LiveDiscussion";
    
    _showShareSheet(context, shareText, shareUrl);
  }

  static Future<void> shareApp({required BuildContext context}) async {
    const String shareUrl = "https://axevoralabs.com";
    const String shareText = 
        "Check out AxevoraLabs – A Social Interaction Platform for live event discussions! 🚀✨\n"
        "Link: $shareUrl\n\n"
        "No betting, just pure social fun!";
    
    _showShareSheet(context, shareText, shareUrl);
  }

  static void _showShareSheet(BuildContext context, String text, String url) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        decoration: const BoxDecoration(
          color: Color(0xFF121212),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Share to Social Platforms",
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 4,
              mainAxisSpacing: 24,
              crossAxisSpacing: 12,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _ShareOption(
                  icon: Icons.chat_bubble_outline,
                  label: "WhatsApp",
                  color: const Color(0xFF25D366),
                  onTap: () => _launchSocial("https://wa.me/?text=${Uri.encodeComponent(text)}"),
                ),
                _ShareOption(
                  icon: Icons.telegram_rounded,
                  label: "Telegram",
                  color: const Color(0xFF0088CC),
                  onTap: () => _launchSocial("https://t.me/share/url?url=${Uri.encodeComponent(url)}&text=${Uri.encodeComponent(text)}"),
                ),
                _ShareOption(
                  icon: Icons.close_rounded,
                  label: "X",
                  color: Colors.white,
                  onTap: () => _launchSocial("https://twitter.com/intent/tweet?text=${Uri.encodeComponent(text)}"),
                ),
                 _ShareOption(
                  icon: Icons.facebook_rounded,
                  label: "Facebook",
                  color: const Color(0xFF1877F2),
                  onTap: () => _launchSocial("https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(url)}"),
                ),
                 _ShareOption(
                  icon: Icons.business_center_rounded,
                  label: "LinkedIn",
                  color: const Color(0xFF0A66C2),
                  onTap: () => _launchSocial("https://www.linkedin.com/sharing/share-offsite/?url=${Uri.encodeComponent(url)}"),
                ),
                _ShareOption(
                  icon: Icons.reddit_rounded,
                  label: "Reddit",
                  color: const Color(0xFFFF4500),
                  onTap: () => _launchSocial("https://www.reddit.com/submit?url=${Uri.encodeComponent(url)}&title=${Uri.encodeComponent(text)}"),
                ),
                _ShareOption(
                  icon: Icons.interests_rounded,
                  label: "Pinterest",
                  color: const Color(0xFFE60023),
                  onTap: () => _launchSocial("https://pinterest.com/pin/create/button/?url=${Uri.encodeComponent(url)}&description=${Uri.encodeComponent(text)}"),
                ),
                _ShareOption(
                  icon: Icons.email_rounded,
                  label: "Email",
                  color: Colors.grey,
                  onTap: () => _launchSocial("mailto:?subject=${Uri.encodeComponent("Join AxevoraLabs")}&body=${Uri.encodeComponent(text)}"),
                ),
                _ShareOption(
                  icon: Icons.link_rounded,
                  label: "Copy",
                  color: Colors.blue,
                  onTap: () async {
                    await Clipboard.setData(ClipboardData(text: text));
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Link copied to clipboard!")),
                      );
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  static Future<void> _launchSocial(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
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

class _ShareOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ShareOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

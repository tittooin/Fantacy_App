import 'package:flutter/material.dart';
import 'package:axevora11/features/legal/presentation/widgets/legal_page_scaffold.dart';

// 1. Terms & Conditions
class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalPageScaffold(
      title: "Terms & Conditions",
      children: [
        LegalSection(
          title: "AxevoraLabs Terms",
          content: "AxevoraLabs ek social interaction platform hai jiska purpose discussion aur interaction hai.\n\nUsers agree that:\n• Platform betting ya gambling ke liye use nahi hoga\n• Koi monetary winning ya rewards available nahi hain\n• Stats, rankings aur comparisons sirf informational hain",
        ),
        LegalSection(
          title: "Private Rooms",
          content: "• Invite-only hote hain\n• Host ke paas moderation rights hote hain",
        ),
        LegalSection(
          title: "Violation hone par",
          content: "• Room access restrict kiya ja sakta hai\n• Account suspend kiya ja sakta hai",
        ),
      ],
    );
  }
}

// 2. Privacy Policy
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalPageScaffold(
      title: "Privacy Policy",
      children: [
        LegalSection(
          title: "Nature of Platform",
          content: "AxevoraLabs ek social interaction platform hai.",
        ),
        LegalSection(
          title: "We collect",
          content: "• Google account basic profile information (name, email, avatar)\n• Room participation data\n• Chat messages (text only)",
        ),
        LegalSection(
          title: "We DO NOT",
          content: "• Store voice recordings\n• Store audio files\n• Support betting or gambling\n• Support cash rewards or withdrawals",
        ),
        LegalSection(
          title: "Voice interactions",
          content: "• Voice notes aur voice chat real-time hote hain\n• Voice data kisi bhi server par record ya store nahi hota\n\nUser data sirf platform functionality ke liye use hota hai.",
        ),
      ],
    );
  }
}

// 3. Community Guidelines
class CommunityGuidelinesScreen extends StatelessWidget {
  const CommunityGuidelinesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalPageScaffold(
      title: "Community Guidelines",
      children: [
        LegalSection(
          title: "Respectful Interaction",
          content: "AxevoraLabs respectful interaction ko promote karta hai.",
        ),
        LegalSection(
          title: "Allowed",
          content: "• Friendly discussion\n• Sports aur events par opinions\n• Healthy debates",
        ),
        LegalSection(
          title: "Not allowed",
          content: "• Abuse\n• Hate speech\n• Spam\n• Harassment\n• Illegal content\n\nVoice aur chat dono par same rules apply hote hain.",
        ),
      ],
    );
  }
}

// 4. About Us
class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalPageScaffold(
      title: "About Us",
      children: [
        LegalSection(
          title: "Our Mission",
          content: "AxevoraLabs ek social interaction platform hai jo users ko live events aur shared interests ke around connect karta hai.",
        ),
        LegalSection(
          title: "Our Focus",
          content: "• Real-time discussions\n• Private group interactions\n• Safe, non-monetary experience\n\nCricket humari pehli category hai, aur future me aur categories add ki jaayengi.",
        ),
      ],
    );
  }
}

// 5. Contact Us
class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalPageScaffold(
      title: "Contact Us",
      children: [
        LegalSection(
          title: "Support",
          content: "For support or queries:\nEmail: support@axevoralabs.com\n\nWe usually respond within 24–48 hours.",
        ),
      ],
    );
  }
}

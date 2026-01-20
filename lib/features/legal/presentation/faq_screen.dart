import 'package:flutter/material.dart';
import 'package:axevora11/features/legal/presentation/widgets/legal_page_scaffold.dart';

class FAQScreen extends StatelessWidget {
  const FAQScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalPageScaffold(
      title: "Frequently Asked Questions",
      children: [
        LegalSection(
          title: "1. Is Axevora11 Legal?",
          content: "Yes, Axevora11 is a 100% Skill-Based platform. According to Supreme Court rulings, fantasy sports where success depends on knowledge and skill are legal businesses and protected under Article 19(1)(g) of the Constitution of India.",
        ),
        LegalSection(
          title: "2. Is this Gambling?",
          content: "No. Axevora11 strictly prohibits gambling, betting, or chance-based games. You cannot bet on match outcomes. You create a team of real players, and points are awarded based on their actual on-field performance.",
        ),
        LegalSection(
          title: "3. How does Scoring Work?",
          content: "Points are awarded for runs, wickets, catches, etc. The detailed point system is available in the 'Point System' tab. Scores are updated on an 'End of Over' basis from official data sources.",
        ),
        LegalSection(
          title: "4. Withdrawal Rules",
          content: "You can withdraw your 'Winnings' balance only. 'Deposit' and 'Bonus' cash cannot be withdrawn. You must verify your Bank Account and PAN Card (KYC) before requesting a withdrawal. Withdrawals are processed after the match is completed.",
        ),
        LegalSection(
          title: "5. Contact Support",
          content: "For any queries, please email us at admin@axevora.com. WhatsApp and Telegram support are coming soon.",
        ),
      ],
    );
  }
}

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
          title: "1. Nature of the Platform",
          content: "Axevora11 ek pure SKILL-BASED fantasy sports platform hai. Isme kisi bhi tarah ka gambling, betting, ya chance-based gameplay include nahi hai. Har contest ka result user ki cricket knowledge aur player selection skills par depend karta hai.",
        ),
        LegalSection(
          title: "2. Eligibility (18+ Only)",
          content: "Axevora11 par khelne ke liye aapki age kam se kam 18 saal honi chahiye. Minor users is platform ko use karne ke liye authorized nahi hain.",
        ),
        LegalSection(
          title: "3. Restricted States",
          content: "India ke kuch states (jaise Assam, Odisha, Telangana, Nagaland, Sikkim, Andhra Pradesh) me real-money fantasy sports restrict hain. Agar aap in states se hain, toh aap paid contests me join nahi kar sakte.",
        ),
        LegalSection(
          title: "4. Entry Fee & Participation",
          content: "Contest me join hone ke liye dee gayi raashi (Entry Fee) ko participation charge mana jayega. Winning amount ka distribution sirf factual scoring ke basis par hoga.",
        ),
        LegalSection(
          title: "5. Scoring & Admin Decisions",
          content: "Points real match events aur factual scoring ke basis par calculate hote hain. Match ka status (Upcoming, Live, Completed) admin ke control me hota hai aur factual situations ke hisaab se update kiya jata hai.",
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
          title: "1. Data We Collect",
          content: "Hum aapki basic profile info jaise mobile number, location (geo-blocking verify karne ke liye), aur unique device IDs collect karte hain taaki aapko safe experience mil sake.",
        ),
        LegalSection(
          title: "2. Purpose of Collection",
          content: "Aapka data platform ko maintain karne, fraud rokne, aur legal compliance (jaise restricted state checks) verify karne ke liye use hota hai.",
        ),
        LegalSection(
          title: "3. Secure Payments",
          content: "Saare payments third-party payment gateways (jaise Cashfree) ke through handle kiye jaate hain. Axevora11 aapke sensitive payment data (like card numbers, CVV) ko store nahi karta.",
        ),
        LegalSection(
          title: "4. Data Protection",
          content: "Aapka data secure rahta hai aur ise sirf law ke under hi share kiya jata hai.",
        ),
      ],
    );
  }
}

// 3. Refund & Cancellation Policy
class RefundPolicyScreen extends StatelessWidget {
  const RefundPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalPageScaffold(
      title: "Refund & Cancellation",
      children: [
        LegalSection(
          title: "1. Entry Fee Non-Refundable",
          content: "Ek baar aapne contest join kar liya, toh entry fee non-refundable hoti hai. Kripya apni team aur contest carefully select karein.",
        ),
        LegalSection(
          title: "2. Contest Cancellation",
          content: "Agar koi match ya contest Axevora11 ya system error ki wajah se cancel hota hai, toh aapki poori entry fee aapke wallet me refund kar di jayegi.",
        ),
        LegalSection(
          title: "3. User Verification & Withdrawals",
          content: "Winnings ka withdrawal sirf verified users ke liye available hai. Withdrawal request process hone ka time banking aur gateway timelines par depend karta hai.",
        ),
      ],
    );
  }
}

// 4. Fair Play & Skill-Based Declaration
class FairPlayScreen extends StatelessWidget {
  const FairPlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalPageScaffold(
      title: "Fair Play & Skill-Based Declaration",
      children: [
        LegalSection(
          title: "1. Purely Skill-Based",
          content: "Axevora11 poori tarah se skill-based platform hai. Yahan koi random outcome ya chance-based rewards nahi hain. Aapki jeet aapki cricket ki samajh aur selection skill par depend karti hai.",
        ),
        LegalSection(
          title: "2. Real Match Events",
          content: "Aapke fantasy points real cricket match ke events par based hote hain. Hum transparency aur fairness ke prati committed hain.",
        ),
        LegalSection(
          title: "3. Commitment to Fairness",
          content: "Hum hardware-level bots ko allow nahi karte aur har user ko ek level playing field pradaan karne ki koshish karte hain.",
        ),
      ],
    );
  }
}

// 5. Responsible Play & 18+ Policy
class ResponsiblePlayScreen extends StatelessWidget {
  const ResponsiblePlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalPageScaffold(
      title: "Responsible Play",
      children: [
        LegalSection(
          title: "1. Age Limit (18+)",
          content: "Axevora11 par sirf 18 saal ya usse badi age ke log hi participate kar sakte hain. Yeh platform minors ke liye nahi hai.",
        ),
        LegalSection(
          title: "2. Play Responsibly",
          content: "Hum aapko 'Samajhdari se khele' (Play Responsibly) ke liye encourage karte hain. Is game ko entertainement ke liye hi dekhen.",
        ),
        LegalSection(
          title: "3. No Financial Dependency",
          content: "Axevora11 kisi bhi tarah ki financial dependency ko promote nahi karta. Har user ko apni financial limits me hi khelna chahiye.",
        ),
        LegalSection(
          title: "4. Right to Restrict",
          content: "Agar koi user platform ka misuse karte huye paya gaya, toh Axevora11 ke paas unka account restrict ya suspend karne ka adhikaar hai.",
        ),
      ],
    );
  }
}

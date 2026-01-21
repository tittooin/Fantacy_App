import 'package:flutter/material.dart';
import 'package:axevora11/features/legal/presentation/widgets/legal_page_scaffold.dart';

// 1. Terms & Conditions
class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalPageScaffold(
      title: "Terms & Conditions / नियम और शर्तें",
      children: [
        LegalSection(
          title: "1. Nature of the Platform / प्लेटफ़ॉर्म की प्रकृति",
          content: "Axevora11 is a purely SKILL-BASED fantasy sports platform. It involves selecting players based on knowledge and analysis. WE DO NOT support gambling, betting, or any chance-based games.\n\nAxevora11 पूरी तरह से कौशल-आधारित (Skill-Based) फैंटेसी स्पोर्ट्स प्लेटफ़ॉर्म है। इसमें खिलाड़ियों का चयन ज्ञान और विश्लेषण के आधार पर किया जाता है। हम जुआ, सट्टेबाजी या किसी भी किस्मत-आधारित खेल का समर्थन नहीं करते हैं।",
        ),
        LegalSection(
          title: "2. Eligibility / योग्यता (18+)",
          content: "Users must be at least 18 years old to participate. Minors are strictly prohibited. By joining, you confirm that you are of legal age.\n\nभाग लेने के लिए उपयोगकर्ताओं की आयु कम से कम 18 वर्ष होनी चाहिए। नाबालिगों का खेलना सख्त मना है। शामिल होकर, आप पुष्टि करते हैं कि आप कानूनी उम्र के हैं।",
        ),
        LegalSection(
          title: "3. Restricted States / प्रतिबंधित राज्य",
          content: "Residents of Assam, Odisha, Telangana, Nagaland, Sikkim, and Andhra Pradesh are NOT allowed to join paid contests due to state laws. You may play free practice contests only.\n\nअसम, ओडिशा, तेलंगाना, नागालैंड, सिक्किम और आंध्र प्रदेश के निवासी राज्य के कानूनों के कारण भुगतान वाले (Paid) कॉन्टेस्ट में शामिल नहीं हो सकते। आप केवल मुफ्त अभ्यास कॉन्टेस्ट खेल सकते हैं।",
        ),
        LegalSection(
          title: "4. Account Security / खाता सुरक्षा",
          content: "You are responsible for maintaining the confidentiality of your account credentials. Axevora11 is not liable for any loss due to unauthorized access.\n\nअपने खाते की सुरक्षा (पासवर्ड/OTP) बनाए रखने की जिम्मेदारी आपकी है। अनधिकृत पहुंच के कारण होने वाले किसी भी नुकसान के लिए Axevora11 जिम्मेदार नहीं है।",
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
      title: "Privacy Policy / गोपनीयता नीति",
      children: [
        LegalSection(
          title: "1. Data We Collect / हम क्या डेटा लेते हैं?",
          content: "We collect basic information like Mobile Number, Email ID, and Location Data. This is required for User Verification (KYC) and to enforce State Restrictions (Geo-blocking).\n\nहम मोबाइल नंबर, ईमेल आईडी और स्थान (Location) जैसी बुनियादी जानकारी एकत्र करते हैं। इसकी आवश्यकता उपयोगकर्ता सत्यापन (KYC) और राज्य प्रतिबंधों (Geo-blocking) को लागू करने के लिए होती है।",
        ),
        LegalSection(
          title: "2. Usage of Data / डेटा का उपयोग",
          content: "Your data is used strictly to assist you in gameplay, process withdrawals, and verify legal compliance. We do not sell your personal data to third parties.\n\nआपके डेटा का उपयोग केवल गेमप्ले, निकासी (Withdrawal) प्रक्रिया, और कानूनी अनुपालन को सत्यापित करने के लिए किया जाता है। हम आपका व्यक्तिगत डेटा किसी तीसरे पक्ष को नहीं बेचते।",
        ),
        LegalSection(
          title: "3. Payment Security / भुगतान सुरक्षा",
          content: "All transactions are processed via secure portals (Cashfree/Razorpay). Axevora11 DOES NOT store your Credit Card, Debit Card, or Net Banking passwords.\n\nसभी लेन-देन सुरक्षित पोर्टल्स (Cashfree/Razorpay) के माध्यम से संसाधित होते हैं। Axevora11 आपके क्रेडिट कार्ड, डेबिट कार्ड या नेट बैंकिंग पासवर्ड को स्टोर नहीं करता है।",
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
      title: "Refund Policy / धन वापसी नीति",
      children: [
        LegalSection(
          title: "1. Contest Entry Fee / प्रवेश शुल्क",
          content: "Once you join a contest, the Entry Fee is generally NON-REFUNDABLE. This is because your participation reserves a spot that others cannot take.\n\nएक बार जब आप कॉन्टेस्ट जॉइन कर लेते हैं, तो प्रवेश शुल्क आमतौर पर नॉन-रिफंडेबल (वापस न होने वाला) होता है। क्योंकि आपकी भागीदारी एक स्लॉट आरक्षित करती है जिसे कोई अन्य नहीं ले सकता।",
        ),
        LegalSection(
          title: "2. Abandoned Matches / रद्द हुए मैच",
          content: "If a real cricket match is abandoned or cancelled (No Result), the specific contest will be cancelled, and your FULL Entry Fee will be refunded to your wallet instantly.\n\nयदि कोई वास्तविक क्रिकेट मैच रद्द (Abandoned) हो जाता है, तो उस कॉन्टेस्ट को रद्द कर दिया जाएगा और आपका पूरा प्रवेश शुल्क आपके वॉलेट में तुरंत वापस कर दिया जाएगा।",
        ),
        LegalSection(
          title: "3. Transaction Failures / विफल लेनदेन",
          content: "If money is deducted from your bank but not added to your Axevora11 wallet, it is usually refunded by the bank within 5-7 working days automatically.\n\nयदि आपके बैंक से पैसे कट गए हैं लेकिन वॉलेट में नहीं जुड़े हैं, तो आमतौर पर बैंक द्वारा 5-7 कार्य दिवसों के भीतर इसे स्वचालित रूप से वापस कर दिया जाता है।",
        ),
      ],
    );
  }
}

// 4. Fair Play & Point System
class FairPlayScreen extends StatelessWidget {
  const FairPlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalPageScaffold(
      title: "Fair Play & Points / निष्पक्ष खेल और अंक",
      children: [
        LegalSection(
          title: "1. How To Play? / कैसे खेलें?",
          content: "• Create a Team of 11 Players from both squads.\n• Maximum 7 players from one team.\n• Choose 1 Captain (2x Points) and 1 Vice-Captain (1.5x Points).\n• Join Contests within your budget.\n\n• दोनों टीमों के खिलाड़ियों को मिलाकर 11 खिलाड़ियों की टीम बनाएं।\n• एक टीम से अधिकतम 7 खिलाड़ी ले सकते हैं।\n• 1 कप्तान (2 गुना अंक) और 1 उप-कप्तान (1.5 गुना अंक) चुनें।\n• अपने बजट के अनुसार कॉन्टेस्ट जॉइन करें।",
        ),
        LegalSection(
          title: "2. Point System (Batting) / बल्लेबाजी अंक",
          content: "• Run Scored: +1 Point\n• Boundary (4): +1 Bonus\n• Six (6): +2 Bonus\n• Half Century (50): +8 Bonus\n• Century (100): +16 Bonus\n• Duck (0 runs): -2 Points (Only for Batsman/WK/AR)\n\n• रन: +1 अंक\n• चौका (4): +1 बोनस\n• छक्का (6): +2 बोनस\n• अर्धशतक (50): +8 बोनस\n• शतक (100): +16 बोनस\n• शून्य (Duck): -2 अंक",
        ),
        LegalSection(
          title: "3. Point System (Bowling) / गेंदबाजी अंक",
          content: "• Wicket: +25 Points\n• Maiden Over: +8 Bonus\n• LBW / Bowled Bonus: +8 Bonus\n• 4 Wicket Haul: +8 Bonus\n• 5 Wicket Haul: +16 Bonus\n\n• विकेट: +25 अंक\n• मेडन ओवर: +8 बोनस\n• LBW / बोल्ड: +8 बोनस\n• 4 विकेट हॉल: +8 बोनस\n• 5 विकेट हॉल: +16 बोनस",
        ),
        LegalSection(
          title: "4. Fielding & Economy / फील्डिंग और अन्य",
          content: "• Catch: +8 Points\n• Stumping: +12 Points\n• Run Out: +6 Points\n\n• कैच: +8 अंक\n• स्टम्पिंग: +12 अंक\n• रन आउट: +6 अंक",
        ),
        LegalSection(
          title: "5. Important Rules / महत्वपूर्ण नियम",
          content: "• Only players in the 'Playing XI' earn points.\n• Substitutes do not earn points.\n• Super Over points are not counted.\n\n• केवल 'Playing XI' (खेल रहे 11) खिलाड़ी ही अंक अर्जित करते हैं।\n• सब्स्टिट्यूट खिलाड़ियों को अंक नहीं मिलते।\n• सुपर ओवर के अंक नहीं गिने जाते।",
        ),
      ],
    );
  }
}

// 5. Responsible Play
class ResponsiblePlayScreen extends StatelessWidget {
  const ResponsiblePlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalPageScaffold(
      title: "Responsible Play / जिम्मेदारी से खेलें",
      children: [
        LegalSection(
          title: "1. Financial Risk / वित्तीय जोखिम",
          content: "Fantasy sports involves a financial risk. You may lose the money you deposit. PLEASE PLAY RESPONSIBLY and at your own risk. Do not play with money you cannot afford to lose.\n\nफैंटेसी स्पोर्ट्स में वित्तीय जोखिम शामिल है। आप जो पैसा जमा करते हैं उसे हार भी सकते हैं। कृपया जिम्मेदारी से और अपने जोखिम पर खेलें। उस पैसे से न खेलें जिसे आप खोना बर्दाश्त नहीं कर सकते।",
        ),
        LegalSection(
          title: "2. No Addiction / लत से बचें",
          content: "Treat this as entertainment, not a source of income. If you feel addicted, please take a break or stop playing.\n\nइसे मनोरंजन के रूप में लें, आय के स्रोत के रूप में नहीं। यदि आपको लत लग रही है, तो कृपया ब्रेक लें या खेलना बंद करें।",
        ),
        LegalSection(
          title: "3. Age Verification / आयु सत्यापन",
          content: "We enforce strict age verification. Any user found below 18 years will be banned and funds forfeited.\n\nहम सख्त आयु सत्यापन लागू करते हैं। 18 वर्ष से कम आयु के किसी भी उपयोगकर्ता को बैन कर दिया जाएगा।",
        ),
      ],
    );
  }
}

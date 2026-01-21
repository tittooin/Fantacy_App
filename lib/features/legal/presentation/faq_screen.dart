import 'package:flutter/material.dart';
import 'package:axevora11/features/legal/presentation/widgets/legal_page_scaffold.dart';

class FAQScreen extends StatelessWidget {
  const FAQScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalPageScaffold(
      title: "FAQs / अक्सर पूछे जाने वाले प्रश्न",
      children: [
        LegalSection(
          title: "1. Is Axevora11 Legal? / क्या Axevora11 कानूनी है?",
          content: "Yes, Axevora11 is a 100% Skill-Based platform. Fantasy sports are protected under Article 19(1)(g) of the Constitution of India. Success depends on your knowledge, not luck.\n\nहाँ, Axevora11 100% कौशल-आधारित प्लेटफ़ॉर्म है। भारत के संविधान के अनुच्छेद 19(1)(g) के तहत फैंटेसी स्पोर्ट्स सुरक्षित है। यहाँ सफलता आपकी जानकारी और कौशल पर निर्भर करती है, किस्मत पर नहीं।",
        ),
        LegalSection(
          title: "2. Is this Gambling? / क्या यह जुआ है?",
          content: "No. Axevora11 prohibits gambling or betting. You create a team based on real-life player performance. You analyze stats and pitch conditions to win, which makes it a Game of Skill.\n\nनहीं। Axevora11 जुआ या सट्टेबाजी को सख्ती से प्रतिबंधित करता है। आप वास्तविक खिलाड़ियों के प्रदर्शन के आधार पर टीम बनाते हैं। जीतने के लिए आप आंकड़ों और पिच की स्थिति का विश्लेषण करते हैं, जो इसे 'कौशल का खेल' बनाता है।",
        ),
        LegalSection(
          title: "3. How does Scoring Work? / पॉइंट सिस्टम कैसे काम करता है?",
          content: "Points are awarded for runs, wickets, catches, etc. Check the 'Fair Play' page for the detailed table. Scores are updated shortly after the real match event.\n\nरन, विकेट, कैच आदि के लिए अंक दिए जाते हैं। विस्तृत तालिका के लिए 'Fair Play' (निष्पक्ष खेल) पेज देखें। वास्तविक मैच घटना के कुछ ही समय बाद स्कोर अपडेट किए जाते हैं।",
        ),
        LegalSection(
          title: "4. Withdrawal Rules / निकासी नियम",
          content: "You can withdraw your 'Winnings' balance only. KYC (PAN & Bank) verification is mandatory. 'Deposit' and 'Bonus' cash cannot be withdrawn directly.\n\nआप केवल अपनी 'Winnings' (जीत की राशि) निकाल सकते हैं। KYC (पैन और बैंक) सत्यापन अनिवार्य है। 'Deposit' और 'Bonus' कैश को सीधे नहीं निकाला जा सकता।",
        ),
        LegalSection(
          title: "5. Why is my state restricted? / मेरा राज्य प्रतिबंधित क्यों है?",
          content: "State laws in Assam, Odisha, Telangana, Nagaland, Sikkim, and Andhra Pradesh do not permit paid fantasy sports. We respect Indian laws and restrict paid contests in these regions.\n\nअसम, ओडिशा, तेलंगाना, नागालैंड, सिक्किम और आंध्र प्रदेश के राज्य कानून भुगतान वाले फैंटेसी स्पोर्ट्स की अनुमति नहीं देते हैं। हम भारतीय कानूनों का सम्मान करते हैं और इन क्षेत्रों में पेड कॉन्टेस्ट को प्रतिबंधित करते हैं।",
        ),
        LegalSection(
          title: "6. Contact Support / सहायता संपर्क",
          content: "For any issues, email us at admin@axevora.com. We are happy to help!\n\nकिसी भी समस्या के लिए, हमें admin@axevora.com पर ईमेल करें। हमें आपकी मदद करने में खुशी होगी!",
        ),
      ],
    );
  }
}

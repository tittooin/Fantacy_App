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
          content: "AxevoraLabs is a Social Interaction platform. Our Category features are protected under relevant laws as Skill-Based interactions. Success depends on your knowledge and discussion metrics.\n\nAxevoraLabs एक सोशल इंटरैक्शन प्लेटफ़ॉर्म है। हमारे फीचर्स कानूनों के तहत कौशल-आधारित (Skill-Based) इंटरैक्शन के रूप में सुरक्षित हैं। यहाँ सफलता आपकी जानकारी और चर्चा के मापदंडों पर निर्भर करती है।",
        ),
        LegalSection(
          title: "2. Is this Gambling? / क्या यह जुआ है?",
          content: "No. AxevoraLabs prohibits gambling or betting. You create teams based on real-life player performance for discussion purposes. You analyze stats and conditions to engage, which makes it a Game of Skill.\n\nनहीं। AxevoraLabs जुआ या सट्टेबाजी को सख्ती से प्रतिबंधित करता है। आप चर्चा के लिए वास्तविक खिलाड़ियों के प्रदर्शन के आधार पर टीम बनाते हैं। जुड़ने के लिए आप आंकड़ों और स्थिति का विश्लेषण करते हैं, जो इसे 'कौशल का खेल' बनाता है।",
        ),
        LegalSection(
          title: "3. How does Scoring Work? / पॉइंट सिस्टम कैसे काम करता है?",
          content: "Informational Stats are awarded for runs, wickets, catches, etc. Check the 'Fair Play' page for the detailed table. Stats are updated shortly after the real match event.\n\nरन, विकेट, कैच आदि के लिए अंक दिए जाते हैं। विस्तृत तालिका के लिए 'Fair Play' (निष्पक्ष खेल) पेज देखें। वास्तविक मैच घटना के कुछ ही समय बाद स्कोर अपडेट किए जाते हैं।",
        ),
        LegalSection(
          title: "4. Withdrawal Rules / निकासी नियम",
          content: "Coupons and Vouchers are managed by individual hosts. The platform serves only as a facilitator for social rewards. Check the 'Social Fair Play' page for guidelines.\n\nकूपन और वाउचर व्यक्तिगत होस्ट द्वारा प्रबंधित किए जाते हैं। प्लेटफ़ॉर्म केवल सामाजिक पुरस्कारों के लिए एक सुविधा के रूप में कार्य करता है। दिशानिर्देशों के लिए 'सोशल फेयर प्ले' पेज देखें।",
        ),
        LegalSection(
          title: "5. Why is my state restricted? / मेरा राज्य प्रतिबंधित क्यों है?",
          content: "Interaction Hubs allow users to engage in deep discussions. Some rooms may have specific entry criteria as set by the host. We respect all regional laws regarding social platforms.\n\nइंटरैक्शन हब उपयोगकर्ताओं को चर्चा करने की अनुमति देते हैं। होस्ट द्वारा निर्धारित कुछ कमरों में विशिष्ट प्रवेश मानदंड हो सकते हैं। हम सोशल प्लेटफॉर्म के संबंध में सभी क्षेत्रीय कानूनों का सम्मान करते हैं।",
        ),
        LegalSection(
          title: "6. Contact Support / सहायता संपर्क",
          content: "For any issues, email us at admin@axevoralabs.com. We are happy to help!\n\nकिसी भी समस्या के लिए, हमें admin@axevoralabs.com पर ईमेल करें। हमें आपकी मदद करने में खुशी होगी!",
        ),
      ],
    );
  }
}

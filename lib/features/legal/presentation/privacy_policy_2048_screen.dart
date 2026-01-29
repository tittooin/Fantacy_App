import 'package:flutter/material.dart';

class PrivacyPolicy2048Screen extends StatelessWidget {
  const PrivacyPolicy2048Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Privacy Policy", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Privacy Policy",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text("Effective Date: 2024-01-28", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            _buildSection("1. Introduction", 
                "Welcome to 2048 Saga: Jewel Puzzle (\"we,\" \"our,\" or \"us\"). We are committed to protecting your privacy. This Privacy Policy explains how we collect, use, and share your information when you use our mobile application."),
            _buildSection("2. Information We Collect", 
                "We do not knowingly collect any personally identifiable information (PII) such as your name, address, or phone number. However, we use third-party services that may collect information used to identify you."),
             _buildSubSurface("A. Device & Usage Information", 
                "When you use our app, we (and our third-party partners) may automatically collect:\n• Device Model & Manufacturer\n• Operating System version\n• Advertising ID (GAID/IDFA)\n• IP Address (Approximate location)\n• Gameplay data (Levels unlocked, coins earned)\n• App crash logs and performance data"),
            _buildSection("3. Third-Party Services", 
                "We use the following third-party services which have their own privacy policies:\n\n• Google AdMob: Used to display banner, interstitial, and rewarded ads.\n• Google Analytics for Firebase: Used to understand how users interact with our app and to improve performance."),
            _buildSection("4. How We Use Your Information", 
                "We use the collected data for the following purposes:\n\n• To provide and maintain our Service.\n• To display personalized advertisements (via AdMob).\n• To monitor the usage of our Service and detect technical issues.\n• To save your game progress securely (via Firebase)."),
            _buildSection("5. Children’s Privacy", 
                "Our Service does not address anyone under the age of 13. We do not knowingly collect personally identifiable information from children under 13. If you are a parent or guardian and you are aware that your child has provided us with personal information, please contact us so that we will be able to do necessary actions."),
            _buildSection("6. Changes to This Privacy Policy", 
                "We may update our Privacy Policy from time to time. Thus, you are advised to review this page periodically for any changes. We will notify you of any changes by posting the new Privacy Policy on this page."),
            _buildSection("7. Contact Us", 
                "If you have any questions or suggestions about our Privacy Policy, do not hesitate to contact us at: admin@axevora.com"),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _buildSubSurface(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0, left: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.black54)),
        ],
      ),
    );
  }
}

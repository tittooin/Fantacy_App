import 'package:flutter/material.dart';
import 'package:axevora11/core/constants/app_colors.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Contact Us"), backgroundColor: Colors.indigo, foregroundColor: Colors.white),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(Icons.support_agent, size: 80, color: Colors.indigo),
            const SizedBox(height: 24),
            const Text(
              "We are here to help!",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "For any queries regarding gameplay, withdrawals, or account issues, please reach out to us.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 48),
            Card(
              elevation: 2,
              child: ListTile(
                leading: const Icon(Icons.email, color: Colors.indigo),
                title: const Text("Email Support"),
                subtitle: const Text("admin@axevora.com"),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              child: ListTile(
                leading: const Icon(Icons.chat, color: Colors.green),
                title: const Text("WhatsApp & Telegram"),
                subtitle: const Text("Support coming soon"),
              ),
            ),
            const Spacer(),
            const Text(
              "Axevora11 Support Team", 
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white24)
            ),
          ],
        ),
      ),
    );
  }
}

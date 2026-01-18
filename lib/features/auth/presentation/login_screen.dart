
import 'package:axevora11/core/constants/app_colors.dart';
import 'package:axevora11/features/auth/data/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _isLoading = false;
  String? _verificationId;
  bool _codeSent = false;

  void _verifyPhone() async {
    final phone = _phoneController.text.trim();
    if (phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid Phone Number")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.verifyPhoneNumber(
        phoneNumber: '+91$phone',
        verificationCompleted: (credential) async {
           // Auto-resolution (Android only)
           await authRepo.signInWithCredential(credential);
        },
        verificationFailed: (e) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed: ${e.message}")));
        },
        codeSent: (verificationId, resendToken) {
          setState(() {
            _verificationId = verificationId;
            _codeSent = true;
            _isLoading = false;
          });
        },
        codeAutoRetrievalTimeout: (verificationId) {
           _verificationId = verificationId;
        },
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _verifyOTP() async {
     final otp = _otpController.text.trim();
     if (otp.length != 6 || _verificationId == null) {
        return;
     }
     
     setState(() => _isLoading = true);
     
     try {
       final credential = PhoneAuthProvider.credential(
         verificationId: _verificationId!,
         smsCode: otp,
       );
       await ref.read(authRepositoryProvider).signInWithCredential(credential);
       // User state listener in main will handle navigation
     } catch (e) {
       setState(() => _isLoading = false);
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Invalid OTP")));
     }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.sports_cricket, size: 80, color: AppColors.accentGreen),
              const SizedBox(height: 16),
              Text(
                "AXEVORA11",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displayLarge?.copyWith(letterSpacing: 2),
              ),
              const SizedBox(height: 40),
              
              if (!_codeSent) ...[
                Text(
                  "Enter Mobile Number",
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    prefixText: "+91 ",
                    prefixStyle: const TextStyle(color: AppColors.accentGreen, fontWeight: FontWeight.bold),
                    filled: true,
                    fillColor: AppColors.secondaryBackground,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _verifyPhone,
                  child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.black) 
                      : const Text("GET OTP"),
                ),
              ] else ...[
                 Text(
                  "Enter OTP sent to +91 ${_phoneController.text}",
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white, letterSpacing: 8, fontSize: 24),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: "000000",
                    filled: true,
                    fillColor: AppColors.secondaryBackground,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOTP,
                  child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.black) 
                      : const Text("VERIFY & LOGIN"),
                ),
                TextButton(
                  onPressed: () => setState(() => _codeSent = false), 
                  child: const Text("Change Number", style: TextStyle(color: AppColors.textGrey))
                )
              ],
              
              if (!_codeSent) ...[
                 const SizedBox(height: 32),
                 const Row(children: [
                    Expanded(child: Divider(color: AppColors.textGrey)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text("OR", style: TextStyle(color: AppColors.textGrey)),
                    ),
                    Expanded(child: Divider(color: AppColors.textGrey)),
                 ]),
                 const SizedBox(height: 24),
                 OutlinedButton(
                   onPressed: _isLoading ? null : () async {
                      setState(() => _isLoading = true);
                      try {
                        await ref.read(authRepositoryProvider).signInWithGoogle();
                      } catch (e) {
                         if (context.mounted) {
                           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Google Sign-In Failed: $e")));
                         }
                      } finally {
                        if(mounted) setState(() => _isLoading = false);
                      }
                   },
                   style: OutlinedButton.styleFrom(
                     side: const BorderSide(color: AppColors.accentGreen),
                     padding: const EdgeInsets.symmetric(vertical: 12),
                   ),
                   child: const Row(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       Icon(Icons.g_mobiledata, size: 32, color: Colors.white), // Placeholder for Google Icon
                       SizedBox(width: 8),
                       Text("Continue with Google", style: TextStyle(fontSize: 16, color: Colors.white)),
                     ],
                   ),
                 ),
                 const SizedBox(height: 20),
                 TextButton(
                   onPressed: () {
                     context.go('/admin/dashboard');
                   }, 
                   child: const Text("Admin Panel (Dev Mode)", style: TextStyle(color: Colors.white24))
                 ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}

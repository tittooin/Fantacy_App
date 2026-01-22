
import 'package:axevora11/features/auth/presentation/widgets/landing_page_content.dart';
import 'package:axevora11/core/constants/app_colors.dart';
import 'package:axevora11/features/auth/data/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
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
  bool _termsAccepted = false;

  void _verifyPhone() async {
    // Aggressive Sanitization: Only allow 0-9
    String phone = _phoneController.text.trim().replaceAll(RegExp(r'[^0-9]'), '');

    // Normalize 12 or 11 digit inputs to 10 digits
    if (phone.length > 10) {
      if (phone.startsWith('91') && phone.length == 12) {
         phone = phone.substring(2);
      } else if (phone.startsWith('0') && phone.length == 11) {
         phone = phone.substring(1);
      }
    }

    debugPrint("DEBUG PHONE: Raw='${_phoneController.text}', Clean='$phone', Final='+91$phone'");

    if (phone.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter valid 10-digit number")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.verifyPhoneNumber(
        phoneNumber: '+91\$phone',
        verificationCompleted: (credential) async {
           // Auto-resolution (Android only)
           await authRepo.signInWithCredential(credential);
        },
        verificationFailed: (e) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Code: ${e.code}\nMsg: ${e.message}\nNum: +91$phone")));
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: \$e")));
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 900) {
            // Desktop Split View
            return Row(
              children: [
                // Left Side: Login Panel (App Mockup)
                Expanded(
                  flex: 2,
                  child: Container(
                    color: const Color(0xFF0B1E3C),
                    child: Center(
                      child: Container(
                        width: 400,
                        height: 750,
                        margin: const EdgeInsets.symmetric(vertical: 40),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBackground,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white10, width: 8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 40,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: _buildLoginForm(context),
                        ),
                      ),
                    ),
                  ),
                ),
                // Right Side: Landing Content (Brand Messaging)
                const Expanded(
                  flex: 3,
                  child: LandingPageContent(),
                ),
              ],
            );
          } else {
            // Mobile Centered View
            return Container(
              color: AppColors.primaryBackground,
              child: Center(
                child: SingleChildScrollView(
                  child: _buildLoginForm(context),
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildLoginForm(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Phone Login Section Hidden as per new requirement (Verify later)
          /*
          if (!_codeSent) ...[
            const Text(
              "Enter Mobile Number",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            // ... (Phone Input Fields)
          ]
          */
          
           const Icon(Icons.sports_cricket, size: 80, color: Colors.white),
           const SizedBox(height: 24),
           const Text(
             "AXEVORA11",
             textAlign: TextAlign.center,
             style: TextStyle(
               color: Colors.white,
               fontSize: 32,
               fontWeight: FontWeight.w900,
               letterSpacing: 4,
               shadows: [Shadow(color: Colors.blueAccent, blurRadius: 20)]
             ),
           ),
           const SizedBox(height: 12),
           const Text(
             "India's Premium Fantasy App",
             textAlign: TextAlign.center,
             style: TextStyle(color: Colors.white70, fontSize: 16),
           ),
           const SizedBox(height: 60),

           // Google Sign-In Button (Primary)
           Center(
             child: Container(
               width: double.infinity,
               constraints: const BoxConstraints(maxWidth: 400),
               child: OutlinedButton(
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
                   backgroundColor: Colors.white,
                   foregroundColor: Colors.black,
                   side: const BorderSide(color: Colors.white),
                   padding: const EdgeInsets.symmetric(vertical: 18),
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                   elevation: 5,
                 ),
                 child: Row(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                     if (_isLoading)
                       const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))
                     else ...[
                       // Image.asset('assets/google_logo.png', height: 24), // Placeholder if we had asset
                       const Icon(Icons.g_mobiledata, size: 32, color: Colors.black), 
                       const SizedBox(width: 12),
                       const Text("Continue with Google", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                     ]
                   ],
                 ),
               ),
             ),
           ),
           
           const Spacer(),
           
           // DISCLAIMER FOOTER
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(8)
                ),
                child: const Text(
                  "DISCLAIMER: This is a skill-based platform. Users must be 18+ to play. Financial risk Element involved. Please play responsibly. No Gambling allowed.",
                  style: TextStyle(color: Colors.white54, fontSize: 10),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              // Legal Footer Links
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 16,
                runSpacing: 8,
                children: [
                   _buildFooterLink(context, "Privacy Policy", "/privacy"),
                   _buildFooterLink(context, "Terms & Conditions", "/terms"),
                   _buildFooterLink(context, "Fair Play", "/fair-play"),
                   _buildFooterLink(context, "Contact Us", "/contact"),
                ],
              ),
           const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildFooterLink(BuildContext context, String text, String route) {
    return InkWell(
      onTap: () => context.push(route),
      child: Text(
        text, 
        style: const TextStyle(
          color: Colors.white60, 
          fontSize: 11, 
          decoration: TextDecoration.underline
        )
      ),
    );
  }
}

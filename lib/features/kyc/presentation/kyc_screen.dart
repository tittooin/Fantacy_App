import 'dart:io';
import 'package:axevora11/core/theme/app_theme.dart';
import 'package:axevora11/features/kyc/data/kyc_repository.dart';
import 'package:axevora11/features/user/presentation/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class KYCScreen extends ConsumerStatefulWidget {
  const KYCScreen({super.key});

  @override
  ConsumerState<KYCScreen> createState() => _KYCScreenState();
}

class _KYCScreenState extends ConsumerState<KYCScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _panController = TextEditingController();
  DateTime? _dob;
  
  File? _panImage;
  File? _aadhaarFront;
  File? _aadhaarBack;
  
  bool _isGlobalLoading = false;

  Future<void> _pickImage(String type) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    
    if (picked != null) {
      setState(() {
        if (type == 'pan') _panImage = File(picked.path);
        if (type == 'front') _aadhaarFront = File(picked.path);
        if (type == 'back') _aadhaarBack = File(picked.path);
      });
    }
  }

  Future<void> _submitKYC(String userId) async {
    if (!_formKey.currentState!.validate()) return;
    if (_dob == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Select Date of Birth")));
      return;
    }
    if (_panImage == null || _aadhaarFront == null || _aadhaarBack == null) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please upload all documents")));
       return;
    }

    setState(() => _isGlobalLoading = true);
    try {
      await ref.read(kycRepositoryProvider).submitKYC(
        userId: userId,
        fullName: _nameController.text,
        panNumber: _panController.text,
        dob: DateFormat('yyyy-MM-dd').format(_dob!),
        panImage: _panImage!,
        aadhaarFrontImage: _aadhaarFront!,
        aadhaarBackImage: _aadhaarBack!,
      );
      
      if(mounted) {
        setState(() => _isGlobalLoading = false);
        // Show Success Dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
             backgroundColor: Colors.grey[900],
             title: const Text("Submission Successful", style: TextStyle(color: Colors.green)),
             content: const Text("Your KYC documents have been submitted for verification. Admin will review them within 24-48 hours.", style: TextStyle(color: Colors.white)),
             actions: [
               TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK", style: TextStyle(color: Colors.white70)))
             ],
          )
        ).then((_) => Navigator.pop(context)); // Go back
      }

    } catch (e) {
      if(mounted) {
         setState(() => _isGlobalLoading = false);
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Submission Failed: $e"), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userEntityProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Verify Identity (KYC)")),
      body: userAsync.when(
        data: (user) {
           if (user == null) return const Center(child: Text("User Not Found"));
           
           // map['kycStatus'] logic if field exists
           final dynamicUser = user as dynamic; 
           // Safety check for kycStatus field existence
           String status = 'unverified';
           try {
              status = dynamicUser.kycStatus ?? 'unverified';
           } catch (_) {}

           if (status == 'verified') {
             return Center(
               child: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   const Icon(Icons.verified, color: Colors.green, size: 80),
                   const SizedBox(height: 16),
                   const Text("KYC Verified", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                   const SizedBox(height: 8),
                   const Text("You can withdraw funds without limits.", style: TextStyle(color: Colors.white54)),
                   const SizedBox(height: 24),
                   ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text("Go Back"))
                 ],
               ),
             );
           }
           
           if (status == 'pending') {
              return Center(
               child: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   const Icon(Icons.hourglass_top, color: Colors.orange, size: 80),
                   const SizedBox(height: 16),
                   const Text("Verification Pending", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                   const SizedBox(height: 8),
                   const Text("Your documents are under review.", style: TextStyle(color: Colors.white54)),
                   const SizedBox(height: 24),
                   ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text("Go Back"))
                 ],
               ),
             );
           }

           // If Rejected or Unverified -> Show Form
           return SingleChildScrollView(
             padding: const EdgeInsets.all(24),
             child: Form(
               key: _formKey,
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   if (status == 'rejected')
                     Container(
                       padding: const EdgeInsets.all(12),
                       margin: const EdgeInsets.only(bottom: 20),
                       decoration: BoxDecoration(
                         color: Colors.red.withOpacity(0.1), 
                         border: Border.all(color: Colors.red)
                       ),
                       child: const Row(
                         children: [
                           Icon(Icons.error, color: Colors.red),
                           SizedBox(width: 12),
                           Expanded(child: Text("KYC Rejected. Please re-submit valid documents.", style: TextStyle(color: Colors.red)))
                         ],
                       ),
                     ),
                   
                   const Text("Personal Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                   const SizedBox(height: 16),
                   TextFormField(
                     controller: _nameController,
                     style: const TextStyle(color: Colors.white),
                     decoration: const InputDecoration(labelText: "Full Name (as per PAN)", border: OutlineInputBorder()),
                     validator: (v) => v!.isEmpty ? "Enter Name" : null,
                   ),
                   const SizedBox(height: 16),
                   TextFormField(
                     controller: _panController,
                     style: const TextStyle(color: Colors.white),
                     decoration: const InputDecoration(labelText: "PAN Number", border: OutlineInputBorder()),
                     validator: (v) => v!.length != 10 ? "Enter valid 10-digit PAN" : null,
                   ),
                   const SizedBox(height: 16),
                   InkWell(
                     onTap: () async {
                       final d = await showDatePicker(
                         context: context, 
                         initialDate: DateTime(2000), 
                         firstDate: DateTime(1950), 
                         lastDate: DateTime.now()
                       );
                       if(d!=null) setState(() => _dob = d);
                     },
                     child: Container(
                       padding: const EdgeInsets.all(16),
                       decoration: BoxDecoration(border: Border.all(color: Colors.white30)),
                       child: Row(
                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                         children: [
                           Text(_dob == null ? "Select Date of Birth" : DateFormat('dd MMM yyyy').format(_dob!),
                                style: const TextStyle(color: Colors.white)),
                           const Icon(Icons.calendar_today, color: Colors.white54)
                         ],
                       ),
                     ),
                   ),
                   
                   const SizedBox(height: 32),
                   const Text("Document Upload", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                   const SizedBox(height: 16),
                   
                   _UploadBox(label: "PAN Card Photo", file: _panImage, onTap: () => _pickImage('pan')),
                   const SizedBox(height: 16),
                   _UploadBox(label: "Aadhaar Front", file: _aadhaarFront, onTap: () => _pickImage('front')),
                   const SizedBox(height: 16),
                   _UploadBox(label: "Aadhaar Back", file: _aadhaarBack, onTap: () => _pickImage('back')),
                   
                   const SizedBox(height: 32),
                   SizedBox(
                     width: double.infinity,
                     child: ElevatedButton(
                       onPressed: _isGlobalLoading ? null : () => _submitKYC(dynamicUser.uid),
                       style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, padding: const EdgeInsets.symmetric(vertical: 16)),
                       child: _isGlobalLoading 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("SUBMIT FOR VERIFICATION")
                     ),
                   )
                 ],
               ),
             ),
           );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Error: $err")),
      ),
    );
  }
}

class _UploadBox extends StatelessWidget {
  final String label;
  final File? file;
  final VoidCallback onTap;
  const _UploadBox({required this.label, required this.file, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[900],
          border: Border.all(color: Colors.white24, style: BorderStyle.solid),
          borderRadius: BorderRadius.circular(8)
        ),
        child: file != null 
          ? Image.file(file!, fit: BoxFit.cover)
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_upload, color: Colors.white54, size: 40),
                const SizedBox(height: 8),
                Text(label, style: const TextStyle(color: Colors.white54))
              ],
            ),
      ),
    );
  }
}

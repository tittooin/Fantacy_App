import 'package:axevora11/core/constants/app_colors.dart';
import 'package:axevora11/core/constants/app_prefs.dart';
import 'package:axevora11/features/auth/data/auth_repository.dart';
import 'package:axevora11/features/location/data/location_service.dart';
import 'package:axevora11/features/user/data/user_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class StateSelectionScreen extends ConsumerStatefulWidget {
  const StateSelectionScreen({super.key});

  @override
  ConsumerState<StateSelectionScreen> createState() => _StateSelectionScreenState();
}

class _StateSelectionScreenState extends ConsumerState<StateSelectionScreen> {
  String? _selectedState;
  bool _isLoading = false;

  final List<String> _allStates = [
    'Andaman and Nicobar Islands',
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chandigarh',
    'Chhattisgarh',
    'Dadra and Nagar Haveli',
    'Daman and Diu',
    'Delhi',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jammu and Kashmir',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Ladakh',
    'Lakshadweep',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Puducherry',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
  ];

  void _confirmSelection() async {
    if (_selectedState == null) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(locationServiceProvider).saveUserState(_selectedState!);
      
      final user = ref.read(authRepositoryProvider).currentUser;
      if (user != null) {
        final isRestricted = RestrictedStates.list.contains(_selectedState);
        await ref.read(userRepositoryProvider).updateUserState(user.uid, _selectedState!, isRestricted);
      }

      if (mounted) {
        final isRestricted = RestrictedStates.list.contains(_selectedState);
        
        if (isRestricted) {
           await showDialog(
             context: context,
             barrierDismissible: false,
             builder: (ctx) => AlertDialog(
               title: const Text("Location Restriction", style: TextStyle(color: Colors.red)),
               content: const Text(
                 "You have selected a restricted state (Assam, Odisha, Telangana, Nagaland, Sikkim, Andhra Pradesh).\n\n"
                 "As per government laws, you cannot participate in 'Paid Contests' (Cash Games).\n\n"
                 "You can still play 'Free Practice Contests'.",
               ),
               actions: [
                 TextButton(
                   onPressed: () => Navigator.pop(ctx),
                   child: const Text("I UNDERSTAND"),
                 )
               ],
             )
           );
        }
        
        if (mounted) context.go('/home');
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.location_on, size: 60, color: AppColors.accentGreen),
              const SizedBox(height: 24),
              Text(
                "Verify Location",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                "Please select your current state to comply with Indian Gaming Laws.",
                style: TextStyle(color: AppColors.textLight, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedState,
                    hint: const Text("Select State", style: TextStyle(color: AppColors.textLight)),
                    dropdownColor: AppColors.cardColor,
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down, color: AppColors.accentGreen),
                    style: const TextStyle(color: AppColors.textDark, fontSize: 16),
                    items: _allStates.map((state) {
                      return DropdownMenuItem(
                        value: state,
                        child: Text(state, style: const TextStyle(color: AppColors.textDark)),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedState = val),
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              ElevatedButton(
                onPressed: (_selectedState == null || _isLoading) ? null : _confirmSelection,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentGreen,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  disabledBackgroundColor: Colors.grey,
                ),
                child: _isLoading 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                  : const Text("CONFIRM LOCATION", style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              
               const SizedBox(height: 16),
               const Text(
                 "Note: Providing false information may lead to account suspension.",
                 style: TextStyle(color: Colors.redAccent, fontSize: 12),
                 textAlign: TextAlign.center,
               ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:axevora11/core/constants/app_prefs.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationService {
  final SharedPreferences _prefs;

  LocationService(this._prefs);

  /// Checks if the user has already selected their state.
  bool get hasSelectedState => _prefs.getString(AppPrefs.userState) != null;

  /// Checks if the user is from a restricted state.
  bool get isRestricted => _prefs.getBool(AppPrefs.isRestrictedUser) ?? false;

  /// Returns the selected state name.
  String? get userState => _prefs.getString(AppPrefs.userState);

  /// Saves the selected state and determines restriction status.
  Future<void> saveUserState(String stateName) async {
    final isRestricted = RestrictedStates.list.contains(stateName);
    
    await _prefs.setString(AppPrefs.userState, stateName);
    await _prefs.setBool(AppPrefs.isRestrictedUser, isRestricted);
  }
  
  /// Clears location data (for logout or debugging).
  Future<void> clearLocationData() async {
    await _prefs.remove(AppPrefs.userState);
    await _prefs.remove(AppPrefs.isRestrictedUser);
  }
}

// Providers
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in main.dart');
});

final locationServiceProvider = Provider<LocationService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocationService(prefs);
});

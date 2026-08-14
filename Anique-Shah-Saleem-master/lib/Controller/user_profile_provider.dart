import 'package:flutter/foundation.dart';

class UserProfileProvider with ChangeNotifier {
  Map<String, dynamic>? _userProfile;
  bool _isLoading = false;
  String? _error;

  // Getter methods
  Map<String, dynamic>? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Set user profile data
  void setUserProfile(Map<String, dynamic> userData) {
    _userProfile = userData;
    notifyListeners();
  }

  // Update user profile
  void updateUserProfile(Map<String, dynamic> updates) {
    if (_userProfile != null) {
      _userProfile!.addAll(updates);
      notifyListeners();
    }
  }

  // Clear user profile (on logout)
  void clearUserProfile() {
    _userProfile = null;
    notifyListeners();
  }

  // Set loading state
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set error message
  void setError(String? error) {
    _error = error;
    notifyListeners();
  }
}

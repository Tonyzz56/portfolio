import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:school_management_system/src/models/institution_model.dart';
import 'package:school_management_system/src/models/subscription_package_model.dart';
import 'package:school_management_system/src/models/user_model.dart' as AppUser; // Aliased to avoid conflict with FirebaseAuth.User

class SubscriptionFeatureService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  AppUser.UserModel? _currentUserModel;
  Institution? _currentInstitution;
  SubscriptionPackageModel? _currentPackage;
  bool _isLoading = false;
  DateTime? _lastLoadTime;

  // Cache duration to avoid frequent Firestore reads
  final Duration _cacheDuration = const Duration(minutes: 5);

  Future<void> _loadCurrentUserAndInstitutionData() async {
    if (_isLoading) return; // Prevent concurrent loads

    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      _currentUserModel = null;
      _currentInstitution = null;
      _currentPackage = null;
      return;
    }

    // Check cache validity
    if (_lastLoadTime != null && DateTime.now().difference(_lastLoadTime!) < _cacheDuration && _currentUserModel != null) {
      // If institution data is also loaded, skip
      if ((_currentUserModel!.institutionId != null && _currentInstitution != null && _currentInstitution!.id == _currentUserModel!.institutionId) || _currentUserModel!.institutionId == null) {
           return;
      }
    }

    _isLoading = true;

    try {
      // Load User Model
      DocumentSnapshot userDoc = await _db.collection('users').doc(firebaseUser.uid).get();
      if (userDoc.exists) {
        _currentUserModel = AppUser.UserModel.fromMap(userDoc.data() as Map<String, dynamic>, userDoc.id);
      } else {
        _currentUserModel = null;
        _currentInstitution = null;
        _currentPackage = null;
        _isLoading = false;
        return;
      }

      if (_currentUserModel?.institutionId == null) {
        // User is not associated with an institution (e.g., Super Admin)
        _currentInstitution = null;
        _currentPackage = null;
        _isLoading = false;
        _lastLoadTime = DateTime.now();
        return;
      }

      // Load Institution
      DocumentSnapshot institutionDoc = await _db.collection('institutions').doc(_currentUserModel!.institutionId).get();
      if (institutionDoc.exists) {
        _currentInstitution = Institution.fromMap(institutionDoc.data() as Map<String, dynamic>, institutionDoc.id);
      } else {
        _currentInstitution = null;
        _currentPackage = null;
        _isLoading = false;
        // Log this, as it's an inconsistent state if user has institutionId but institution doesn't exist
        print("Error: Institution not found for ID: ${_currentUserModel!.institutionId}");
        return;
      }

      // Load Subscription Package
      if (_currentInstitution?.activeSubscriptionPackageId != null) {
        DocumentSnapshot packageDoc = await _db.collection('subscriptionPackages').doc(_currentInstitution!.activeSubscriptionPackageId).get();
        if (packageDoc.exists) {
          _currentPackage = SubscriptionPackageModel.fromMap(packageDoc.data() as Map<String, dynamic>, packageDoc.id);
        } else {
          _currentPackage = null;
          // Log this, as it's an inconsistent state
          print("Error: Subscription package not found for ID: ${_currentInstitution!.activeSubscriptionPackageId}");
        }
      } else {
        _currentPackage = null;
      }
      _lastLoadTime = DateTime.now();

    } catch (e) {
      print("Error loading subscription/feature data: $e");
      // Keep existing stale data or clear it? For now, let's not clear on error to avoid UI flicker if it's temporary.
      // _currentUserModel = null;
      // _currentInstitution = null;
      // _currentPackage = null;
    } finally {
      _isLoading = false;
    }
  }

  Future<bool> isFeatureEnabled(String featureTag) async {
    await _loadCurrentUserAndInstitutionData();

    // Super Admins typically have all features enabled, or their features are not controlled by institution subscriptions.
    if (_currentUserModel?.role == AppUser.UserRole.superAdmin) {
      // For super admins, you might have a separate permission system or grant all.
      // For now, let's assume they have access to all features relevant to their role,
      // and this service is primarily for institution-specific features.
      // Or, check against a predefined list of super admin features if `featureTag` is one of them.
      // This part depends on how super admin features are defined.
      // For simplicity, if it's an institution-specific feature, a super admin might not "enable" it in the institution context.
      // Let's assume for now this method is mostly called by institutional users.
      // A more robust way would be to check if the featureTag is something a super admin would use.
      // For now, let's return true for super admins for system-level features, or based on their own permissions.
      // This needs refinement based on what 'featureTag' represents.
      // If featureTag is like 'CAN_CREATE_INSTITUTION', super admin should have it.
      // If it's 'CAN_SUBMIT_ASSIGNMENT', it's irrelevant for super admin.
      // For now, let's assume featureTags are institution-level.
      return true; // Or handle super admin permissions separately
    }

    if (_currentInstitution == null) {
      // Non-super admin user not tied to an institution, or institution data failed to load
      return false;
    }

    // Check institution status - only 'active' and 'trial' (and perhaps 'grace_period') allow feature access.
    final allowedStatuses = ['active', 'trial', 'grace_period'];
    if (!allowedStatuses.contains(_currentInstitution!.subscriptionStatus)) {
      return false;
    }

    // If no package is assigned, but status is 'trial', allow basic features or a predefined trial set.
    // This example assumes trial features are also defined in a (possibly "Trial") package.
    // If a trial has its own hardcoded feature set, that logic would go here.
    if (_currentPackage == null) {
        // If in 'trial' or 'grace_period' without a specific package, deny features that require one.
        // Or, you could have a default "trial" package definition.
        // For now, if no package, no features from packages.
      return false;
    }

    // Check if the package itself is active (though institution status should reflect this)
    if (!_currentPackage!.isActive) {
        return false;
    }

    return _currentPackage!.features.contains(featureTag);
  }

  Future<int?> getLimit(String limitTag) async {
    await _loadCurrentUserAndInstitutionData();

    if (_currentUserModel?.role == AppUser.UserRole.superAdmin) {
      return null; // Super Admins usually don't have such limits
    }

    if (_currentInstitution == null || _currentPackage == null) {
      return 0; // Or null, indicating limit not applicable or no package
    }

    // Similar status check as isFeatureEnabled
    final allowedStatuses = ['active', 'trial', 'grace_period'];
     if (!allowedStatuses.contains(_currentInstitution!.subscriptionStatus)) {
      return 0; // No usage allowed if subscription is not in a usable state
    }
    if (!_currentPackage!.isActive) {
        return 0;
    }

    // Example: these limitTags correspond to fields in SubscriptionPackageModel
    if (limitTag == 'MAX_STUDENTS') {
      return _currentPackage!.maxStudents;
    } else if (limitTag == 'MAX_STAFF') {
      return _currentPackage!.maxStaff;
    }
    // Add other limits as defined in your SubscriptionPackageModel, e.g., MAX_STORAGE_MB

    return null; // Limit tag not recognized or not set
  }

  // Helper to get current institution status directly if needed by UI
  Future<String?> getCurrentInstitutionSubscriptionStatus() async {
    await _loadCurrentUserAndInstitutionData();
    return _currentInstitution?.subscriptionStatus;
  }

  // Call this on user logout to clear cached data
  void clearCache() {
    _currentUserModel = null;
    _currentInstitution = null;
    _currentPackage = null;
    _lastLoadTime = null;
  }

  // Call this if user's institution or subscription changes significantly to force a reload
  Future<void> forceReloadData() async {
    _lastLoadTime = null; // Invalidate cache
    await _loadCurrentUserAndInstitutionData();
  }
}

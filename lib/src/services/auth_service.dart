import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final fb_auth.FirebaseAuth _firebaseAuth = fb_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _usersCollection = 'users';

  fb_auth.User? get currentUserAuthInfo => _firebaseAuth.currentUser;

  Stream<UserModel?> get user {
    return _firebaseAuth.authStateChanges().asyncMap((fb_auth.User? firebaseUser) async {
      if (firebaseUser == null) return null;
      DocumentSnapshot userDoc = await _firestore.collection(_usersCollection).doc(firebaseUser.uid).get();
      if (userDoc.exists) {
        return UserModel.fromMap(userDoc.data() as Map<String, dynamic>, firebaseUser.uid);
      }
      // This case implies an issue (e.g. Firestore doc creation failed post-Auth creation)
      print("Warning: User document not found in Firestore for UID: ${firebaseUser.uid}.");
      return UserModel(uid: firebaseUser.uid, email: firebaseUser.email ?? '', role: UserRole.unknown, createdAt: DateTime.now(), updatedAt: DateTime.now());
    });
  }

  Future<UserModel?> signUpOrRegisterUser({
    required String emailForAuth, // This will be used for Firebase Auth (can be system-generated)
    required String? customLoginId, // User-facing login ID, must be unique
    required String password,
    required String displayName,
    required UserRole role,
    required String? institutionId,
    String? admissionNumber, String? currentClassId, List<String>? parentUids,
    String? staffId, List<String>? subjectIds, String? department,
    List<String>? childUids, String? vendorCompanyName,
  }) async {
    if (role != UserRole.superAdmin && institutionId == null) {
      throw ArgumentError("Institution ID is required for non-SuperAdmin roles.");
    }
    if (customLoginId != null && customLoginId.isNotEmpty) {
      final existingUserByCustomId = await _firestore.collection(_usersCollection).where('customLoginId', isEqualTo: customLoginId).limit(1).get();
      if (existingUserByCustomId.docs.isNotEmpty) {
        throw Exception("Custom Login ID '$customLoginId' already exists. Please choose another.");
      }
    } else if (role != UserRole.superAdmin) {
        // For most roles, customLoginId should be mandatory. SuperAdmin might be an exception using email.
        // This logic can be adjusted. For now, allow null/empty customLoginId if email is the primary login.
        // However, the request implies customLoginId is the primary login for most.
        // throw ArgumentError("Custom Login ID is required for this user role.");
        print("Warning: customLoginId is not provided for user $displayName ($role). Email will be primary identifier if custom login is attempted without it.");
    }


    DateTime now = DateTime.now();
    fb_auth.UserCredential userCredential;

    try {
      // Check if user already exists with this email in Firebase Auth (might happen if email is not system-generated)
      try {
          userCredential = await _firebaseAuth.createUserWithEmailAndPassword(email: emailForAuth, password: password);
      } on fb_auth.FirebaseAuthException catch (e) {
          if (e.code == 'email-already-in-use') {
              // If email is already in use, this might be an error or an attempt to link to an existing auth user.
              // For simplicity now, we'll throw. More complex logic could allow linking.
              throw Exception("The email address '$emailForAuth' is already in use by another account for Firebase Authentication.");
          }
          rethrow; // rethrow other Firebase Auth exceptions
      }

      fb_auth.User? firebaseUser = userCredential.user;
      if (firebaseUser == null) throw Exception("Firebase user creation failed.");

      await firebaseUser.updateDisplayName(displayName);

      UserModel newUser = UserModel(
        uid: firebaseUser.uid,
        email: emailForAuth, // Store the email used for Firebase Auth
        customLoginId: customLoginId,
        displayName: displayName,
        role: role,
        institutionId: institutionId,
        createdAt: now,
        updatedAt: now,
        isActive: true,
        admissionNumber: admissionNumber, currentClassId: currentClassId, parentUids: parentUids,
        staffId: staffId, subjectIds: subjectIds, department: department,
        childUids: childUids, vendorCompanyName: vendorCompanyName,
      );
      await _firestore.collection(_usersCollection).doc(firebaseUser.uid).set(newUser.toMap());
      return newUser;
    } on fb_auth.FirebaseAuthException catch (e) {
      print('Firebase Auth Exception during user creation: ${e.message}');
      throw e;
    } catch (e) {
      print('Error during user creation: $e');
      throw e; // Rethrow other exceptions
    }
  }

  Future<UserModel?> signInWithCustomIdPassword(String customId, String password) async {
    if (customId.isEmpty) throw Exception("Login ID cannot be empty.");

    final querySnapshot = await _firestore.collection(_usersCollection).where('customLoginId', isEqualTo: customId).limit(1).get();

    if (querySnapshot.docs.isEmpty) {
      throw Exception("Login ID not found. Please check your Login ID or contact support.");
    }

    DocumentSnapshot userDocSnap = querySnapshot.docs.first;
    UserModel tempUser = UserModel.fromMap(userDocSnap.data() as Map<String, dynamic>, userDocSnap.id);

    if (tempUser.email.isEmpty) {
        // This should not happen if data is consistent.
        throw Exception("User account configuration error. Associated email for Firebase Auth is missing.");
    }
    // Now sign in with the email linked to this customLoginId
    return _signInWithActualEmail(tempUser.email, password, tempUser.uid);
  }

  // Kept for SuperAdmins or direct email login scenarios
  Future<UserModel?> signInWithEmailPassword(String email, String password) async {
    if (email.isEmpty) throw Exception("Email cannot be empty.");
    // For direct email login, we don't know the UID yet to check Firestore first for active status easily.
    // So, we sign in to Auth, then check Firestore.
    return _signInWithActualEmail(email, password, null);
  }

  // Internal method to handle actual Firebase Auth sign-in and Firestore doc retrieval
  Future<UserModel?> _signInWithActualEmail(String emailForAuth, String password, String? expectedUid) async {
    try {
      fb_auth.UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(email: emailForAuth, password: password);
      fb_auth.User? firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        // If expectedUid is provided (from custom ID login), verify it matches.
        if (expectedUid != null && firebaseUser.uid != expectedUid) {
            await signOut(); // Security measure: UID mismatch
            throw Exception("Authentication integrity error. Please try again.");
        }
        DocumentSnapshot userDoc = await _firestore.collection(_usersCollection).doc(firebaseUser.uid).get();
        if (userDoc.exists) {
          UserModel userModel = UserModel.fromMap(userDoc.data() as Map<String, dynamic>, firebaseUser.uid);
          if (!userModel.isActive) {
            await signOut();
            throw fb_auth.FirebaseAuthException(code: 'user-disabled', message: 'This user account has been deactivated.');
          }
          return userModel;
        } else {
          print("Error: User document not found in Firestore for UID: ${firebaseUser.uid} after sign in.");
          await signOut();
          throw Exception("User data not found in database. Please contact support.");
        }
      }
      return null;
    } on fb_auth.FirebaseAuthException catch (e) {
      print('Firebase Auth Exception during sign in with email $emailForAuth: ${e.message}');
      throw e;
    } catch (e) {
      print('Error during sign in with email $emailForAuth: $e');
      throw Exception("An unexpected error occurred during sign in.");
    }
  }

  Future<bool> updateUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = Timestamp.now();
      // Note: Updating 'email' or 'customLoginId' here only affects Firestore.
      // Changing Firebase Auth email requires re-authentication or Admin SDK.
      // Changing customLoginId would need uniqueness checks again.
      // These critical fields should ideally be updated via specific admin functions.
      await _firestore.collection(_usersCollection).doc(uid).update(data);
      return true;
    } catch (e) {
      print("Error updating user profile for $uid: $e");
      return false;
    }
  }

  Stream<List<UserModel>> getUsersForInstitution(String institutionId) {
    return _firestore.collection(_usersCollection).where('institutionId', isEqualTo: institutionId).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
    });
  }

  Future<bool> toggleUserActiveStatus(String uid, bool isActive) async {
    try {
      await _firestore.collection(_usersCollection).doc(uid).update({'isActive': isActive, 'updatedAt': Timestamp.now()});
      return true;
    } catch (e) {
      print('Error toggling user active status for $uid: $e');
      return false;
    }
  }

  Future<void> sendPasswordResetEmail(String emailOrCustomId) async {
    String emailToUse = emailOrCustomId;
    // Attempt to see if it's a custom ID
    if (!emailOrCustomId.contains('@')) { // Simple check, might need refinement
        final querySnapshot = await _firestore.collection(_usersCollection).where('customLoginId', isEqualTo: emailOrCustomId).limit(1).get();
        if (querySnapshot.docs.isNotEmpty) {
            UserModel tempUser = UserModel.fromMap(querySnapshot.docs.first.data() as Map<String, dynamic>, querySnapshot.docs.first.id);
            emailToUse = tempUser.email;
        } else {
            // If not found as custom ID, and not an email, it will likely fail or user needs to be guided.
            // For now, we pass it to Firebase Auth, which expects an email.
             throw Exception("Login ID not found. Cannot send password reset.");
        }
    }
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: emailToUse);
    } on fb_auth.FirebaseAuthException catch (e) {
      print('Firebase Auth Exception during password reset for $emailToUse: ${e.message}');
      throw e;
    } catch (e) {
      print('Error sending password reset email for $emailToUse: $e');
      throw Exception('Failed to send password reset email.');
    }
  }

  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      print('Error during sign out: $e');
    }
  }

  // Super Admin creation should use a unique, non-guessable email for Auth if customLoginId is also used.
  Future<void> createSuperAdminAccount(String emailForAuth, String password, String displayName, {String? customLoginIdForSuperAdmin}) async {
    final querySnapshot = await _firestore.collection(_usersCollection).where('role', isEqualTo: 'superAdmin').limit(1).get();
    if (querySnapshot.docs.isNotEmpty) {
      print("Super Admin already exists.");
      return;
    }
    try {
      await signUpOrRegisterUser(
          emailForAuth: emailForAuth, // e.g. superadmin@system.yourdomain.com
          customLoginId: customLoginIdForSuperAdmin, // Optional for super admin
          password: password,
          displayName: displayName,
          role: UserRole.superAdmin,
          institutionId: null);
      print("Super Admin account creation attempt finished for: $displayName");
    } catch (e) {
      print("Error creating Super Admin: $e");
    }
  }
}

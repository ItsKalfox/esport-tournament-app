import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  // ── Current user ──────────────────────────────────────────────────────────
  static User? get currentUser => _auth.currentUser;
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── Save user to Firestore ────────────────────────────────────────────────
  static Future<void> _saveUserToFirestore({
    required String uid,
    required String firstName,
    required String lastName,
    required String email,
    String? phone,
    String? photoUrl,
    String provider = 'email',
  }) async {
    final userRef = _db.collection('users').doc(uid);
    final snap = await userRef.get();

    if (!snap.exists) {
      // New user — create full document
      await userRef.set({
        'uid': uid,
        'firstName': firstName,
        'lastName': lastName,
        'displayName': '$firstName $lastName'.trim(),
        'email': email,
        'phone': phone ?? '',
        'photoUrl': photoUrl ?? '',
        'role': 'user',
        'provider': provider,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      // Existing user — only update last login time
      await userRef.update({'updatedAt': FieldValue.serverTimestamp()});
    }
  }

  // ── Email & Password Login ────────────────────────────────────────────────
  static Future<UserCredential> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    // Update last login
    await _db.collection('users').doc(credential.user!.uid).update({
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return credential;
  }

  // ── Email & Password Register ─────────────────────────────────────────────
  static Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    // Update Firebase Auth display name
    await credential.user?.updateDisplayName('$firstName $lastName'.trim());
    await credential.user?.reload();

    // Save to Firestore
    await _saveUserToFirestore(
      uid: credential.user!.uid,
      firstName: firstName,
      lastName: lastName,
      email: email.trim(),
      phone: phone,
      provider: 'email',
    );

    return credential;
  }

  // ── Google Sign-In ────────────────────────────────────────────────────────
  static Future<UserCredential?> signInWithGoogle() async {
    await _googleSignIn.signOut();

    final GoogleSignInAccount? googleAccount = await _googleSignIn.signIn();
    if (googleAccount == null) return null;

    final GoogleSignInAuthentication googleAuth =
        await googleAccount.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user!;

    // Split display name into first/last
    final nameParts = (user.displayName ?? '').split(' ');
    final firstName = nameParts.isNotEmpty ? nameParts.first : '';
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    // Save to Firestore (only creates if new user)
    await _saveUserToFirestore(
      uid: user.uid,
      firstName: firstName,
      lastName: lastName,
      email: user.email ?? '',
      phone: user.phoneNumber,
      photoUrl: user.photoURL,
      provider: 'google',
    );

    return userCredential;
  }

  // ── Forgot Password ───────────────────────────────────────────────────────
  static Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  // ── Sign Out ──────────────────────────────────────────────────────────────
  static Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // ── Parse Firebase Error Messages ─────────────────────────────────────────
  static String getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password is too weak. Use at least 8 characters.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      case 'invalid-credential':
        return 'Email or password is incorrect.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  // ── Complete Onboarding ────────────────────────────────────────────────────
  static Future<bool> completeOnboarding() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      await _db.collection('users').doc(user.uid).update({
        'onboardingCompleted': true,
        'onboardingCompletedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // ── Check Onboarding Status ─────────────────────────────────────────────
  static Future<bool> isOnboardingCompleted(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists) return false;
      final data = doc.data();
      return data != null && (data['onboardingCompleted'] == true);
    } catch (e) {
      return false;
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Service handling Firebase Authentication and user cloud provisioning.
class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  static const String webClientId =
      '627355300105-t4rv7memoiokslhmj0op07rn58l595tn.apps.googleusercontent.com';

  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _googleSignIn = googleSignIn ??
            GoogleSignIn(
              serverClientId: webClientId,
            );

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  bool get isSignedIn => currentUser != null;

  /// Helper to extract existing guest dossier from 'users/user_me'
  Future<Map<String, dynamic>> _fetchExistingGuestDossier() async {
    try {
      final guestDoc = await _firestore.collection('users').doc('user_me').get();
      if (guestDoc.exists && guestDoc.data() != null) {
        return guestDoc.data()!;
      }
    } catch (_) {}
    return {};
  }

  /// Migrates any locally authored reviews from 'user_me' to the authenticated critic UID.
  Future<void> _migrateGuestReviews(String newUid, String criticName, String criticHandle) async {
    try {
      final reviewsSnapshot = await _firestore
          .collection('reviews')
          .where('userId', isEqualTo: 'user_me')
          .get();
      for (final doc in reviewsSnapshot.docs) {
        await doc.reference.update({
          'userId': newUid,
          'userName': criticName,
          'userHandle': criticHandle,
        });
      }
    } catch (_) {}
  }

  /// Register a new critic account with Email & Password.
  Future<UserCredential> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String criticName,
    String? criticHandle,
  }) async {
    final cleanEmail = email.trim();
    final cleanName = criticName.trim().toUpperCase();
    final generatedHandle = criticHandle != null && criticHandle.trim().isNotEmpty
        ? (criticHandle.trim().startsWith('@') ? criticHandle.trim() : '@${criticHandle.trim()}')
        : '@${criticName.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_')}';

    final credential = await _auth.createUserWithEmailAndPassword(
      email: cleanEmail,
      password: password,
    );

    final user = credential.user;
    if (user != null) {
      await user.updateDisplayName(cleanName);

      // Fetch any existing guest dossier (e.g. from user_me)
      final guestData = await _fetchExistingGuestDossier();

      // Provision user profile in Cloud Firestore under their permanent Auth UID
      await _firestore.collection('users').doc(user.uid).set({
        'userId': user.uid,
        'email': cleanEmail,
        'userName': cleanName,
        'userHandle': generatedHandle,
        'bio': guestData['bio'] ?? 'Sonic explorer & vinyl enthusiast. Chronicling deep cuts and 10/10 masterpieces.',
        'createdAt': FieldValue.serverTimestamp(),
        'avatarPath': guestData['avatarPath'],
        'backdropPath': guestData['backdropPath'],
      }, SetOptions(merge: true));

      await _migrateGuestReviews(user.uid, cleanName, generatedHandle);
    }

    return credential;
  }

  /// Sign in an existing critic with Email & Password.
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user;
    if (user != null) {
      // Ensure user document exists in Firestore
      final docRef = _firestore.collection('users').doc(user.uid);
      final doc = await docRef.get();
      if (!doc.exists) {
        final guestData = await _fetchExistingGuestDossier();
        final displayName = guestData['userName'] ?? user.displayName ?? 'CRITIC // YOU';
        final handle = guestData['userHandle'] ??
            '@${displayName.toLowerCase().replaceAll(RegExp(r'\s+'), '_')}';
        await docRef.set({
          'userId': user.uid,
          'email': user.email ?? email.trim(),
          'userName': displayName.toUpperCase(),
          'userHandle': handle,
          'bio': guestData['bio'] ?? 'Sonic explorer & vinyl enthusiast. Chronicling deep cuts and 10/10 masterpieces.',
          'createdAt': FieldValue.serverTimestamp(),
          'avatarPath': guestData['avatarPath'],
          'backdropPath': guestData['backdropPath'],
        }, SetOptions(merge: true));

        await _migrateGuestReviews(user.uid, displayName.toUpperCase(), handle);
      }
    }

    return credential;
  }

  /// Sign in or register seamlessly using Google Sign-In.
  Future<UserCredential?> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      // User cancelled the Google sign-in process
      return null;
    }

    final googleAuth = await googleUser.authentication;
    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user;

    if (user != null) {
      final docRef = _firestore.collection('users').doc(user.uid);
      final doc = await docRef.get();
      if (!doc.exists) {
        final guestData = await _fetchExistingGuestDossier();
        final name = guestData['userName'] ??
            (user.displayName ?? googleUser.displayName ?? 'CRITIC').toUpperCase();
        final handle = guestData['userHandle'] ??
            '@${name.toLowerCase().replaceAll(RegExp(r'\s+'), '_')}';
        await docRef.set({
          'userId': user.uid,
          'email': user.email ?? googleUser.email,
          'userName': name,
          'userHandle': handle,
          'bio': guestData['bio'] ?? 'Sonic explorer & vinyl enthusiast. Chronicling deep cuts and 10/10 masterpieces.',
          'createdAt': FieldValue.serverTimestamp(),
          'avatarPath': guestData['avatarPath'] ?? user.photoURL,
          'backdropPath': guestData['backdropPath'],
        }, SetOptions(merge: true));

        await _migrateGuestReviews(user.uid, name, handle);
      }
    }

    return userCredential;
  }

  /// Send password reset email.
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  /// Sign out current critic session.
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _auth.signOut();
  }

  /// Translates Firebase errors into bold, neo-brutalist user-friendly messages.
  static String getHumanReadableError(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'NO CRITIC DOSSIER FOUND FOR THIS EMAIL';
        case 'wrong-password':
          return 'INCORRECT PASSWORD PROVIDED';
        case 'invalid-credential':
          return 'INVALID CREDENTIALS. CHECK YOUR EMAIL AND PASSWORD';
        case 'email-already-in-use':
          return 'A DOSSIER WITH THIS EMAIL ALREADY EXISTS';
        case 'weak-password':
          return 'SECURITY COMPROMISED: PASSWORD MUST BE AT LEAST 6 CHARACTERS';
        case 'invalid-email':
          return 'MALFORMED EMAIL ADDRESS ENTERED';
        case 'user-disabled':
          return 'THIS ACCOUNT HAS BEEN SUSPENDED';
        case 'too-many-requests':
          return 'RATE LIMITED: TOO MANY FAILED ATTEMPTS. TRY AGAIN LATER';
        case 'network-request-failed':
          return 'NETWORK TIMEOUT: CHECK INTERNET CONNECTION';
        case 'operation-not-allowed':
          return 'THIS SIGN-IN METHOD IS CURRENTLY DISABLED';
        default:
          return error.message?.toUpperCase() ?? 'AUTHENTICATION REJECTED';
      }
    }
    return error.toString().toUpperCase();
  }
}

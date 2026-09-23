import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/services/auth_service.dart';

/// Provider for AuthService singleton
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Stream of active Firebase Auth user state
final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

/// Boolean provider indicating whether a critic is signed in with Firebase
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.asData?.value != null;
});

/// Provider for current critic's authenticated email
final currentUserEmailProvider = Provider<String?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.asData?.value?.email;
});

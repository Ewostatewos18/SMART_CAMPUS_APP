import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/service_providers.dart';
import '../../../models/user_model.dart';
import '../../../models/user_role.dart';
import '../../../services/auth_service.dart';

final authStateProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authServiceProvider));
});

class AuthState {
  const AuthState({
    this.appUser,
    this.isLoading = true,
    this.errorMessage,
  });

  final AppUser? appUser;
  final bool isLoading;
  final String? errorMessage;

  bool get isAuthenticated => appUser != null;

  AuthState copyWith({
    AppUser? appUser,
    bool? isLoading,
    String? errorMessage,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      appUser: clearUser ? null : (appUser ?? this.appUser),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._auth) : super(const AuthState()) {
    _sub = _auth.authStateChanges().listen(_onAuthState);
  }

  final AuthService _auth;
  StreamSubscription<User?>? _sub;

  Future<void> _onAuthState(User? user) async {
    if (user == null) {
      state = state.copyWith(clearUser: true, isLoading: false, clearError: true);
      return;
    }
    try {
      final profile = await _auth.getUserProfile(user.uid);
      state = AuthState(appUser: profile, isLoading: false);
    } catch (e) {
      state = AuthState(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _auth.signIn(email: email, password: password);
      state = AuthState(appUser: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _humanizeAuthError(e),
      );
      rethrow;
    }
  }

  Future<void> registerStudent({
    required String name,
    required String email,
    required String password,
    String? department,
    String? studentId,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _auth.registerStudent(
        name: name,
        email: email,
        password: password,
        department: department,
        studentId: studentId,
      );
      state = AuthState(appUser: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _humanizeAuthError(e),
      );
      rethrow;
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    await _auth.signOut();
    state = const AuthState(isLoading: false);
  }

  Future<void> refreshProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final profile = await _auth.getUserProfile(uid);
    state = AuthState(appUser: profile, isLoading: false);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  String _humanizeAuthError(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-email':
          return 'Invalid email address.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Email or password is incorrect.';
        case 'email-already-in-use':
          return 'That email is already registered.';
        case 'weak-password':
          return 'Password is too weak.';
        default:
          return e.message ?? e.code;
      }
    }
    if (e is ArgumentError) return e.message ?? e.toString();
    return e.toString();
  }
}

/// Dashboard route path by role.
String dashboardPathForRole(UserRole role) {
  switch (role) {
    case UserRole.student:
      return '/student';
    case UserRole.sectorOfficer:
      return '/officer';
    case UserRole.admin:
      return '/admin';
    case UserRole.vicePresident:
    case UserRole.president:
      return '/executive';
  }
}

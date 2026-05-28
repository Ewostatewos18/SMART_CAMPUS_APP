import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_status.dart';
import '../../../core/auth/session_prefs.dart';
import '../../../core/providers/service_providers.dart';
import '../../../core/services/firestore_bootstrap.dart';
import '../../../models/account_status.dart';
import '../../../models/user_model.dart';
import '../../../models/user_role.dart';
import '../../../services/auth_service.dart';
import '../models/registration_result.dart';

final authStateProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authServiceProvider));
});

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._auth) : super(const AuthState()) {
    _init();
  }

  final AuthService _auth;
  StreamSubscription<User?>? _authSub;
  StreamSubscription<AppUser?>? _profileSub;
  bool _handlingCredential = false;
  bool _registering = false;
  String? _activeSessionUid;

  Future<void> _init() async {
    state = const AuthState(status: AuthStatus.loading);
    _authSub = _auth.authStateChanges().listen(_onFirebaseUser);
  }

  Future<void> _onFirebaseUser(User? fbUser) async {
    if (_handlingCredential || _registering) return;

    if (fbUser == null) {
      _activeSessionUid = null;
      await _profileSub?.cancel();
      _profileSub = null;
      if (state.status != AuthStatus.unauthenticated) {
        state = AuthState(
          status: AuthStatus.unauthenticated,
          errorMessage: state.errorMessage,
        );
      }
      return;
    }

    // Keep a successful manual login — do not let the listener undo it.
    if (state.status == AuthStatus.authenticated &&
        state.user?.userId == fbUser.uid) {
      _activeSessionUid = fbUser.uid;
      return;
    }

    try {
      AppUser profile;
      try {
        profile = await _auth.resolveProfileForLogin(fbUser);
      } catch (e) {
        state = AuthState(
          status: AuthStatus.unauthenticated,
          errorMessage: _humanizeAuthError(e),
        );
        return;
      }

      if (!profile.canSignIn) {
        await _auth.signOut();
        _activeSessionUid = null;
        final message = profile.accountStatus == AccountStatus.pending
            ? (profile.role == UserRole.admin
                ? 'Admin account is not active yet. Try again or contact support.'
                : 'Your account is pending approval. Ask an administrator to approve you.')
            : profile.accountStatus == AccountStatus.rejected
                ? 'Your registration was rejected. Contact the Student Union.'
                : 'Your account has been deactivated.';
        state = AuthState(
          status: AuthStatus.unauthenticated,
          errorMessage: message,
        );
        return;
      }

      _activeSessionUid = fbUser.uid;
      await _bindProfileStream(fbUser.uid);
      state = AuthState(status: AuthStatus.authenticated, user: profile);
    } catch (e) {
      debugPrint('Auth listener error: $e');
      // Do not sign out if we already have this session from manual sign-in.
      if (_activeSessionUid == fbUser.uid &&
          state.status == AuthStatus.authenticated) {
        return;
      }
      await _auth.signOut();
      _activeSessionUid = null;
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: _humanizeAuthError(e),
      );
    }
  }

  Future<void> signIn(
    String email,
    String password, {
    bool rememberMe = false,
  }) async {
    _handlingCredential = true;
    try {
      final user = await _auth.signIn(
        email: email,
        password: password,
      );
      _activeSessionUid = user.userId;
      await SessionPrefs.saveRememberMe(remember: rememberMe, email: email);
      state = AuthState(status: AuthStatus.authenticated, user: user);
      await _bindProfileStream(user.userId);
    } catch (e) {
      _activeSessionUid = null;
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: _humanizeAuthError(e),
      );
      rethrow;
    } finally {
      // Let authStateChanges run only after session is committed.
      await Future<void>.delayed(const Duration(milliseconds: 100));
      _handlingCredential = false;
    }
  }

  Future<RegistrationResult> registerAccount({
    required UserRole role,
    required String name,
    required String email,
    required String password,
    String? phone,
    String? studentId,
    String? department,
    String? year,
    String? section,
    String? sectorId,
    String? position,
    String? officeInfo,
    String? adminCode,
    String? profileImageUrl,
  }) async {
    _registering = true;
    _handlingCredential = true;
    _activeSessionUid = null;
    try {
      final result = await _auth.registerAccount(
        role: role,
        name: name,
        email: email,
        password: password,
        phone: phone,
        studentId: studentId,
        department: department,
        year: year,
        section: section,
        sectorId: sectorId,
        position: position,
        officeInfo: officeInfo,
        adminCode: adminCode,
        profileImageUrl: profileImageUrl,
      );
      state = const AuthState(status: AuthStatus.unauthenticated);
      return result;
    } catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: _humanizeAuthError(e),
      );
      rethrow;
    } finally {
      _registering = false;
      await Future<void>.delayed(const Duration(milliseconds: 100));
      _handlingCredential = false;
    }
  }

  Future<void> signOut() async {
    _handlingCredential = true;
    try {
      _activeSessionUid = null;
      await _profileSub?.cancel();
      _profileSub = null;
      await _auth.signOut();
      state = const AuthState(status: AuthStatus.unauthenticated);
    } finally {
      _handlingCredential = false;
    }
  }

  Future<void> clearOrphanSession() async {
    _activeSessionUid = null;
    await _auth.signOut();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> refreshProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final profile = await _auth.getUserProfile(uid);
    if (profile != null && profile.canSignIn) {
      _activeSessionUid = uid;
      state = AuthState(status: AuthStatus.authenticated, user: profile);
    }
  }

  Future<void> _bindProfileStream(String uid) async {
    await _profileSub?.cancel();
    _profileSub = _auth.userProfileStream(uid).listen(
      (live) {
        if (live == null || !live.canSignIn) return;
        if (state.status == AuthStatus.authenticated) {
          state = AuthState(status: AuthStatus.authenticated, user: live);
        }
      },
      onError: (e) => debugPrint('Profile stream: $e'),
    );
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _profileSub?.cancel();
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
        case 'too-many-requests':
          return 'Too many attempts. Try again later.';
        default:
          return e.message ?? e.code;
      }
    }
    if (e is FirebaseException) {
      if (e.code == 'permission-denied') {
        return FirestoreBootstrap.permissionMessage();
      }
      if (e.code == 'unavailable' ||
          (e.message ?? '').toLowerCase().contains('offline')) {
        return FirestoreBootstrap.offlineMessage();
      }
      return e.message ?? e.code;
    }
    final text = e.toString().toLowerCase();
    if (text.contains('offline') || text.contains('unavailable')) {
      return FirestoreBootstrap.offlineMessage();
    }
    if (e is StateError) return e.message ?? e.toString();
    if (e is ArgumentError) return e.message ?? e.toString();
    return e.toString();
  }
}

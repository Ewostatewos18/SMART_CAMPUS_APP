import '../../models/user_model.dart';

/// High-level authentication lifecycle for routing and UI.
enum AuthStatus {
  /// App just started; resolving Firebase session.
  unknown,

  /// Loading profile or signing in.
  loading,

  /// Firebase + Firestore profile ready.
  authenticated,

  /// No session.
  unauthenticated,

  /// Firebase user exists but Firestore profile is missing (orphan account).
  profileMissing,
}

class AuthState {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.errorMessage,
  });

  final AuthStatus status;
  final AppUser? user;
  final String? errorMessage;

  bool get isLoading =>
      status == AuthStatus.unknown || status == AuthStatus.loading;

  bool get isAuthenticated =>
      status == AuthStatus.authenticated && user != null;

  AuthState copyWith({
    AuthStatus? status,
    AppUser? user,
    String? errorMessage,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

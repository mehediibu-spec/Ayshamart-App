import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../../data/models/app_user.dart';
import '../../../data/services/auth_service.dart';
import '../../../providers/core_providers.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final AppUser? user;

  const AuthState({required this.status, this.user});

  const AuthState.unknown() : this(status: AuthStatus.unknown);
  const AuthState.unauthenticated()
      : this(status: AuthStatus.unauthenticated);
  AuthState.authenticated(AppUser user)
      : this(status: AuthStatus.authenticated, user: user);

  bool get isLoggedIn => status == AuthStatus.authenticated && user != null;
}

final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(ref.watch(dioProvider)),
);

/// Holds auth state, persists the JWT, and exposes the current token to the
/// Dio interceptor (synchronously, via DioClient.authTokenProvider).
class AuthController extends StateNotifier<AuthState> {
  AuthController(this._service)
      : super(const AuthState.unknown()) {
    // The interceptor reads the token synchronously on every request.
    DioClient.authTokenProvider = () => _token;
    _restore();
  }

  final AuthService _service;
  final TokenStorage _storage = TokenStorage();
  String? _token;

  int? get customerId => state.user?.id;

  Future<void> _restore() async {
    final saved = await _storage.read();
    if (saved == null || saved.isEmpty) {
      state = const AuthState.unauthenticated();
      return;
    }
    _token = saved;
    try {
      final user = await _service.currentUser(token: saved);
      state = AuthState.authenticated(user);
    } catch (_) {
      // Token invalid/expired — wipe and require re-login.
      await _clearToken();
      state = const AuthState.unauthenticated();
    }
  }

  Future<void> login(String username, String password) async {
    final token = await _service.login(username.trim(), password);
    _token = token;
    await _storage.save(token);
    final user = await _service.currentUser(token: token);
    state = AuthState.authenticated(user);
  }

  Future<void> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    await _service.register(
      email: email.trim(),
      password: password,
      firstName: firstName.trim(),
      lastName: lastName.trim(),
    );
    // Auto-login with the new credentials.
    await login(email, password);
  }

  Future<void> logout() async {
    await _clearToken();
    state = const AuthState.unauthenticated();
  }

  Future<void> _clearToken() async {
    _token = null;
    await _storage.clear();
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>(
  (ref) => AuthController(ref.watch(authServiceProvider)),
);

/// Convenience: the WooCommerce customer id (null when guest).
final currentCustomerIdProvider = Provider<int?>(
  (ref) => ref.watch(authControllerProvider).user?.id,
);

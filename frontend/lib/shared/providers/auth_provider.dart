import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';

part 'auth_provider.g.dart';

enum AuthState { initial, unauthenticated, authenticated, error }

class AuthStateModel {
  final AuthState status;
  final String? uid;
  final bool isGuest;

  const AuthStateModel({
    this.status = AuthState.initial,
    this.uid,
    this.isGuest = false,
  });
}

@Riverpod(keepAlive: true)
class AuthNotifier extends _$AuthNotifier {
  @override
  Future<AuthStateModel> build() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('uid');
    final isGuest = prefs.getBool('isGuest') ?? false;

    if (uid != null) {
      return AuthStateModel(status: AuthState.authenticated, uid: uid, isGuest: isGuest);
    }
    return const AuthStateModel(status: AuthState.unauthenticated);
  }

  Future<void> signUp(String email, String password, {String? name}) async {
    state = const AsyncValue.loading();
    try {
      final response = await ApiClient().request<Map<String, dynamic>>(
        path: '/auth/signup',
        method: 'POST',
        data: {'email': email, 'password': password, 'name': name ?? ''},
        parser: (data) => data as Map<String, dynamic>,
      );

      if (response is ApiSuccess<Map<String, dynamic>>) {
        final uid = response.data['uid'] as String;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('uid', uid);
        await prefs.setBool('isGuest', false);
        state = AsyncValue.data(AuthStateModel(status: AuthState.authenticated, uid: uid, isGuest: false));
      } else if (response is ApiFailure<Map<String, dynamic>>) {
        state = AsyncValue.error(response.message, StackTrace.current);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signInAsGuest() async {
    state = const AsyncValue.loading();
    try {
      final response = await ApiClient().request<Map<String, dynamic>>(
        path: '/auth/guest',
        method: 'POST',
        parser: (data) => data as Map<String, dynamic>,
      );

      if (response is ApiSuccess<Map<String, dynamic>>) {
        final uid = response.data['uid'] as String;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('uid', uid);
        await prefs.setBool('isGuest', true);
        state = AsyncValue.data(AuthStateModel(status: AuthState.authenticated, uid: uid, isGuest: true));
      } else if (response is ApiFailure<Map<String, dynamic>>) {
        state = AsyncValue.error(response.message, StackTrace.current);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> logOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('uid');
    await prefs.remove('isGuest');
    state = const AsyncValue.data(AuthStateModel(status: AuthState.unauthenticated));
  }
}

@Riverpod(keepAlive: true)
String? currentUserId(CurrentUserIdRef ref) {
  final authState = ref.watch(authNotifierProvider).valueOrNull;
  return authState?.uid;
}

@Riverpod(keepAlive: true)
bool isGuest(IsGuestRef ref) {
  final authState = ref.watch(authNotifierProvider).valueOrNull;
  return authState?.isGuest ?? false;
}

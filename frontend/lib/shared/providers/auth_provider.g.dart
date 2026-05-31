// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$currentUserIdHash() => r'43b9969f450557dbb69d60d8d78c0ecba504b669';

/// See also [currentUserId].
@ProviderFor(currentUserId)
final currentUserIdProvider = Provider<String?>.internal(
  currentUserId,
  name: r'currentUserIdProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentUserIdHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef CurrentUserIdRef = ProviderRef<String?>;
String _$isGuestHash() => r'39adbcd6f5b911ad120eb8d0cb5c12bbb9b6620f';

/// See also [isGuest].
@ProviderFor(isGuest)
final isGuestProvider = Provider<bool>.internal(
  isGuest,
  name: r'isGuestProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$isGuestHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef IsGuestRef = ProviderRef<bool>;
String _$authNotifierHash() => r'9db31800e0431b34680bc2a0f2b99bb552a6b378';

/// See also [AuthNotifier].
@ProviderFor(AuthNotifier)
final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, AuthStateModel>.internal(
  AuthNotifier.new,
  name: r'authNotifierProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$authNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AuthNotifier = AsyncNotifier<AuthStateModel>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member

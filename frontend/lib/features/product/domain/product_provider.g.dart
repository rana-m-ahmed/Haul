// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$productNotifierHash() => r'80635ed0490fde5e9b57d185c118778d151749df';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

abstract class _$ProductNotifier
    extends BuildlessAutoDisposeNotifier<ProductState> {
  late final String productId;

  ProductState build(
    String productId,
  );
}

/// See also [ProductNotifier].
@ProviderFor(ProductNotifier)
const productNotifierProvider = ProductNotifierFamily();

/// See also [ProductNotifier].
class ProductNotifierFamily extends Family<ProductState> {
  /// See also [ProductNotifier].
  const ProductNotifierFamily();

  /// See also [ProductNotifier].
  ProductNotifierProvider call(
    String productId,
  ) {
    return ProductNotifierProvider(
      productId,
    );
  }

  @override
  ProductNotifierProvider getProviderOverride(
    covariant ProductNotifierProvider provider,
  ) {
    return call(
      provider.productId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'productNotifierProvider';
}

/// See also [ProductNotifier].
class ProductNotifierProvider
    extends AutoDisposeNotifierProviderImpl<ProductNotifier, ProductState> {
  /// See also [ProductNotifier].
  ProductNotifierProvider(
    String productId,
  ) : this._internal(
          () => ProductNotifier()..productId = productId,
          from: productNotifierProvider,
          name: r'productNotifierProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$productNotifierHash,
          dependencies: ProductNotifierFamily._dependencies,
          allTransitiveDependencies:
              ProductNotifierFamily._allTransitiveDependencies,
          productId: productId,
        );

  ProductNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.productId,
  }) : super.internal();

  final String productId;

  @override
  ProductState runNotifierBuild(
    covariant ProductNotifier notifier,
  ) {
    return notifier.build(
      productId,
    );
  }

  @override
  Override overrideWith(ProductNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: ProductNotifierProvider._internal(
        () => create()..productId = productId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        productId: productId,
      ),
    );
  }

  @override
  AutoDisposeNotifierProviderElement<ProductNotifier, ProductState>
      createElement() {
    return _ProductNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ProductNotifierProvider && other.productId == productId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, productId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin ProductNotifierRef on AutoDisposeNotifierProviderRef<ProductState> {
  /// The parameter `productId` of this provider.
  String get productId;
}

class _ProductNotifierProviderElement
    extends AutoDisposeNotifierProviderElement<ProductNotifier, ProductState>
    with ProductNotifierRef {
  _ProductNotifierProviderElement(super.provider);

  @override
  String get productId => (origin as ProductNotifierProvider).productId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member

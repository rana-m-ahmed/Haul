import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/cart_provider.dart';

part 'checkout_provider.g.dart';

class ShippingAddress {
  final String name;
  final String line1;
  final String line2;
  final String city;
  final String state;
  final String zip;
  final String country;

  ShippingAddress({
    required this.name,
    required this.line1,
    this.line2 = '',
    required this.city,
    required this.state,
    required this.zip,
    required this.country,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'line1': line1,
    'line2': line2,
    'city': city,
    'state': state,
    'zip': zip,
    'country': country,
  };
}

class CheckoutState {
  final int currentStep; // 0 = Shipping, 1 = Payment
  final ShippingAddress? address;
  final bool isProcessing;
  final String? error;
  final String? orderId;

  CheckoutState({
    this.currentStep = 0,
    this.address,
    this.isProcessing = false,
    this.error,
    this.orderId,
  });

  CheckoutState copyWith({
    int? currentStep,
    ShippingAddress? address,
    bool? isProcessing,
    String? error,
    bool clearError = false,
    String? orderId,
  }) {
    return CheckoutState(
      currentStep: currentStep ?? this.currentStep,
      address: address ?? this.address,
      isProcessing: isProcessing ?? this.isProcessing,
      error: clearError ? null : (error ?? this.error),
      orderId: orderId ?? this.orderId,
    );
  }
}

@riverpod
class CheckoutNotifier extends _$CheckoutNotifier {
  @override
  CheckoutState build() {
    return CheckoutState();
  }

  void submitShipping(ShippingAddress address) {
    state = state.copyWith(address: address, currentStep: 1, clearError: true);
  }

  void goBack() {
    if (state.currentStep == 1) {
      state = state.copyWith(currentStep: 0, clearError: true);
    }
  }

  Future<void> placeOrder({required String cardNumber, required String expiry, required String cvc}) async {
    if (state.address == null) return;
    
    final cartItems = ref.read(cartNotifierProvider);
    final total = ref.read(cartNotifierProvider.notifier).subtotal;
    final userId = ref.read(currentUserIdProvider) ?? 'guest_123';
    
    if (cartItems.isEmpty) {
      state = state.copyWith(error: 'Cart is empty');
      return;
    }

    state = state.copyWith(isProcessing: true, clearError: true);

    try {
      // 1. Create and auto-confirm Payment Intent via backend
      final intentRes = await ApiClient().request<Map<String, dynamic>>(
        path: '/create-payment-intent',
        method: 'POST',
        data: {
          'amount': (total * 100).round(),
          'currency': 'usd',
          'userId': userId,
        },
        parser: (data) => data as Map<String, dynamic>,
      );

      if (intentRes is! ApiSuccess<Map<String, dynamic>>) {
        throw Exception((intentRes as ApiFailure).message);
      }

      final intentId = intentRes.data['paymentIntentId'] ?? intentRes.data['id'];

      // 2. Create Order
      final items = cartItems.map((item) => {
        'productId': item.product.id,
        'quantity': item.quantity,
        'variant': item.variant,
      }).toList();

      final orderRes = await ApiClient().request<Map<String, dynamic>>(
        path: '/orders',
        method: 'POST',
        data: {
          'userId': userId,
          'items': items,
          'shippingAddress': state.address!.toJson(),
          'stripePaymentIntentId': intentId,
        },
        parser: (data) => data as Map<String, dynamic>,
      );

      if (orderRes is! ApiSuccess<Map<String, dynamic>>) {
        throw Exception((orderRes as ApiFailure).message);
      }

      ref.read(cartNotifierProvider.notifier).clearCart();
      state = state.copyWith(isProcessing: false, orderId: orderRes.data['orderId']);

    } catch (e) {
      state = state.copyWith(isProcessing: false, error: e.toString());
    }
  }
}


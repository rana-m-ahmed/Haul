import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/providers/cart_provider.dart';
import '../domain/checkout_provider.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _shippingFormKey = GlobalKey<FormState>();
  final _paymentFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _line1Controller = TextEditingController();
  final _line2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();
  final _countryController = TextEditingController(text: 'US');
  
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvcController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _line1Controller.dispose();
    _line2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _countryController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvcController.dispose();
    super.dispose();
  }

  void _submitShipping() {
    if (_shippingFormKey.currentState?.validate() ?? false) {
      ref.read(checkoutNotifierProvider.notifier).submitShipping(
        ShippingAddress(
          name: _nameController.text.trim(),
          line1: _line1Controller.text.trim(),
          line2: _line2Controller.text.trim(),
          city: _cityController.text.trim(),
          state: _stateController.text.trim(),
          zip: _zipController.text.trim(),
          country: _countryController.text.trim(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(checkoutNotifierProvider);
    final total = ref.watch(cartNotifierProvider.notifier).subtotal;

    ref.listen<CheckoutState>(checkoutNotifierProvider, (prev, next) {
      if (next.orderId != null && prev?.orderId == null) {
        context.go('/order/${next.orderId}/success');
      }
      if (next.error != null && prev?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: AppColors.errorCrimson),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.ink),
          onPressed: () {
            if (state.currentStep == 1) {
              ref.read(checkoutNotifierProvider.notifier).goBack();
            } else {
              context.pop();
            }
          },
        ),
        title: Text('CHECKOUT', style: AppTypography.titleLG.copyWith(color: AppColors.ink)),
      ),
      body: Column(
        children: [
          // Step indicator
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 2,
                  color: AppColors.signal,
                ),
              ),
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  height: 2,
                  color: state.currentStep == 1 ? AppColors.signal : AppColors.surfaceAlt,
                ),
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: state.currentStep == 0 ? _buildShippingForm() : _buildPaymentForm(total, state.isProcessing),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: const BoxDecoration(
          color: AppColors.warmWhite,
          border: Border(top: BorderSide(color: AppColors.surfaceAlt)),
        ),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: state.isProcessing ? AppColors.pebble : AppColors.ink,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: state.isProcessing
                ? null
                : (state.currentStep == 0
                    ? _submitShipping
                    : () {
                        if (_paymentFormKey.currentState?.validate() ?? false) {
                          ref.read(checkoutNotifierProvider.notifier).placeOrder(
                            cardNumber: _cardNumberController.text,
                            expiry: _expiryController.text,
                            cvc: _cvcController.text,
                          );
                        }
                      }),
            child: state.isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.warmWhite),
                  )
                : Text(
                    state.currentStep == 0 ? 'CONTINUE →' : 'PLACE ORDER — \$${total.toStringAsFixed(2)} →',
                    style: AppTypography.labelMD.copyWith(color: AppColors.warmWhite),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildShippingForm() {
    return Form(
      key: _shippingFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Shipping Address', style: AppTypography.titleLG.copyWith(color: AppColors.ink)),
          const SizedBox(height: AppSpacing.lg),
          _buildField('Full Name', _nameController, required: true),
          _buildField('Address Line 1', _line1Controller, required: true),
          _buildField('Address Line 2 (Optional)', _line2Controller),
          Row(
            children: [
              Expanded(child: _buildField('City', _cityController, required: true)),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: _buildField('State', _stateController, required: true)),
            ],
          ),
          Row(
            children: [
              Expanded(child: _buildField('ZIP Code', _zipController, required: true)),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: _buildField('Country', _countryController, required: true)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.labelSM.copyWith(color: AppColors.stone)),
          TextFormField(
            controller: controller,
            style: AppTypography.bodyMD.copyWith(color: AppColors.ink),
            validator: required ? (v) => v == null || v.trim().isEmpty ? 'Required' : null : null,
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 8),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.pebble)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.signal)),
              errorBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.errorCrimson)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentForm(double total, bool isProcessing) {
    final itemCount = ref.read(cartNotifierProvider.notifier).itemCount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Payment', style: AppTypography.titleLG.copyWith(color: AppColors.ink)),
        const SizedBox(height: AppSpacing.lg),
        
        // Summary Card
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('$itemCount items', style: AppTypography.bodyMD.copyWith(color: AppColors.stone)),
                  Text('\$${total.toStringAsFixed(2)}', style: AppTypography.bodyMD.copyWith(color: AppColors.ink)),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              const Divider(),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('TOTAL', style: AppTypography.monoMD.copyWith(color: AppColors.signal, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('\$${total.toStringAsFixed(2)}', style: AppTypography.monoMD.copyWith(color: AppColors.signal, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(height: AppSpacing.xl),
        
        // Custom Card Fields
        Text('Card Details', style: AppTypography.labelSM.copyWith(color: AppColors.stone)),
        const SizedBox(height: AppSpacing.sm),
        Form(
          key: _paymentFormKey,
          child: IgnorePointer(
            ignoring: isProcessing,
            child: Column(
              children: [
                _buildField('Card Number', _cardNumberController, required: true),
                Row(
                  children: [
                    Expanded(child: _buildField('MM/YY', _expiryController, required: true)),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: _buildField('CVC', _cvcController, required: true)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

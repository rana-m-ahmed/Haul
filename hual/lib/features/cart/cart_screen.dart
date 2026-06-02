import 'package:flutter/material.dart';
import '../../shared/widgets/haul_empty_state.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
      ),
      body: const HaulEmptyState(
        title: 'Your cart is empty',
        message: 'Looks like you haven\'t added anything to your cart yet.',
        icon: Icons.shopping_bag_outlined,
      ),
    );
  }
}

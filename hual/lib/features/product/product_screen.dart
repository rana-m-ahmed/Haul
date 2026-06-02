import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../shared/widgets/haul_empty_state.dart';

class ProductScreen extends StatelessWidget {
  final String productId;

  const ProductScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: Text('Product $productId'),
      ),
      body: HaulEmptyState(
        title: 'Product Details',
        message: 'Viewing details for product $productId.',
        icon: Icons.inventory_2_outlined,
      ),
    );
  }
}

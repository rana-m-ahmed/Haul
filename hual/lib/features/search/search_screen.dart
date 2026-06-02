import 'package:flutter/material.dart';
import '../../shared/widgets/haul_empty_state.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
      ),
      body: const HaulEmptyState(
        title: 'Find what you love',
        message: 'Search for products, categories, or brands.',
        icon: Icons.search,
      ),
    );
  }
}

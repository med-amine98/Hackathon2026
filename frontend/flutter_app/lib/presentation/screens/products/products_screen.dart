// lib/presentation/screens/products/products_screen.dart

import 'package:flutter/material.dart';
import 'package:ai_insurance_advisor/data/models/product.dart';
import 'package:ai_insurance_advisor/data/repositories/product_repository.dart';
import 'package:ai_insurance_advisor/injection/dependency_injection.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  late final ProductRepository _repository;
  List<InsuranceProduct> _products = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Utiliser le repository enregistré dans get_it : il partage l'ApiClient
    // configuré avec SharedPreferences, qui attache le token d'authentification.
    _repository = getIt<ProductRepository>();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await _repository.getProducts();
      _products = data.map((item) => InsuranceProduct.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Erreur: $_error'),
            ElevatedButton(
              onPressed: _loadProducts,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_products.isEmpty) {
      return const Center(
        child: Text('Aucun produit disponible'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(product.name),
            subtitle: Text('${product.provider} - ${product.formattedPremium}'),
            trailing: Text('⭐ ${product.rating}'),
            onTap: () {
              Navigator.pushNamed(
                context,
                '/product_detail',
                arguments: product.id.toString(),
              );
            },
          ),
        );
      },
    );
  }
}
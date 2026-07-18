// lib/presentation/screens/products/product_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:ai_insurance_advisor/data/models/product.dart';
import 'package:ai_insurance_advisor/data/repositories/product_repository.dart';
import 'package:ai_insurance_advisor/injection/dependency_injection.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late final ProductRepository _repository;
  InsuranceProduct? _product;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Utiliser le repository enregistré dans get_it : il partage l'ApiClient
    // configuré avec SharedPreferences, qui attache le token d'authentification.
    _repository = getIt<ProductRepository>();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await _repository.getProduct(widget.productId);
      setState(() {
        _product = InsuranceProduct.fromJson(data);
      });
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
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Erreur: $_error'),
              ElevatedButton(
                onPressed: _loadProduct,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (_product == null) {
      return const Scaffold(
        body: Center(child: Text('Produit non trouvé')),
      );
    }

    final product = _product!;

    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                product.provider,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              _buildInfoRow('Catégorie', product.category),
              _buildInfoRow('Prime mensuelle', product.formattedPremium),
              _buildInfoRow('Couverture', product.formattedCoverage),
              _buildInfoRow('Évaluation', '⭐ ${product.rating} (${product.reviewsCount} avis)'),
              const SizedBox(height: 16),
              const Text(
                'Caractéristiques :',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...product.features.map((feature) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.check, color: Colors.green, size: 16),
                    const SizedBox(width: 8),
                    Text(feature),
                  ],
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
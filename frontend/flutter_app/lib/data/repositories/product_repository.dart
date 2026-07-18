import 'package:ai_insurance_advisor/data/datasources/remote/api_client.dart';

class ProductRepository {
  final ApiClient _apiClient;

  ProductRepository(this._apiClient);

  Future<List<dynamic>> getProducts({String? category}) async {
    return await _apiClient.getProducts(category: category);
  }

  Future<Map<String, dynamic>> getProduct(String id) async {
    return await _apiClient.getProduct(id);
  }
}
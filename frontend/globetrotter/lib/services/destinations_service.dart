import 'api_service.dart';
import '../models/destination.dart';

class DestinationsService {
  Future<List<Destination>> list({String? query, String? category}) async {
    final params = <String, String>{};
    if (query != null && query.isNotEmpty) params['q'] = query;
    if (category != null && category.isNotEmpty) params['category'] = category;

    final queryString =
        params.isEmpty ? '' : '?${Uri(queryParameters: params).query}';

    final result = await apiService.get('/destinations$queryString');
    return (result as List).map((json) => Destination.fromJson(json)).toList();
  }

  Future<Destination> getById(String id) async {
    final result = await apiService.get('/destinations/$id');
    return Destination.fromJson(result);
  }
}

final destinationsService = DestinationsService();

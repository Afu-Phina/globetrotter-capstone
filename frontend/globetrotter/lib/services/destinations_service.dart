import 'api_service.dart';
import '../models/destination.dart';
import '../models/review.dart';

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

  Future<List<Review>> getReviews(String destinationId) async {
    final result = await apiService.get('/destinations/$destinationId/reviews');
    return (result as List).map((json) => Review.fromJson(json)).toList();
  }

  Future<Review> addReview(String destinationId, int rating, String comment) async {
    final result = await apiService.post('/destinations/$destinationId/reviews', {
      'rating': rating,
      'comment': comment,
    });
    return Review.fromJson(result);
  }

  Future<String> ask(String destinationId, String question) async {
    final result = await apiService.post('/destinations/$destinationId/ask', {
      'question': question,
    });
    return result['answer'] as String;
  }
}

final destinationsService = DestinationsService();

import 'api_service.dart';
import '../models/itinerary.dart';
import '../models/destination.dart';

class ItinerariesService {
  Future<List<Itinerary>> list() async {
    final result = await apiService.get('/itineraries');
    return (result as List).map((json) => Itinerary.fromJson(json)).toList();
  }

  Future<Itinerary> create({
    required String title,
    List<String> destinationIds = const [],
    String notes = '',
  }) async {
    final result = await apiService.post('/itineraries', {
      'title': title,
      'destination_ids': destinationIds,
      'notes': notes,
    });
    return Itinerary.fromJson(result);
  }

  Future<Itinerary> update(String id, Map<String, dynamic> changes) async {
    final result = await apiService.put('/itineraries/$id', changes);
    return Itinerary.fromJson(result);
  }

  Future<void> delete(String id) async {
    await apiService.delete('/itineraries/$id');
  }

  Future<Itinerary> share(String id, String email) async {
    final result = await apiService.post('/itineraries/$id/share', {'email': email});
    return Itinerary.fromJson(result);
  }
}

class RecommendationsService {
  Future<List<Destination>> get() async {
    final result = await apiService.get('/recommendations');
    return (result as List).map((json) => Destination.fromJson(json)).toList();
  }
}

final itinerariesService = ItinerariesService();
final recommendationsService = RecommendationsService();

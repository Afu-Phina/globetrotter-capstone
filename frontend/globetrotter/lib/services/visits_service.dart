import 'api_service.dart';
import '../models/visit.dart';

class VisitsService {
  Future<Visit> book({
    required String destinationId,
    required String date,
    required String time,
    required int numPeople,
  }) async {
    final result = await apiService.post('/visits', {
      'destination_id': destinationId,
      'date': date,
      'time': time,
      'num_people': numPeople,
    });
    return Visit.fromJson(result);
  }

  Future<List<Visit>> listMine() async {
    final result = await apiService.get('/visits');
    return (result as List).map((json) => Visit.fromJson(json)).toList();
  }

  Future<void> cancel(String id) async {
    await apiService.delete('/visits/$id');
  }
}

final visitsService = VisitsService();

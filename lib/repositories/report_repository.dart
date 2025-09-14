import '../services/api_service.dart';

class ReportRepository {
  Future<List<Map<String, dynamic>>> fetchReports(DateTime from, DateTime to) async {
    final fromStr = from.toIso8601String();
    final toStr = to.toIso8601String();

    final data = await ApiService.get('/reports?from=$fromStr&to=$toStr');
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> exportReportsCSV(DateTime from, DateTime to) async {
    final fromStr = from.toIso8601String();
    final toStr = to.toIso8601String();

    await ApiService.get('/reports/export?from=$fromStr&to=$toStr');
  }
}

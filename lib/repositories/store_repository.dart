import '../services/api_service.dart';
import '../models/store_model.dart';

class StoreRepository {
  Future<List<Store>> fetchStores() async {
    final data = await ApiService.get('/stores');
    return (data['stores'] as List).map((json) => Store.fromJson(json)).toList();
  }

  Future<List<Store>> fetchStoresByDate(DateTime date) async {
    final d = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    final data = await ApiService.get('/stores/by-date?date=$d');
    return (data['stores'] as List).map((json) => Store.fromJson(json)).toList();
  }

  Future<void> addStore(Store store) async {
    await ApiService.post('/stores', store.toJson());
  }

  Future<void> updateStore(int id, Store store) async {
    await ApiService.put('/stores/$id', store.toJson());
  }

  Future<void> deleteStore(int id) async {
    await ApiService.delete('/stores/$id');
  }

  Future<void> saveNote(int paymentId, String note) async {
    await ApiService.put('/payments/$paymentId/note', {'note': note});
  }
}

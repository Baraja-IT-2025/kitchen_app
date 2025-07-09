import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class OrderService {
  final String? baseUrl = dotenv.env['BASE_URL'];

  Future<List<dynamic>> fetchKitchenOrders() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/orders/kitchen'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'ngrok-skip-browser-warning': 'true'
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          return data['data'];
        } else {
          throw Exception('Gagal memuat kitchen orders: Server tidak berhasil');
        }
      } else {
        throw Exception('Gagal memuat kitchen orders: Status ${response.statusCode}');
      }
    } catch (e) {
      print('Error saat mengambil kitchen orders: $e');
      rethrow;
    }
  }

  // Tambahkan method untuk update status order
  Future<bool> updateOrderStatus(String orderId, String newStatus) async {
    try {
      print('Updating order $orderId to status: $newStatus');

      final response = await http.put(
        Uri.parse('$baseUrl/api/orders/$orderId/status'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'ngrok-skip-browser-warning': 'true'
        },
        body: json.encode({
          'status': newStatus,
          'updatedAt': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Order status updated successfully: $data');
        return data['success'] == true;
      } else {
        print('Failed to update order status: ${response.statusCode}');
        print('Response body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error updating order status: $e');
      return false;
    }
  }

  // Method untuk update multiple orders sekaligus (jika diperlukan)
  Future<bool> updateMultipleOrdersStatus(List<String> orderIds, String newStatus) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/orders/bulk-status'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'ngrok-skip-browser-warning': 'true'
        },
        body: json.encode({
          'orderIds': orderIds,
          'status': newStatus,
          'updatedAt': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      } else {
        return false;
      }
    } catch (e) {
      print('Error updating multiple orders status: $e');
      return false;
    }
  }
}
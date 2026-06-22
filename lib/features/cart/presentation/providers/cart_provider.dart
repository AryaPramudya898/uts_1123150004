import 'package:flutter/foundation.dart';
import 'package:uts_1123150004/core/services/dio_client.dart';
import 'package:uts_1123150004/core/services/notification_service.dart';
import 'package:uts_1123150004/features/cart/data/models/cart_item_model.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => _items;

  int get itemCount => _items.length;

  double get totalPrice {
    return _items.fold(0, (sum, item) => sum + item.totalPrice);
  }

  /// Ambil data keranjang dari backend
  Future<void> fetchCart() async {
    try {
      final response = await DioClient.instance.get('/cart');
      final data = response.data['data'] as List;
      _items.clear();
      _items.addAll(data.map((item) => CartItem.fromJson(item as Map<String, dynamic>)));
      notifyListeners();
    } catch (e) {
      debugPrint('[CartProvider] Gagal mengambil keranjang: $e');
    }
  }

  /// Tambah barang ke cart
  Future<void> addItem(String productId, String productName, double price, {String? imageUrl}) async {
    final index = _items.indexWhere((item) => item.productId == productId);
    
    if (index == -1) {
      // Item tidak ada, tambah baru
      final newItem = CartItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        productId: productId,
        productName: productName,
        price: price,
        quantity: 1,
        imageUrl: imageUrl,
      );
      _items.add(newItem);
    } else {
      // Item sudah ada, update quantity
      final item = _items[index];
      final updatedItem = item.copyWith(quantity: item.quantity + 1);
      _items[index] = updatedItem;
    }
    notifyListeners();

    // Tampilkan notifikasi lokal
    NotificationService.showNotification(
      id: productId.hashCode,
      title: 'Keranjang Belanja',
      body: 'Berhasil menambahkan $productName ke keranjang!',
    );

    // Sinkronisasi ke backend
    try {
      await DioClient.instance.post('/cart', data: {
        'product_id': int.parse(productId),
        'quantity': 1,
      });
      // Ambil ulang data untuk menyamakan ID real dari backend
      await fetchCart();
    } catch (e) {
      debugPrint('[CartProvider] Gagal sinkronisasi tambah item ke backend: $e');
    }
  }

  /// Hapus barang dari cart
  Future<void> removeItem(String productId) async {
    _items.removeWhere((item) => item.productId == productId);
    notifyListeners();

    // Sinkronisasi ke backend
    try {
      await DioClient.instance.delete('/cart/$productId');
    } catch (e) {
      debugPrint('[CartProvider] Gagal menghapus item dari backend: $e');
    }
  }

  /// Update quantity barang
  Future<void> updateItemQuantity(String productId, int quantity) async {
    final index = _items.indexWhere((item) => item.productId == productId);
    if (index != -1) {
      if (quantity <= 0) {
        _items.removeAt(index);
      } else {
        _items[index] = _items[index].copyWith(quantity: quantity);
      }
      notifyListeners();
    }

    // Sinkronisasi ke backend
    try {
      await DioClient.instance.put('/cart', data: {
        'product_id': int.parse(productId),
        'quantity': quantity,
      });
    } catch (e) {
      debugPrint('[CartProvider] Gagal update quantity ke backend: $e');
    }
  }

  /// Clear semua item
  Future<void> clearCart() async {
    _items.clear();
    notifyListeners();

    // Sinkronisasi ke backend
    try {
      await DioClient.instance.delete('/cart');
    } catch (e) {
      debugPrint('[CartProvider] Gagal mengosongkan keranjang di backend: $e');
    }
  }

  /// Restore items from checkout
  Future<void> restoreCart(List<CartItem> items) async {
    if (items.isEmpty) return;
    _items.clear();
    _items.addAll(items);
    notifyListeners();

    // Sinkronisasi ke backend
    try {
      // Clear cart on backend first
      await DioClient.instance.delete('/cart');
      // Add items back to backend
      for (final item in items) {
        await DioClient.instance.post('/cart', data: {
          'product_id': int.parse(item.productId),
          'quantity': item.quantity,
        });
      }
      // Re-fetch to sync IDs properly
      await fetchCart();
    } catch (e) {
      debugPrint('[CartProvider] Gagal restore keranjang ke backend: $e');
    }
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_links/app_links.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uts_1123150004/core/constants/app_colors.dart';
import 'package:uts_1123150004/core/services/secure_storage.dart';
import 'package:uts_1123150004/core/services/dio_client.dart';
import 'package:uts_1123150004/core/routes/app_router.dart';
import 'package:uts_1123150004/features/cart/data/models/cart_item_model.dart';
import '../providers/cart_provider.dart';
import 'payment_success_page.dart';
import 'package:uts_1123150004/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:uts_1123150004/core/services/notification_service.dart';

class CheckoutPage extends StatefulWidget {
  final Map<String, dynamic>? pendingTransaction;
  const CheckoutPage({Key? key, this.pendingTransaction}) : super(key: key);

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> with WidgetsBindingObserver {
  bool _isProcessing = false;
  bool _isWalletConnected = false;
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  List<CartItem> _tempCartItems = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initDeepLinkListener();
    _checkWalletStatus();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.pendingTransaction == null) {
        final cartProvider = context.read<CartProvider>();
        setState(() {
          _tempCartItems = List.from(cartProvider.items);
        });
        cartProvider.clearCartLocally();
      }
    });
  }

  Future<void> _restoreCart() async {
    if (widget.pendingTransaction == null && _tempCartItems.isNotEmpty) {
      final itemsToRestore = List<CartItem>.from(_tempCartItems);
      _tempCartItems.clear();
      await context.read<CartProvider>().restoreCart(itemsToRestore);
    }
  }

  Future<void> _cancelAndGoBack() async {
    if (_isProcessing) return;
    await _restoreCart();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _checkWalletStatus() async {
    final connected = await SecureStorage.isWalletConnected();
    if (mounted) {
      setState(() {
        _isWalletConnected = connected;
      });
    }
  }

  void _initDeepLinkListener() {
    _appLinks = AppLinks();
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) async {
      debugPrint('[CheckoutPage] Deep link received: $uri');
      if (uri.scheme == 'sepatufutsal' && uri.host == 'checkout') {
        final status = uri.queryParameters['status'];
        final reference = uri.queryParameters['reference'] ?? '';
        final transactionId = uri.queryParameters['transaction_id'] ?? '';

        if (status == 'success') {
          _onPaymentSuccess(reference, transactionId);
        } else if (status == 'cancelled') {
          _onPaymentCancelled(reference);
        } else if (status == 'failed') {
          final error = uri.queryParameters['error'] ?? 'Pembayaran gagal';
          _onPaymentFailed(reference, error);
        }
      } else if (uri.scheme == 'sepatufutsal' && uri.host == 'connect') {
        final status = uri.queryParameters['status'];
        if (status == 'success') {
          await SecureStorage.setWalletConnected(true);
          if (mounted) {
            setState(() {
              _isWalletConnected = true;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Berhasil terhubung ke Coach E-Money!'),
                backgroundColor: AppColors.primary,
              ),
            );
          }
        }
      }
    });
  }

  void _onPaymentSuccess(String reference, String transactionId) async {
    if (reference.isNotEmpty) {
      try {
        await DioClient.instance.put('/transactions/$reference/status', data: {
          'status': 'success',
          'transaction_id': transactionId,
        });
      } catch (e) {
        debugPrint('[CheckoutPage] Gagal update status transaksi ke backend: $e');
      }
    }

    // Tampilkan notifikasi lokal pembayaran berhasil
    try {
      await NotificationService.showNotification(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: 'Pembayaran Berhasil',
        body: 'Pembayaran berhasil menggunakan Coach E-Money.',
      );
    } catch (e) {
      debugPrint('[CheckoutPage] Gagal memicu notifikasi lokal: $e');
    }

    if (!mounted) return;
    setState(() {
      _isProcessing = false;
    });
    _tempCartItems.clear();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentSuccessPage(
          onSuccess: () {
            // Clear cart setelah sukses
            context.read<CartProvider>().clearCart();
            Navigator.popUntil(context, (route) => route.isFirst);
          },
        ),
      ),
    );
  }

  void _onPaymentCancelled(String reference) {
    if (!mounted) return;
    setState(() {
      _isProcessing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pembayaran dibatalkan oleh pengguna.'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _onPaymentFailed(String reference, String error) {
    if (!mounted) return;
    setState(() {
      _isProcessing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pembayaran gagal: $error'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _connectWallet() async {
    final uri = Uri.parse('dompetkampus://connect').replace(
      queryParameters: {
        'merchant_id': '1123150004',
        'merchant_name': 'Sepatu Ku',
        'callback': 'sepatufutsal://connect',
      },
    );
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        throw Exception('Gagal membuka Dompet Kampus. Pastikan aplikasi e-money sudah terpasang.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _processCheckout() async {
    final double amount;
    final String description;
    final String reference;
    final callbackUrl = 'sepatufutsal://checkout';
    final merchantId = '1123150004';
    final merchantName = 'Sepatu Ku';

    if (widget.pendingTransaction != null) {
      amount = (widget.pendingTransaction!['amount'] as num).toDouble();
      description = widget.pendingTransaction!['description'] as String? ?? '';
      reference = widget.pendingTransaction!['reference'] as String? ?? '';
    } else {
      amount = _tempCartItems.fold(0.0, (sum, item) => sum + item.totalPrice);
      if (amount <= 0) return;

      description = _tempCartItems
          .map((i) => '${i.productName} (x${i.quantity})')
          .join(', ');
      reference = 'ORD-${DateTime.now().millisecondsSinceEpoch}';

      setState(() {
        _isProcessing = true;
      });

      // 1. Kirim transaksi pending ke Go backend
      try {
        await DioClient.instance.post('/transactions', data: {
          'reference': reference,
          'amount': amount,
          'description': description,
        });
        if (mounted) {
          await context.read<CartProvider>().clearCart();
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal membuat transaksi di server: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    // 2. Launch E-Money deep link
    final uri = Uri.parse('dompetkampus://pay').replace(
      queryParameters: {
        'merchant_id': merchantId,
        'merchant_name': merchantName,
        'amount': amount.toStringAsFixed(0),
        'description': description,
        'reference': reference,
        'callback': callbackUrl,
      },
    );

    try {
      setState(() {
        _isProcessing = true;
      });
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalNonBrowserApplication,
      );
      if (!launched) {
        throw Exception('Gagal membuka aplikasi Coach E-Money. Pastikan aplikasi Coach E-Money terpasang.');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint('[CheckoutPage] App resumed, resetting processing status');
      if (mounted && _isProcessing) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isProcessing) return false;
        await _restoreCart();
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: const Text('Konfirmasi Pesanan'),
          centerTitle: true,
          automaticallyImplyLeading: false,
          leading: !_isProcessing
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _cancelAndGoBack,
                )
              : null,
          elevation: 2,
        ),
        body: Consumer<CartProvider>(
          builder: (context, cartProvider, _) {
            if (widget.pendingTransaction == null && _tempCartItems.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.lightGreen50,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.shopping_cart_outlined,
                        size: 80,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Tidak Ada Item di Keranjang',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              );
            }

            final int itemCount = widget.pendingTransaction != null ? 1 : _tempCartItems.length;
            final double totalPrice = widget.pendingTransaction != null
                ? (widget.pendingTransaction!['amount'] as num).toDouble()
                : _tempCartItems.fold(0.0, (sum, item) => sum + item.totalPrice);
            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Checkout Info
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            color: AppColors.lightGreen50,
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(16),
                              bottomRight: Radius.circular(16),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.receipt_long,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Ringkasan Pesanan',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Total Item',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                         Text(
                                          '$itemCount item',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      width: 1,
                                      height: 30,
                                      color: AppColors.divider,
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        const Text(
                                          'Total Harga',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Rp ${totalPrice.toStringAsFixed(0)}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Item List Title
                        const Padding(
                          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Text(
                            'Item yang Dibeli',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),

                        // Item List (Column instead of scrollable ListView)
                         ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: widget.pendingTransaction != null ? 1 : _tempCartItems.length,
                          itemBuilder: (context, index) {
                            if (widget.pendingTransaction != null) {
                              final description = widget.pendingTransaction!['description'] as String? ?? 'Pembayaran';
                              final double amount = (widget.pendingTransaction!['amount'] as num? ?? 0).toDouble();
                              return Card(
                                elevation: 1,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: Colors.grey.shade200),
                                ),
                                margin: const EdgeInsets.only(bottom: 8),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          color: AppColors.lightGreen50,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.shopping_bag_outlined,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              description,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.textPrimary,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Total: Rp ${amount.toStringAsFixed(0)}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          const Text(
                                            'Subtotal',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Rp ${amount.toStringAsFixed(0)}',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                            final item = _tempCartItems[index];
                            return Card(
                              elevation: 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Colors.grey.shade200),
                              ),
                              margin: const EdgeInsets.only(bottom: 8),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: AppColors.lightGreen50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: item.imageUrl != null
                                          ? ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: Image.network(
                                                item.imageUrl!,
                                                fit: BoxFit.cover,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.image,
                                              color: AppColors.primary,
                                            ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.productName,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textPrimary,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Qty: ${item.quantity}  ·  Rp ${item.price.toStringAsFixed(0)}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        const Text(
                                          'Subtotal',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Rp ${item.totalPrice.toStringAsFixed(0)}',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                        const Divider(height: 24, thickness: 1, indent: 16, endIndent: 16),

                        // Metode Pembayaran Section
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Metode Pembayaran',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (_isWalletConnected) ...[
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.primary,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.04),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: const BoxDecoration(
                                          color: AppColors.lightGreen50,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.account_balance_wallet_rounded,
                                          color: AppColors.primary,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Coach E-Money',
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Terhubung',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.green.shade700,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(
                                        Icons.check_circle_rounded,
                                        color: AppColors.primary,
                                        size: 24,
                                      ),
                                    ],
                                  ),
                                ),
                              ] else ...[
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.orange.shade200,
                                      width: 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.02),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.orange.shade50,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.warning_amber_rounded,
                                              color: Colors.orange.shade700,
                                              size: 24,
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'Belum Ada Metode Pembayaran',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.textPrimary,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  'Hubungkan Coach E-Money untuk melanjutkan pembayaran.',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      ElevatedButton.icon(
                                        onPressed: _connectWallet,
                                        icon: const Icon(Icons.link_rounded, size: 18),
                                        label: const Text('Hubungkan Coach E-Money'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          minimumSize: const Size(double.infinity, 44),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                // Total & Action Button
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(
                        color: AppColors.border,
                        width: 1,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        offset: const Offset(0, -2),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Pembayaran:',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            'Rp ${totalPrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _isProcessing
                            ? null
                            : (_isWalletConnected ? _processCheckout : _connectWallet),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isWalletConnected ? AppColors.primary : Colors.grey.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isProcessing
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _isWalletConnected ? 'Konfirmasi & Bayar' : 'Hubungkan Coach E-Money',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                      if (widget.pendingTransaction == null) ...[
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: _isProcessing ? null : _cancelAndGoBack,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            foregroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Batalkan Pembayaran',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

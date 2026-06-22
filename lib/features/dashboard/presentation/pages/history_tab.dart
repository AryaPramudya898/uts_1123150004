import 'package:flutter/material.dart';
import 'package:uts_1123150004/core/constants/app_colors.dart';
import 'package:uts_1123150004/core/services/dio_client.dart';
import 'package:uts_1123150004/features/cart/presentation/pages/checkout_page.dart';

class HistoryTab extends StatefulWidget {
  const HistoryTab({super.key});

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  late Future<List<dynamic>> _transactionsFuture;

  @override
  void initState() {
    super.initState();
    _refreshTransactions();
  }

  void _refreshTransactions() {
    setState(() {
      _transactionsFuture = _getTransactions();
    });
  }

  Future<List<dynamic>> _getTransactions() async {
    try {
      final response = await DioClient.instance.get('/transactions');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'];
        if (data is List) {
          return data;
        }
      }
      return [];
    } catch (e) {
      debugPrint('[HistoryTab] Error fetching transactions: $e');
      throw Exception('Gagal mengambil data transaksi');
    }
  }

  String formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      return '${dt.day} ${_monthName(dt.month)} ${dt.year}, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }

  String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return months[month - 1];
  }

  void _showInvoice(BuildContext context, Map<String, dynamic> tx) {
    showDialog(
      context: context,
      builder: (context) {
        final reference = tx['reference'] ?? '';
        final amount = (tx['amount'] as num? ?? 0).toDouble();
        final description = tx['description'] ?? '';
        final transactionId = tx['transaction_id'] ?? '';
        final date = tx['CreatedAt'] != null ? formatDate(tx['CreatedAt']) : '';

        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'INVOICE PEMBAYARAN',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Lunas',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  _buildInvoiceRow('No. Referensi', reference),
                  if (transactionId.toString().isNotEmpty)
                    _buildInvoiceRow('ID Transaksi', transactionId.toString()),
                  _buildInvoiceRow('Tanggal', date),
                  _buildInvoiceRow('Metode Pembayaran', 'Coach E-Money'),
                  const SizedBox(height: 16),
                  const Text(
                    'Detail Belanja',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Bayar',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Rp ${amount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Tutup',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInvoiceRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => _refreshTransactions(),
      child: FutureBuilder<List<dynamic>>(
        future: _transactionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    snapshot.error.toString().replaceAll('Exception: ', ''),
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshTransactions,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    child: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          }

          final orders = snapshot.data ?? [];
          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.receipt_long_outlined, color: Colors.grey.shade400, size: 64),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Belum Ada Transaksi',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Riwayat pesanan Anda akan muncul di sini.',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index] as Map<String, dynamic>;
              final isSuccess = order['status'] == 'success';
              final reference = order['reference'] ?? '';
              final amount = (order['amount'] as num? ?? 0).toDouble();
              final description = order['description'] ?? '';
              final date = order['CreatedAt'] != null ? formatDate(order['CreatedAt']) : '';

              return Card(
                margin: const EdgeInsets.only(bottom: 14),
                elevation: 1,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade100, width: 1.5),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    if (isSuccess) {
                      _showInvoice(context, order);
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CheckoutPage(pendingTransaction: order),
                        ),
                      ).then((_) => _refreshTransactions());
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              date,
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isSuccess ? Colors.green.shade50 : Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                isSuccess ? 'Sukses' : 'Belum Dibayar',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isSuccess ? Colors.green : Colors.orange.shade800,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: isSuccess ? Colors.green.shade50 : Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Icon(
                                  isSuccess ? Icons.check_circle_outline_rounded : Icons.payment_rounded,
                                  color: isSuccess ? Colors.green : Colors.orange,
                                  size: 26,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    description,
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Ref: $reference',
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Belanja',
                                  style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Rp ${amount.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            OutlinedButton(
                              onPressed: () {
                                if (isSuccess) {
                                  _showInvoice(context, order);
                                } else {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CheckoutPage(pendingTransaction: order),
                                    ),
                                  ).then((_) => _refreshTransactions());
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: isSuccess ? AppColors.primary : Colors.orange),
                                foregroundColor: isSuccess ? AppColors.primary : Colors.orange,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              ),
                              child: Text(
                                isSuccess ? 'Lihat Invoice' : 'Bayar Sekarang',
                                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

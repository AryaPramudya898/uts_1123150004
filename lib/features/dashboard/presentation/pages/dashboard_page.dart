import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uts_1123150004/core/routes/app_router.dart';
import 'package:uts_1123150004/core/constants/app_colors.dart';
import 'package:uts_1123150004/features/auth/presentation/providers/auth_provider.dart';
import 'package:uts_1123150004/features/cart/presentation/pages/cart_page.dart';
import 'package:uts_1123150004/features/cart/presentation/providers/cart_provider.dart';
import 'package:uts_1123150004/features/dashboard/presentation/providers/product_provider.dart';

// Import Tabs
import 'home_tab.dart';
import 'history_tab.dart';
import 'profile_tab.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().fetchProducts();
      context.read<CartProvider>().fetchCart();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final userName = auth.firebaseUser?.displayName ?? 'User';
    final userEmail = auth.firebaseUser?.email ?? '';

    // Daftar tabs/halaman
    final List<Widget> tabs = [
      const HomeTab(),
      const HistoryTab(),
      ProfileTab(name: userName, email: userEmail),
    ];

    // Judul AppBar dinamis sesuai tab aktif
    final List<Widget> appBarTitles = [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Dashboard', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(
            'Halo, $userName!',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
      const Text('Riwayat Transaksi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const Text('Profil Pengguna', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF9FBF9),
      appBar: AppBar(
        title: appBarTitles[_currentIndex],
        elevation: 2,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        actions: _currentIndex == 0
            ? [
                IconButton(
                  icon: const Icon(Icons.shopping_cart),
                  tooltip: 'Keranjang',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CartPage()),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () async {
                    await auth.logout();
                    if (!mounted) return;
                    Navigator.pushReplacementNamed(context, AppRouter.login);
                  },
                ),
              ]
            : null,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: tabs,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: Colors.grey.shade400,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_rounded),
              activeIcon: Icon(Icons.history_toggle_off_rounded),
              label: 'Riwayat',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}

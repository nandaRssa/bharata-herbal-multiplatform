import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/product_provider.dart';
import '../services/store_info_service.dart';
import '../widgets/category_chip.dart';
import '../widgets/product_card.dart';
import 'product_detail_screen.dart';
import 'catalog_screen.dart';
import '../widgets/store_footer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  StoreInfo? _storeInfo;

  @override
  void initState() {
    super.initState();
    _loadStoreInfo();
  }

  Future<void> _loadStoreInfo() async {
    final info = await StoreInfoService().getStoreInfo();
    if (mounted && info != null) setState(() => _storeInfo = info);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProductProvider>(context);
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final slogan = _storeInfo?.description.isNotEmpty == true
        ? _storeInfo!.description
        : 'Produk herbal dari\nalam nusantara';

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(overscroll: false),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. HERO SECTION (Header Hijau) ---
              Container(
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 40),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1A5C38), Color(0xFF16A34A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.all(Radius.circular(6)),
                            child: Image.asset(
                              'assets/images/logo.png',
                              width: 28,
                              height: 28,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            '100% alami dan terpercaya',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Halo, Sobat Sehat',
                      style: TextStyle(color: Colors.white70, fontSize: 18),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      slogan,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _storeInfo?.name.isNotEmpty == true
                          ? 'Eksplorasi katalog ${_storeInfo!.name}, bandingkan manfaat,\ndan temukan produk yang paling cocok\nuntuk kebutuhan Anda.'
                          : 'Eksplorasi katalog, bandingkan manfaat,\ndan temukan produk yang paling cocok\nuntuk kebutuhan Anda.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CatalogScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF1A5C38),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.storefront_rounded),
                      label: const Text(
                        'Jelajahi Katalog',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // --- 2. STATS CARDS ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: _buildStatCard('10+', 'Produk Herbal')),
                    const SizedBox(width: 8),
                    Expanded(child: _buildStatCard('6.000+', 'Pelanggan Puas')),
                    const SizedBox(width: 8),
                    Expanded(child: _buildStatCard('4.8', 'Rating Rata-rata')),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // --- 3. KATEGORI PILIHAN ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kategori Pilihan',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F3D25),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Cari produk sesuai kebutuhan Anda.',
                          style: TextStyle(fontSize: 13, color: Colors.black54),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CatalogScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Lihat semua',
                        style: TextStyle(
                          color: Color(0xFF1A5C38),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 40,
                child: ListView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  scrollDirection: Axis.horizontal,
                  children: [
                    CategoryChip(
                      label: 'Semua',
                      selected: provider.selectedCategory.isEmpty,
                      onTap: () => provider.filterProducts(category: ''),
                    ),
                    ...provider.categories.map((category) {
                      return CategoryChip(
                        label: category.name,
                        selected: provider.selectedCategory == category.slug,
                        onTap: () =>
                            provider.filterProducts(category: category.slug),
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // --- 4. PRODUK UNGGULAN ---
              _buildProductSection(
                context: context,
                title: 'Produk Unggulan',
                subtitle: 'Pilihan herbal premium terbaik untuk Anda.',
                products: provider.products,
                formatter: currencyFormatter,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CatalogScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 30),

              // --- 5. PRODUK TERBARU ---
              _buildProductSection(
                context: context,
                title: 'Produk Terbaru',
                subtitle: 'Koleksi herbal terbaru di Bharata Herbal.',
                products: provider.products.reversed.toList(),
                formatter: currencyFormatter,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CatalogScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 30),

              // --- 6. PRODUK TERLARIS ---
              _buildProductSection(
                context: context,
                title: 'Produk Terlaris',
                subtitle: 'Herbal yang paling banyak diminati pelanggan.',
                products: provider.products,
                formatter: currencyFormatter,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CatalogScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 30),

              // --- 7. FOOTER TOKO ---
              const StoreFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductSection({
    required BuildContext context,
    required String title,
    required String subtitle,
    required List products,
    required NumberFormat formatter,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F3D25),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onTap,
                child: const Text(
                  'Semua',
                  style: TextStyle(
                    color: Color(0xFF1A5C38),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 280,
          child: products.isEmpty
              ? const Center(child: Text('Belum ada produk'))
              : ListView.separated(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  scrollDirection: Axis.horizontal,
                  itemCount: products.length > 5 ? 5 : products.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    final product = products[index];

                    final formattedPrice = formatter.format(
                      int.parse(product.price.toString()),
                    );

                    return SizedBox(
                      width: 160,
                      child: ProductCard(
                        name: product.name,
                        price: formattedPrice,
                        imageUrl: product.imageUrl,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ProductDetailScreen(product: product),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String value, String label) {
    return Container(
      width: 105,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1A5C38),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

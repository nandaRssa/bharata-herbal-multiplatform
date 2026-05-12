import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/product_provider.dart';
import '../widgets/product_card.dart';
import 'product_detail_screen.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProductProvider>(context);
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER ---
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Katalog Produk',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F3D25),
                        ),
                      ),
                      IconButton(
                        onPressed: () => provider.loadInitialData(),
                        icon: const Icon(
                          Icons.refresh_rounded,
                          color: Color(0xFF16A34A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Cari produk herbal, filter per kategori, dan urutkan sesuai preferensi.',
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            // --- SEARCH & FILTER ICON ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) =>
                            provider.filterProducts(keyword: val),
                        decoration: const InputDecoration(
                          hintText: 'Cari produk herbal...',
                          prefixIcon: Icon(Icons.search),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 15),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      color: Color(0xFF1A5C38),
                    ),
                  ),
                ],
              ),
            ),

            // --- CATEGORY CHIPS ---
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: provider.categories.length + 1,
                itemBuilder: (context, index) {
                  final isAll = index == 0;
                  final catName = isAll
                      ? 'Semua kategori'
                      : provider.categories[index - 1].name;
                  final catSlug = isAll
                      ? ''
                      : provider.categories[index - 1].slug;
                  final isSelected = provider.selectedCategory == catSlug;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(catName),
                      selected: isSelected,
                      onSelected: (val) =>
                          provider.filterProducts(category: catSlug),
                      backgroundColor: Colors.white,
                      selectedColor: const Color(0xFFE8F5E9),
                      side: BorderSide(
                        color: isSelected
                            ? const Color(0xFF1A5C38)
                            : Colors.black12,
                      ),
                      labelStyle: TextStyle(
                        color: isSelected
                            ? const Color(0xFF1A5C38)
                            : Colors.black87,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  );
                },
              ),
            ),

            // --- GRID PRODUK ---
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : provider.products.isEmpty
                  ? _buildErrorState(provider)
                  : GridView.builder(
                      padding: const EdgeInsets.all(20),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 0.58,
                          ),
                      itemCount: provider.products.length,
                      itemBuilder: (context, index) {
                        final p = provider.products[index];
                        return ProductCard(
                          name: p.name,
                          price: currencyFormatter.format(
                            int.parse(p.price.toString()),
                          ),
                          imageUrl: p.imageUrl,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (c) => ProductDetailScreen(product: p),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ProductProvider p) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 80,
            color: Color(0xFF1A5C38),
          ),
          const SizedBox(height: 16),
          const Text(
            'Terjadi kendala koneksi',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40, vertical: 8),
            child: Text(
              'Pastikan server Laravel menyala dan IP 192.168.0.104 bisa diakses.',
              textAlign: TextAlign.center,
            ),
          ),
          ElevatedButton(
            onPressed: () => p.loadInitialData(),
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }
}

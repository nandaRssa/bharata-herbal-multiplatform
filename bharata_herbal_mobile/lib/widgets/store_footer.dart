import 'package:flutter/material.dart';
import '../services/store_info_service.dart';

/// Footer dinamis yang membaca data dari Pengaturan Toko
class StoreFooter extends StatefulWidget {
  const StoreFooter({super.key});

  @override
  State<StoreFooter> createState() => _StoreFooterState();
}

class _StoreFooterState extends State<StoreFooter> {
  StoreInfo? _info;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final info = await StoreInfoService().getStoreInfo();
    if (mounted && info != null) setState(() => _info = info);
  }

  @override
  Widget build(BuildContext context) {
    if (_info == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F3D25), Color(0xFF1A5C38)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Store name
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 22,
                    height: 22,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _info!.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),

          if (_info!.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              _info!.description,
              style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
            ),
          ],

          const SizedBox(height: 20),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.15)),
          const SizedBox(height: 20),

          // Contact info
          const Text(
            'Hubungi Kami',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),

          if (_info!.address.isNotEmpty)
            _contactRow(Icons.location_on_outlined, _info!.address),
          if (_info!.whatsapp.isNotEmpty)
            _contactRow(Icons.phone_outlined, _info!.whatsapp),
          if (_info!.email.isNotEmpty)
            _contactRow(Icons.email_outlined, _info!.email),
          if (_info!.instagram.isNotEmpty)
            _contactRow(Icons.camera_alt_outlined, '@${_info!.instagram.replaceAll('@', '')}'),

          const SizedBox(height: 20),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.15)),
          const SizedBox(height: 16),

          Center(
            child: Text(
              '© ${DateTime.now().year} ${_info!.name}. All rights reserved.',
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white60, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/services/service_locator.dart';

/// Debug-only overlay. Never shown in release builds.
class PerformanceOverlayWidget extends StatelessWidget {
  const PerformanceOverlayWidget({super.key});

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();

    final perfManager = ServiceLocator.instance.performanceManager;

    return Positioned(
      top: 48,
      right: 8,
      child: ListenableBuilder(
        listenable: perfManager,
        builder: (context, _) {
          final config = perfManager.config;
          return Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _row('Mode', config.mode.name.toUpperCase()),
                _row('Glow', config.glowEnabled ? 'ON' : 'OFF'),
                _row('Shadows', config.shadowsEnabled ? 'ON' : 'OFF'),
                _row('Particles (mega)', '${config.particles.maxMegaBlastParticles}'),
                _row('Particles (large)', '${config.particles.maxLargeBlastParticles}'),
                _row('Particles (small)', '${config.particles.maxSmallBlastParticles}'),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        '$label: $value',
        style: const TextStyle(color: Colors.greenAccent, fontSize: 10, fontFamily: 'monospace'),
      ),
    );
  }
}

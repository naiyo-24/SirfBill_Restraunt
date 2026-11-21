import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/zoom_provider.dart';

/// Floating interactive resizer tool for Mobile, Tablet, and Desktop.
/// Allows instant zoom in/out, reset, and auto-fit screen width.
class AppScreenResizer extends ConsumerStatefulWidget {
  final double screenWidth;
  const AppScreenResizer({super.key, required this.screenWidth});

  @override
  ConsumerState<AppScreenResizer> createState() => _AppScreenResizerState();
}

class _AppScreenResizerState extends ConsumerState<AppScreenResizer> {
  bool _isExpanded = false;
  Timer? _autoCollapseTimer;

  @override
  void dispose() {
    _autoCollapseTimer?.cancel();
    super.dispose();
  }

  void _resetCollapseTimer() {
    _autoCollapseTimer?.cancel();
    _autoCollapseTimer = Timer(const Duration(seconds: 8), () {
      if (mounted && _isExpanded) {
        setState(() => _isExpanded = false);
      }
    });
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    if (_isExpanded) {
      _resetCollapseTimer();
    } else {
      _autoCollapseTimer?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final zoom = ref.watch(zoomProvider);
    final percentage = (zoom * 100).round();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isDark
        ? const Color(0xFF0F172A).withValues(alpha: 0.94)
        : const Color(0xFF1E293B).withValues(alpha: 0.95);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFF475569);

    if (!_isExpanded) {
      // Collapsed Pill Button
      return Material(
        color: Colors.transparent,
        elevation: 6,
        shadowColor: Colors.black45,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: _toggleExpanded,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: borderColor, width: 1.2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.aspect_ratio_rounded,
                  color: Color(0xFF10B981),
                  size: 15,
                ),
                const SizedBox(width: 5),
                Text(
                  '$percentage%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(width: 3),
                const Icon(
                  Icons.unfold_more_rounded,
                  color: Colors.white70,
                  size: 13,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Expanded Resizer Toolbar
    return Material(
      color: Colors.transparent,
      elevation: 10,
      shadowColor: Colors.black54,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Top Control Bar
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Zoom Out
                _buildToolButton(
                  icon: Icons.remove_rounded,
                  tooltip: 'Zoom Out (-5%)',
                  onPressed: () {
                    ref.read(zoomProvider.notifier).zoomOut();
                    _resetCollapseTimer();
                  },
                ),
                const SizedBox(width: 4),

                // Fit to Screen button
                InkWell(
                  onTap: () {
                    ref.read(zoomProvider.notifier).fitWidth(widget.screenWidth);
                    _resetCollapseTimer();
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF10B981), width: 1),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.fit_screen_rounded, size: 13, color: Color(0xFF34D399)),
                        SizedBox(width: 4),
                        Text(
                          'Fit Screen',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF34D399),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 4),

                // Reset 100% Pill
                InkWell(
                  onTap: () {
                    ref.read(zoomProvider.notifier).resetZoom();
                    _resetCollapseTimer();
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$percentage%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),

                // Zoom In
                _buildToolButton(
                  icon: Icons.add_rounded,
                  tooltip: 'Zoom In (+5%)',
                  onPressed: () {
                    ref.read(zoomProvider.notifier).zoomIn();
                    _resetCollapseTimer();
                  },
                ),
                const SizedBox(width: 6),

                // Minimize
                InkWell(
                  onTap: _toggleExpanded,
                  borderRadius: BorderRadius.circular(6),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.close_rounded, size: 16, color: Colors.white70),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Quick Preset Scale Chips
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildPresetChip('75%', 0.75),
                const SizedBox(width: 4),
                _buildPresetChip('85%', 0.85),
                const SizedBox(width: 4),
                _buildPresetChip('100%', 1.0),
                const SizedBox(width: 4),
                _buildPresetChip('115%', 1.15),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Colors.white12,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }

  Widget _buildPresetChip(String label, double targetZoom) {
    final currentZoom = ref.watch(zoomProvider);
    final isSelected = (currentZoom - targetZoom).abs() < 0.02;

    return InkWell(
      onTap: () {
        ref.read(zoomProvider.notifier).setZoom(targetZoom);
        _resetCollapseTimer();
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF10B981) : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : Colors.white70,
          ),
        ),
      ),
    );
  }
}

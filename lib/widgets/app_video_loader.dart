import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../themes/app_colors.dart';

/// Cross-platform video loader that plays `assets/Loader.mp4` on loop.
/// Fully responsive and adaptive for Windows (.exe), Web, and Mobile (Android / iOS).
class AppVideoLoader extends StatefulWidget {
  final double? size;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final BoxFit fit;

  const AppVideoLoader({
    super.key,
    this.size,
    this.width,
    this.height,
    this.borderRadius,
    this.fit = BoxFit.contain,
  });

  @override
  State<AppVideoLoader> createState() => _AppVideoLoaderState();
}

class _AppVideoLoaderState extends State<AppVideoLoader> {
  late VideoPlayerController _controller;
  bool _isInit = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      _controller = VideoPlayerController.asset('assets/Loader.mp4');
      await _controller.initialize();
      if (!mounted) return;

      // Volume must be 0 for Web browser auto-play policies
      await _controller.setVolume(0.0);
      await _controller.setLooping(true);
      await _controller.play();

      if (mounted) {
        setState(() => _isInit = true);
      }
    } catch (e) {
      debugPrint('[AppVideoLoader] Error initializing Loader.mp4: $e');
      if (mounted) {
        setState(() => _hasError = true);
      }
    }
  }

  @override
  void dispose() {
    if (_isInit) {
      _controller.pause();
    }
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.width ?? widget.size;
    final h = widget.height ?? widget.size;

    Widget content;
    if (_isInit && !_hasError) {
      final videoSize = _controller.value.size;
      final aspect = _controller.value.aspectRatio > 0
          ? _controller.value.aspectRatio
          : 1.0;

      content = FittedBox(
        fit: widget.fit,
        child: SizedBox(
          width: videoSize.width > 0 ? videoSize.width : 512,
          height: videoSize.height > 0 ? videoSize.height : 512,
          child: AspectRatio(
            aspectRatio: aspect,
            child: VideoPlayer(_controller),
          ),
        ),
      );
    } else {
      content = const Center(
        child: SizedBox(
          width: 36,
          height: 36,
          child: CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 3,
            strokeCap: StrokeCap.round,
          ),
        ),
      );
    }

    Widget result = widget.borderRadius != null
        ? ClipRRect(
            borderRadius: widget.borderRadius!,
            child: content,
          )
        : content;

    if (w != null || h != null) {
      result = SizedBox(
        width: w,
        height: h,
        child: result,
      );
    }

    return result;
  }
}

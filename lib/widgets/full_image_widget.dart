import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Full-screen photo viewer: pinch or double-tap to zoom, tap to show/hide
/// the top bar.
///
/// [heroTag] must match the tag on the thumbnail that opened it for the
/// photo to fly in; it defaults to the one chat bubbles use.
class FullImageWidget extends StatefulWidget {
  final String imageUrl;
  final String? heroTag;
  final String? title;

  const FullImageWidget({super.key, required this.imageUrl, this.heroTag, this.title});

  @override
  State<FullImageWidget> createState() => _FullImageWidgetState();
}

class _FullImageWidgetState extends State<FullImageWidget> with SingleTickerProviderStateMixin {
  final _transform = TransformationController();
  late final AnimationController _zoomAnimation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  )..addListener(() => _transform.value = _zoomTween!.evaluate(_zoomAnimation));
  Matrix4Tween? _zoomTween;
  TapDownDetails? _doubleTapDetails;
  bool _showChrome = true;

  @override
  void dispose() {
    _zoomAnimation.dispose();
    _transform.dispose();
    super.dispose();
  }

  void _toggleZoom() {
    final zoomedIn = _transform.value.getMaxScaleOnAxis() > 1.01;
    final Matrix4 target;
    if (zoomedIn) {
      target = Matrix4.identity();
    } else {
      // Zoom 2.5× into the point that was double-tapped.
      final p = _doubleTapDetails?.localPosition ?? Offset.zero;
      const scale = 2.5;
      target = Matrix4.identity()
        ..translateByDouble(-p.dx * (scale - 1), -p.dy * (scale - 1), 0, 1)
        ..scaleByDouble(scale, scale, 1, 1);
    }
    _zoomTween = Matrix4Tween(begin: _transform.value, end: target);
    _zoomAnimation.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final tag = widget.heroTag ?? 'imageHero_${widget.imageUrl}';

    Widget message(IconData icon, String text) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white54, size: 48),
            const SizedBox(height: 12),
            Text(text, style: const TextStyle(color: Colors.white70, fontSize: 15)),
          ],
        );

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AnimatedOpacity(
          opacity: _showChrome ? 1 : 0,
          duration: const Duration(milliseconds: 180),
          child: IgnorePointer(
            ignoring: !_showChrome,
            child: AppBar(
              backgroundColor: Colors.black38,
              foregroundColor: Colors.white,
              title: widget.title == null
                  ? null
                  : Text(widget.title!, maxLines: 1, overflow: TextOverflow.ellipsis),
              leading: IconButton(
                tooltip: 'Close',
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
          ),
        ),
      ),
      body: GestureDetector(
        onTap: () => setState(() => _showChrome = !_showChrome),
        onDoubleTapDown: (d) => _doubleTapDetails = d,
        onDoubleTap: _toggleZoom,
        child: InteractiveViewer(
          transformationController: _transform,
          minScale: 1,
          maxScale: 5,
          child: SizedBox.expand(
            child: Hero(
              tag: tag,
              child: widget.imageUrl.isEmpty
                  ? Center(child: message(Icons.image_not_supported_outlined, 'No photo'))
                  : CachedNetworkImage(
                      imageUrl: widget.imageUrl,
                      fit: BoxFit.contain,
                      placeholder: (_, __) => const Center(
                        child: SizedBox.square(
                          dimension: 32,
                          child: CircularProgressIndicator(color: Colors.white70, strokeWidth: 2.5),
                        ),
                      ),
                      errorWidget: (_, __, ___) =>
                          Center(child: message(Icons.broken_image_outlined, 'Couldn\'t load this photo')),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

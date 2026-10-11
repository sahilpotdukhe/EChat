import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shadcn_kit/shadcn_kit.dart';
import 'package:video_player/video_player.dart';

/// Full-screen video player: tap to show/hide the controls (they hide by
/// themselves while playing), a play/pause button, and a seek bar with the
/// current time and length. Shows a Retry message if the video can't load.
class CachedVideoPlayerScreen extends StatefulWidget {
  final String videoUrl;

  const CachedVideoPlayerScreen({super.key, required this.videoUrl});

  @override
  State<CachedVideoPlayerScreen> createState() => _CachedVideoPlayerScreenState();
}

class _CachedVideoPlayerScreenState extends State<CachedVideoPlayerScreen> {
  VideoPlayerController? _controller;
  bool _failed = false;
  bool _showControls = true;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    _controller?.dispose();
    final uri = Uri.tryParse(widget.videoUrl);
    setState(() {
      _failed = false;
      _controller = null;
    });
    if (uri == null || widget.videoUrl.isEmpty) {
      setState(() => _failed = true);
      return;
    }
    final controller = VideoPlayerController.networkUrl(uri);
    try {
      await controller.initialize();
    } catch (e) {
      debugPrint('Video failed to load: $e');
      await controller.dispose();
      if (mounted) setState(() => _failed = true);
      return;
    }
    if (!mounted) {
      await controller.dispose();
      return;
    }
    controller.addListener(_onTick);
    setState(() => _controller = controller);
    await controller.play();
    _scheduleHide();
  }

  // Rebuild for play/pause and the end of the video, not every frame: the
  // progress bar listens to the controller itself.
  bool _wasPlaying = false;
  void _onTick() {
    final value = _controller!.value;
    if (value.hasError && !_failed) setState(() => _failed = true);
    if (value.isPlaying != _wasPlaying) {
      _wasPlaying = value.isPlaying;
      if (!value.isPlaying) _hideTimer?.cancel();
      setState(() {
        if (!value.isPlaying) _showControls = true;
      });
    }
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && (_controller?.value.isPlaying ?? false)) setState(() => _showControls = false);
    });
  }

  void _togglePlay() {
    final c = _controller;
    if (c == null) return;
    if (c.value.isPlaying) {
      c.pause();
    } else {
      // At the end: start again from the beginning.
      if (c.value.position >= c.value.duration) c.seekTo(Duration.zero);
      c.play();
      _scheduleHide();
    }
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) _scheduleHide();
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    final Widget body;
    if (_failed) {
      body = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videocam_off_outlined, color: Colors.white54, size: 48),
            const SizedBox(height: 12),
            const Text('Couldn\'t play this video', style: TextStyle(color: Colors.white70, fontSize: 15)),
            const SizedBox(height: 16),
            ShadcnButton(
              variant: ShadcnButtonVariant.secondary,
              leading: const Icon(Icons.refresh_rounded),
              onPressed: _load,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    } else if (c == null) {
      body = const Center(
        child: SizedBox.square(
          dimension: 32,
          child: CircularProgressIndicator(color: Colors.white70, strokeWidth: 2.5),
        ),
      );
    } else {
      body = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _toggleControls,
        child: Stack(
          children: [
            Center(child: AspectRatio(aspectRatio: c.value.aspectRatio, child: VideoPlayer(c))),
            IgnorePointer(
              ignoring: !_showControls,
              child: AnimatedOpacity(
                opacity: _showControls ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: Stack(
                  children: [
                    Center(
                      child: Material(
                        color: Colors.black45,
                        shape: const CircleBorder(),
                        child: IconButton(
                          iconSize: 44,
                          padding: const EdgeInsets.all(14),
                          tooltip: c.value.isPlaying ? 'Pause' : 'Play',
                          color: Colors.white,
                          icon: Icon(c.value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                          onPressed: _togglePlay,
                        ),
                      ),
                    ),
                    Positioned(left: 0, right: 0, bottom: 0, child: _ProgressBar(controller: c)),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        leading: IconButton(
          tooltip: 'Close',
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: body,
    );
  }
}

/// Elapsed time, a draggable seek bar and the total length.
class _ProgressBar extends StatelessWidget {
  final VideoPlayerController controller;

  const _ProgressBar({required this.controller});

  static String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return d.inHours > 0 ? '${d.inHours}:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final primary = context.shadcn.primary;
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black54, Colors.transparent],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: ValueListenableBuilder<VideoPlayerValue>(
            valueListenable: controller,
            builder: (context, value, _) => Row(
              children: [
                Text(_format(value.position), style: const TextStyle(color: Colors.white, fontSize: 12)),
                const SizedBox(width: 12),
                Expanded(
                  child: VideoProgressIndicator(
                    controller,
                    allowScrubbing: true,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    colors: VideoProgressColors(
                      playedColor: primary,
                      bufferedColor: Colors.white38,
                      backgroundColor: Colors.white24,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(_format(value.duration), style: const TextStyle(color: Colors.white, fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

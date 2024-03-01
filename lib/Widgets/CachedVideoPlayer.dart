import 'package:cached_video_player/cached_video_player.dart';
import 'package:flutter/material.dart';

class CachedVideoPlayerScreen extends StatefulWidget {
  final String videoUrl;

  CachedVideoPlayerScreen({required this.videoUrl});

  @override
  _CachedVideoPlayerScreenState createState() =>
      _CachedVideoPlayerScreenState();
}

class _CachedVideoPlayerScreenState extends State<CachedVideoPlayerScreen> {
  late CachedVideoPlayerController _controller;

  @override
  void initState() {
    _controller = CachedVideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        _controller.play();
        setState(() {});
      });
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Video Player'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_controller.value.isInitialized)
              AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    CachedVideoPlayer(_controller),
                    Container(
                      child: VideoProgressIndicator(
                        _controller,
                        allowScrubbing: true,
                        colors: VideoProgressColors(
                          playedColor: Colors.blue,
                          bufferedColor: Colors.grey,
                        ),
                        padding: EdgeInsets.all(8.0),
                      ),
                    ),
                  ],
                ),
              )
            else
              CircularProgressIndicator(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            if (_controller.value.isPlaying) {
              _controller.pause();
            } else {
              _controller.play();
            }
          });
        },
        child: Icon(
          _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
        ),
      ),
    );
  }
}

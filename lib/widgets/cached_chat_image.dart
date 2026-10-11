import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class CachedChatImage extends StatelessWidget {
  final String imageUrl;
  final bool isRound;
  final double radius;
  final double height;
  final double width;
  final BoxFit fit;
  const CachedChatImage({super.key, required this.imageUrl, required this.isRound, required this.radius, required this.height, required this.width, required this.fit});

  @override
  Widget build(BuildContext context) {
    try{
      return  SizedBox(
        height: isRound ? radius : height,
        width: isRound ? radius : width,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(isRound ? 50 : radius),
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: fit,
            placeholder: (context,url){
              return Center(
                child: CircularProgressIndicator(),
              );
            },
            errorWidget: (context,url,error)=> _unavailable(),
          ),
        ),
      );
    }catch(e){
      return _unavailable();
    }

  }

  // Shown when the image can't load (offline, deleted, or no URL).
  Widget _unavailable() => Container(
        color: Colors.grey.shade800,
        alignment: Alignment.center,
        child: const Icon(Icons.broken_image_outlined, color: Colors.white54),
      );
}

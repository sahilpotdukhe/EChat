import 'package:echat/Utils/UniversalVariables.dart';
import 'package:flutter/material.dart';

class NewChatButton extends StatelessWidget {
  const NewChatButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          gradient: UniversalVariables.fabGradient,
          borderRadius: BorderRadius.circular(50)),
      padding: EdgeInsets.all(16),
      child: const Icon(
        Icons.chat,
        color: Colors.white,
        size: 26,
      ),
    );
  }
}

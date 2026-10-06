import 'package:flutter/material.dart';

/// Round button used for mic / camera / hang-up controls on the call screens.
class CallControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color color;

  const CallControlButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.color = Colors.white24,
  });

  @override
  Widget build(BuildContext context) {
    return RawMaterialButton(
      onPressed: onPressed,
      shape: const CircleBorder(),
      fillColor: onPressed == null ? Colors.white10 : color,
      padding: const EdgeInsets.all(14),
      elevation: 2,
      child: Icon(icon, color: Colors.white, size: 28),
    );
  }
}

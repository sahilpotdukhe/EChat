import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shadcn_kit/shadcn_kit.dart';

/// The bar at the bottom of a chat: an attach (+) button, a text box that
/// grows up to five lines, and a camera button that turns into a send button
/// as soon as there's something to send.
class ChatComposer extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onAttach;
  final VoidCallback onCamera;

  /// False until the signed-in user's profile has loaded; sending is
  /// blocked (typing still works) so nothing is lost.
  final bool canSend;

  const ChatComposer({
    super.key,
    required this.controller,
    required this.onSend,
    required this.onAttach,
    required this.onCamera,
    this.canSend = true,
  });

  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _hasText = widget.controller.text.trim().isNotEmpty;
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(covariant ChatComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTextChanged);
      widget.controller.addListener(_onTextChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  // Only rebuild when the send/camera choice actually flips, not per key.
  void _onTextChanged() {
    final hasText = widget.controller.text.trim().isNotEmpty;
    if (hasText != _hasText) setState(() => _hasText = hasText);
  }

  void _send() {
    if (!_hasText || !widget.canSend) return;
    HapticFeedback.lightImpact();
    widget.onSend();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.shadcn;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.background,
        border: Border(top: BorderSide(color: t.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 8, 8, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ShadcnButton(
                variant: ShadcnButtonVariant.ghost,
                size: ShadcnButtonSize.icon,
                tooltip: 'Attach',
                semanticLabel: 'Attach a photo, video or file',
                onPressed: widget.onAttach,
                child: Icon(Icons.add_circle_outline_rounded, size: 26, color: t.primary),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: ShadcnInput(
                  controller: widget.controller,
                  placeholder: 'Message',
                  minLines: 1,
                  maxLines: 5,
                  keyboardType: TextInputType.multiline,
                  textCapitalization: TextCapitalization.sentences,
                  style: ShadcnInputStyle(
                    backgroundColor: t.muted,
                    borderColor: t.muted,
                    borderRadius: BorderRadius.circular(22),
                    textStyle: TextStyle(color: t.foreground, fontSize: 15, height: 1.35),
                    hintStyle: TextStyle(color: t.mutedForeground, fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 160),
                transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                child: _hasText
                    ? ShadcnButton(
                        key: const ValueKey('send'),
                        size: ShadcnButtonSize.icon,
                        tooltip: 'Send',
                        semanticLabel: 'Send message',
                        style: const ShadcnButtonStyle(shape: CircleBorder()),
                        onPressed: widget.canSend ? _send : null,
                        child: const Icon(Icons.send_rounded, size: 20),
                      )
                    : ShadcnButton(
                        key: const ValueKey('camera'),
                        variant: ShadcnButtonVariant.ghost,
                        size: ShadcnButtonSize.icon,
                        tooltip: 'Camera',
                        semanticLabel: 'Take a photo',
                        onPressed: widget.onCamera,
                        child: Icon(Icons.photo_camera_outlined, size: 24, color: t.mutedForeground),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

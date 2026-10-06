import 'package:flutter/material.dart';
import '../../data/ai_models.dart';
import 'typing_indicator.dart';
import 'package:intl/intl.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final VoidCallback? onRetry;

  const MessageBubble({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (message.isStreaming) {
      return _AssistantBubble(
        child: const TypingIndicator(),
        time: null,
      );
    }

    if (message.isUser) {
      return _UserBubble(message: message);
    }

    return _AssistantMessageBubble(
      message: message,
      onRetry: onRetry,
    );
  }
}

// ---------------------------------------------------------------------------
// User bubble
// ---------------------------------------------------------------------------
class _UserBubble extends StatelessWidget {
  final MessageModel message;
  const _UserBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 64, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                constraints: const BoxConstraints(maxWidth: 280),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C896),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(4),
                  ),
                ),
                child: Text(
                  message.content,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                DateFormat('h:mm a').format(message.createdAt),
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFF00C896).withOpacity(0.2),
            child: const Icon(
              Icons.person_rounded,
              size: 18,
              color: Color(0xFF00C896),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Assistant bubble
// ---------------------------------------------------------------------------
class _AssistantMessageBubble extends StatelessWidget {
  final MessageModel message;
  final VoidCallback? onRetry;

  const _AssistantMessageBubble({
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return _AssistantBubble(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.errorMessage != null) ...[
            Row(
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: Color(0xFFFF5252), size: 14),
                const SizedBox(width: 4),
                const Text(
                  'Failed to get response',
                  style: TextStyle(
                      color: Color(0xFFFF5252), fontSize: 12),
                ),
              ],
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 6),
              GestureDetector(
                onTap: onRetry,
                child: const Text(
                  'Tap to retry',
                  style: TextStyle(
                    color: Color(0xFF00C896),
                    fontSize: 12,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ] else
            Text(
              message.content,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.5,
              ),
            ),
        ],
      ),
      time: DateFormat('h:mm a').format(message.createdAt),
    );
  }
}

class _AssistantBubble extends StatelessWidget {
  final Widget child;
  final String? time;

  const _AssistantBubble({required this.child, required this.time});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 64, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF00C896).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 18,
              color: Color(0xFF00C896),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                constraints: const BoxConstraints(maxWidth: 280),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1F36),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(18),
                  ),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.06)),
                ),
                child: child,
              ),
              if (time != null) ...[
                const SizedBox(height: 3),
                Text(
                  time!,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

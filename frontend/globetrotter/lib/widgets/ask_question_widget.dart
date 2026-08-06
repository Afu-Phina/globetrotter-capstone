import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/destinations_service.dart';

class _ChatMessage {
  final String text;
  final bool isUser;
  final bool aiGenerated;
  _ChatMessage(this.text, this.isUser, {this.aiGenerated = false});
}

/// Inline "ask a question about this place" widget. Answers come from the
/// backend's /ask endpoint, which calls Google's Gemini API with context
/// about the destination -- real natural-language answers, not keyword
/// matching. Falls back to a simpler templated answer server-side if the
/// AI call fails. The badge on each answer bubble shows which one actually
/// generated it, so this is visible rather than a guess.
class AskQuestionWidget extends StatefulWidget {
  final String destinationId;
  const AskQuestionWidget({super.key, required this.destinationId});

  @override
  State<AskQuestionWidget> createState() => _AskQuestionWidgetState();
}

class _AskQuestionWidgetState extends State<AskQuestionWidget> {
  final _controller = TextEditingController();
  final List<_ChatMessage> _messages = [];
  bool _sending = false;

  Future<void> _send() async {
    final question = _controller.text.trim();
    if (question.isEmpty) return;
    setState(() {
      _messages.add(_ChatMessage(question, true));
      _sending = true;
    });
    _controller.clear();
    try {
      final (answer, aiGenerated) = await destinationsService.ask(widget.destinationId, question);
      setState(() => _messages.add(_ChatMessage(answer, false, aiGenerated: aiGenerated)));
    } catch (e) {
      setState(() => _messages.add(_ChatMessage("Couldn't get an answer right now.", false)));
    } finally {
      setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.forum_outlined, size: 18, color: AppColors.forest),
            const SizedBox(width: AppSpacing.xs),
            Text('Ask a question about this place', style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (_messages.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 260),
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.mist,
              borderRadius: BorderRadius.circular(14),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _messages
                    .map((m) => Align(
                          alignment: m.isUser ? Alignment.centerRight : Alignment.centerLeft,
                          child: Column(
                            crossAxisAlignment:
                                m.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              if (!m.isUser)
                                Padding(
                                  padding: const EdgeInsets.only(left: 4, bottom: 2),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        m.aiGenerated ? Icons.auto_awesome : Icons.info_outline,
                                        size: 11,
                                        color: m.aiGenerated ? AppColors.marigold : AppColors.inkMuted,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        m.aiGenerated ? 'AI answer' : 'Quick answer',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: m.aiGenerated ? AppColors.marigold : AppColors.inkMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              Container(
                                constraints: BoxConstraints(
                                  maxWidth: MediaQuery.of(context).size.width * 0.65,
                                ),
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: m.isUser ? AppColors.forest : AppColors.surface,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(
                                  m.text,
                                  style: TextStyle(
                                    color: m.isUser ? AppColors.forestDeep : AppColors.ink,
                                    fontSize: 13,
                                    fontWeight: m.isUser ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: 'e.g. What are the opening hours?',
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            IconButton.filled(
              onPressed: _sending ? null : _send,
              style: IconButton.styleFrom(backgroundColor: AppColors.marigold),
              icon: _sending
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.forestDeep),
                    )
                  : const Icon(Icons.send, color: AppColors.forestDeep, size: 18),
            ),
          ],
        ),
      ],
    );
  }
}

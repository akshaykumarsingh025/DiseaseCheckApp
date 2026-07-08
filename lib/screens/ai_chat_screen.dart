import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/gemma_provider.dart';
import '../services/ai_api_service.dart';
import '../services/gemma_service.dart';
import '../models/report.dart';

class AiChatScreen extends ConsumerStatefulWidget {
  final HealthReport report;
  const AiChatScreen({super.key, required this.report});

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _messages.add(_ChatMessage(
      text: 'I have your health report loaded. Ask me anything about your results — what a value means, what to eat, what to avoid, or what to do next.',
      isUser: false,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isGenerating) return;

    _controller.clear();
    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _isGenerating = true;
    });
    _scrollToBottom();

    final reportContext = GemmaService.buildRawReportText(widget.report.toJson());
    final language = ref.read(gemmaProvider).language;

    String langInstruction;
    switch (language) {
      case 'hindi':
        langInstruction = 'हिन्दी (देवनागरी) में जवाब दें।';
        break;
      case 'hinglish':
        langInstruction = 'Hinglish mein jawab dein.';
        break;
      default:
        langInstruction = 'Answer in simple English.';
    }

    final prompt = '''You are a caring medical assistant. The patient is asking a follow-up question about their health report. $langInstruction

Their health report data:
$reportContext

Patient's question: $text

Give a helpful, simple answer. If the question is about something serious, remind them to consult their doctor. Keep it concise (3-5 sentences max).''';

    final result = await AiApiService.generateText(prompt, language: language);

    setState(() {
      _isGenerating = false;
      if (result.success && result.text != null) {
        _messages.add(_ChatMessage(text: result.text!, isUser: false));
      } else {
        _messages.add(_ChatMessage(
          text: 'Sorry, I could not process that. Please try again or consult your doctor.',
          isUser: false,
        ));
      }
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ask AI About Your Report'),
        actions: [
          IconButton(
            icon: const Icon(Icons.local_hospital),
            tooltip: 'Book Doctor',
            onPressed: () => context.push('/book-appointment'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildMessageBubble(msg, isDark);
              },
            ),
          ),
          if (_isGenerating)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 10),
                  Text('AI is thinking...', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          _buildQuickQuestions(),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    enabled: !_isGenerating,
                    decoration: InputDecoration(
                      hintText: 'Ask about your report...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.pink,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(_ChatMessage msg, bool isDark) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        decoration: BoxDecoration(
          color: msg.isUser
              ? Colors.pink.shade600
              : (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(msg.isUser ? 16 : 4),
            bottomRight: Radius.circular(msg.isUser ? 4 : 16),
          ),
        ),
        child: Text(
          msg.text,
          style: TextStyle(
            fontSize: 14,
            color: msg.isUser ? Colors.white : (isDark ? Colors.white : Colors.black87),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickQuestions() {
    final questions = [
      'Is my condition serious?',
      'What food should I avoid?',
      'Can I exercise?',
      'What should I tell my doctor?',
    ];

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: questions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          return ActionChip(
            label: Text(questions[index], style: const TextStyle(fontSize: 12)),
            onPressed: _isGenerating
                ? null
                : () {
                    _controller.text = questions[index];
                    _sendMessage();
                  },
          );
        },
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  _ChatMessage({required this.text, required this.isUser});
}

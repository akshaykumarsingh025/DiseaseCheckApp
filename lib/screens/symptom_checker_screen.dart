import 'package:flutter/material.dart';

import '../services/ai_api_service.dart';
import '../utils/doctor_info.dart';

/// A lightweight AI symptom checker focused on women's health. It gives
/// general guidance and always nudges the user to consult Dr. Deepika for
/// anything concerning — it is not a diagnosis.
class SymptomCheckerScreen extends StatefulWidget {
  const SymptomCheckerScreen({super.key});

  @override
  State<SymptomCheckerScreen> createState() => _SymptomCheckerScreenState();
}

class _SymptomCheckerScreenState extends State<SymptomCheckerScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final List<_Msg> _messages = [];
  bool _generating = false;

  static const List<String> _quick = [
    'Irregular periods',
    'Painful cramps',
    'PCOS symptoms',
    'White discharge',
    'Missed period',
    'Breast pain',
    'Low mood / PMS',
    'UTI symptoms',
  ];

  @override
  void initState() {
    super.initState();
    _messages.add(_Msg(
      text:
          'Hi! I\'m your women\'s-health assistant. Describe what you\'re feeling — for example your symptoms, when they started, and where — and I\'ll share general guidance.\n\nThis is not a diagnosis. For anything serious or persistent, please consult ${DoctorInfo.name}.',
      isUser: false,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _controller.text).trim();
    if (text.isEmpty || _generating) return;
    _controller.clear();
    setState(() {
      _messages.add(_Msg(text: text, isUser: true));
      _generating = true;
    });
    _scrollToBottom();

    final history = _messages
        .where((m) => m.isUser)
        .map((m) => m.text)
        .take(6)
        .join('; ');

    final prompt =
        '''You are a caring women's-health assistant for a gynaecology clinic. A patient describes symptoms. Give brief, practical, reassuring guidance in simple English.

Rules:
- Do NOT give a definitive diagnosis. Use phrases like "this could be related to...".
- Mention 1-3 possible common causes, simple self-care they can try, and clear red-flag signs that mean they should see a doctor soon.
- If symptoms sound urgent (heavy bleeding, severe pain, fever, fainting, pregnancy complications), tell them to seek care promptly.
- Always end by suggesting they consult ${DoctorInfo.name} for a proper check-up.
- Keep it under 8 short sentences. Use a friendly tone.

Patient's symptoms so far: $history

Latest message: $text''';

    final result = await AiApiService.generateText(prompt);

    if (!mounted) return;
    setState(() {
      _generating = false;
      _messages.add(_Msg(
        text: result.success && result.text != null
            ? result.text!
            : 'Sorry, I couldn\'t analyse that right now. Please check your connection or consult ${DoctorInfo.name} directly.',
        isUser: false,
      ));
    });
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Symptom Checker')),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: Colors.amber.shade50,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.amber.shade800),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'General guidance only — not a medical diagnosis.',
                      style:
                          TextStyle(fontSize: 12, color: Colors.amber.shade900),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length + (_generating ? 1 : 0),
                itemBuilder: (context, i) {
                  if (i == _messages.length) {
                    return const _TypingBubble();
                  }
                  return _bubble(_messages[i]);
                },
              ),
            ),
            if (_messages.length <= 1)
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: _quick
                      .map((q) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ActionChip(
                              label: Text(q,
                                  style: const TextStyle(fontSize: 12)),
                              onPressed: () => _send(q),
                            ),
                          ))
                      .toList(),
                ),
              ),
            _inputBar(),
          ],
        ),
      ),
    );
  }

  Widget _bubble(_Msg m) {
    return Align(
      alignment: m.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: m.isUser ? Colors.pink.shade400 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          m.text,
          style: TextStyle(
              color: m.isUser ? Colors.white : Colors.black87, fontSize: 14),
        ),
      ),
    );
  }

  Widget _inputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              textCapitalization: TextCapitalization.sentences,
              minLines: 1,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Describe your symptoms...',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onSubmitted: (_) => _send(),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: Colors.pink,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _generating ? null : () => _send(),
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Msg {
  final String text;
  final bool isUser;
  _Msg({required this.text, required this.isUser});
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const SizedBox(
          width: 40,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                  width: 8,
                  height: 8,
                  child: CircularProgressIndicator(strokeWidth: 2)),
              Text('...', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}

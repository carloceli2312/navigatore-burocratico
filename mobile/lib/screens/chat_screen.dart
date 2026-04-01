import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../providers/procedures_provider.dart';
import '../widgets/chat_bubble.dart';

// ── Palette Direction B ───────────────────────────────────────────────────────
const _cobalt = Color(0xFF1A47B8);
const _cobaltDark = Color(0xFF1538A0);
const _cobaltLight = Color(0xFFEEF2FF);
const _warmGrey = Color(0xFFF5F4F2);
const _textPrimary = Color(0xFF0F1A2E);
const _textSecondary = Color(0xFF64748B);
const _cardBorder = Color(0xFFE8EDF4);

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    _inputCtrl.clear();
    await context.read<ChatProvider>().sendMessage(text);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    final procs = context.read<ProceduresProvider>();

    String? procedureName;
    if (chat.procedureSlug != null) {
      try {
        procedureName =
            procs.procedures.firstWhere((p) => p.slug == chat.procedureSlug).name;
      } catch (_) {
        procedureName = chat.procedureSlug;
      }
    }

    return Scaffold(
      backgroundColor: _warmGrey,
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          _buildHeader(context, chat),
          if (procedureName != null) _buildContextBanner(chat, procedureName),
          Expanded(
            child: chat.messages.isEmpty
                ? _EmptyState(
                    hasProcedureContext: chat.procedureSlug != null,
                    procedureName: procedureName,
                  )
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemCount: chat.messages.length + (chat.isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == chat.messages.length) {
                        return const _TypingIndicator();
                      }
                      return ChatBubble(message: chat.messages[index]);
                    },
                  ),
          ),
          _buildInputBar(chat),
        ],
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, ChatProvider chat) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_cobalt, _cobaltDark],
        ),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 4,
        right: 16,
        bottom: 16,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 18),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 2),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(child: Text('🤖', style: TextStyle(fontSize: 18))),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Assistente AI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                Text(
                  'Provincia di Cosenza',
                  style: TextStyle(
                    color: Color(0xFFB3C3EF),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (chat.messages.isNotEmpty)
            IconButton(
              tooltip: 'Nuova conversazione',
              icon: Icon(Icons.delete_sweep_outlined,
                  color: Colors.white.withAlpha(180), size: 20),
              onPressed: () {
                chat.clearMessages();
                _inputCtrl.clear();
              },
            ),
        ],
      ),
    );
  }

  // ── Procedure context banner ─────────────────────────────────────────────────

  Widget _buildContextBanner(ChatProvider chat, String procedureName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: _cobaltLight,
        border: Border(bottom: BorderSide(color: _cardBorder, width: 1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.folder_outlined, size: 14, color: _cobalt),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Contesto: $procedureName',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _cobalt,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: () => chat.setProcedureContext(null),
            child: const Icon(Icons.close_rounded, size: 16, color: _cobalt),
          ),
        ],
      ),
    );
  }

  // ── Input bar ────────────────────────────────────────────────────────────────

  Widget _buildInputBar(ChatProvider chat) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _cardBorder, width: 1)),
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 12,
        top: 10,
        bottom: 10 + MediaQuery.of(context).padding.bottom,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _inputCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Fai una domanda...',
                hintStyle: const TextStyle(color: _textSecondary, fontSize: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(color: _cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(color: _cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(color: _cobalt, width: 1.5),
                ),
                filled: true,
                fillColor: _warmGrey,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onSubmitted: (_) => _sendMessage(),
              maxLines: 4,
              minLines: 1,
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: chat.isLoading ? null : _sendMessage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: chat.isLoading ? _cardBorder : _cobalt,
                borderRadius: BorderRadius.circular(21),
              ),
              child: chat.isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(11),
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: _cobalt),
                    )
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool hasProcedureContext;
  final String? procedureName;

  const _EmptyState({required this.hasProcedureContext, this.procedureName});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _cobaltLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(child: Text('🤖', style: TextStyle(fontSize: 36))),
            ),
            const SizedBox(height: 20),
            Text(
              hasProcedureContext
                  ? 'Sono qui per aiutarti con "${procedureName ?? ""}"'
                  : 'Il tuo assistente burocratico',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasProcedureContext
                  ? 'Chiedimi documenti necessari, uffici, costi o qualsiasi dubbio sulla procedura.'
                  : 'Chiedimi qualsiasi cosa riguardi le procedure burocratiche della Provincia di Cosenza.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: _textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            _SuggestedPrompt(
              text: hasProcedureContext
                  ? 'Quali documenti servono?'
                  : 'Come ottengo la carta d\'identità?',
            ),
            const SizedBox(height: 8),
            _SuggestedPrompt(
              text: hasProcedureContext
                  ? 'Quanto tempo ci vuole?'
                  : 'Dove si presenta la SCIA?',
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestedPrompt extends StatelessWidget {
  final String text;

  const _SuggestedPrompt({required this.text});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.read<ChatProvider>().sendMessage(text);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _cardBorder, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.arrow_forward_rounded, size: 13, color: _cobalt),
            const SizedBox(width: 6),
            Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: _cobalt,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Typing indicator ──────────────────────────────────────────────────────────

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(left: 16, top: 4, bottom: 4, right: 48),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
          ),
          border: Border.all(color: _cardBorder, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: _cobalt),
            ),
            const SizedBox(width: 10),
            Text(
              'Sto elaborando...',
              style: TextStyle(fontSize: 12, color: _textSecondary.withAlpha(180)),
            ),
          ],
        ),
      ),
    );
  }
}

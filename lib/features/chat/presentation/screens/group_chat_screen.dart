import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:topar_115/core/utils/haptic_utils.dart';
import 'package:topar_115/features/auth/presentation/controllers/auth_controller.dart';
import '../../data/models/chat_message_model.dart';
import '../../data/repositories/chat_repository.dart';

class GroupChatScreen extends ConsumerStatefulWidget {
  const GroupChatScreen({super.key});

  @override
  ConsumerState<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends ConsumerState<GroupChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _canSend = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _msgCtrl.addListener(() {
      final can = _msgCtrl.text.trim().isNotEmpty;
      if (can != _canSend) {
        setState(() => _canSend = can);
      }
    });
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool immediate = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      if (immediate) {
        _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
      } else {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  Future<void> _handleSend() async {
    if (_isSending) return;
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;

    final authState = ref.read(authProvider);
    final student = authState.currentStudent;

    final senderName = student?.name ?? 'Talyp';
    final role = authState.isStarshy ? 'starshy' : 'student';

    setState(() => _isSending = true);
    _msgCtrl.clear();
    HapticUtils.light();

    try {
      await ref.read(chatProvider.notifier).sendMessage(
            senderName: senderName,
            senderRole: role,
            message: text,
          );
      _scrollToBottom();
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatProvider);
    final authState = ref.watch(authProvider);
    final currentStudent = authState.currentStudent;
    final currentPhone = currentStudent?.phone ?? '';
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.primary,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Topar-115 Çat 💬',
              style: tt.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              '25 talyp • Umumy söhbetdeşlik',
              style: tt.bodySmall?.copyWith(
                color: Colors.white.withAlpha(200),
                fontSize: 11,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Hatlary täzele',
            onPressed: () {
              HapticUtils.light();
              ref.read(chatProvider.notifier).loadMessages();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Chat messages list
            Expanded(
              child: messages.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: cs.primaryContainer.withAlpha(60),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.chat_bubble_outline_rounded,
                                  size: 48, color: cs.primary),
                            ),
                            const Gap(16),
                            Text(
                              'Söhbetdeşlikde entek hat ýok.',
                              style: tt.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: cs.onSurface,
                              ),
                            ),
                            const Gap(6),
                            Text(
                              'Birinji bolup toparadaşlaryňyza salam ýazyň! 👋',
                              textAlign: TextAlign.center,
                              style: tt.bodyMedium?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final isMe = (currentStudent != null &&
                                msg.senderName.trim().toLowerCase() ==
                                    currentStudent.name.trim().toLowerCase()) ||
                            (currentPhone.isNotEmpty &&
                                msg.senderPhone.isNotEmpty &&
                                msg.senderPhone == currentPhone);

                        return _ChatMessageBubble(
                          message: msg,
                          isMe: isMe,
                        );
                      },
                    ),
            ),

            // Quick emoji bar
            _buildQuickEmojiBar(),

            // Message Composer input
            _buildComposer(context),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickEmojiBar() {
    final emojis = ['👍', '🎓', '📢', '👏', '🤝', '🔥', '📚', '✅'];
    final cs = Theme.of(context).colorScheme;

    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: emojis.length,
        separatorBuilder: (ctx, i) => const Gap(6),
        itemBuilder: (ctx, i) {
          final emoji = emojis[i];
          return InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              HapticUtils.light();
              final currentText = _msgCtrl.text;
              final sel = _msgCtrl.selection;
              if (sel.isValid && sel.start >= 0) {
                final newText = currentText.replaceRange(sel.start, sel.end, emoji);
                _msgCtrl.value = TextEditingValue(
                  text: newText,
                  selection: TextSelection.collapsed(offset: sel.start + emoji.length),
                );
              } else {
                _msgCtrl.text = '$currentText$emoji';
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withAlpha(140),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cs.outlineVariant.withAlpha(50)),
              ),
              child: Center(
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildComposer(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          top: BorderSide(color: cs.outlineVariant.withAlpha(40)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withAlpha(120),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: cs.outlineVariant.withAlpha(60),
                ),
              ),
              child: TextField(
                controller: _msgCtrl,
                minLines: 1,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(fontSize: 15),
                decoration: const InputDecoration(
                  hintText: 'Hat ýazyň…',
                  hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  isDense: true,
                ),
              ),
            ),
          ),
          const Gap(8),
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: (_canSend && !_isSending) ? cs.primary : cs.surfaceContainerHighest,
                shape: BoxShape.circle,
                boxShadow: (_canSend && !_isSending)
                    ? [
                        BoxShadow(
                          color: cs.primary.withAlpha(90),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: (_canSend && !_isSending) ? _handleSend : null,
                  child: Center(
                    child: _isSending
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: cs.primary,
                            ),
                          )
                        : Icon(
                            Icons.send_rounded,
                            size: 20,
                            color: _canSend ? Colors.white : cs.onSurfaceVariant.withAlpha(120),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;

  const _ChatMessageBubble({
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isStarshy = message.isStarshy;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: isStarshy
                  ? const Color(0xFFF59E0B)
                  : cs.primaryContainer,
              child: Text(
                message.senderName.isNotEmpty
                    ? message.senderName[0].toUpperCase()
                    : 'T',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isStarshy ? Colors.white : cs.onPrimaryContainer,
                ),
              ),
            ),
            const Gap(8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.74,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: isMe
                    ? LinearGradient(
                        colors: [cs.primary, const Color(0xFF4F46E5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isMe ? null : cs.surfaceContainerLow,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 18),
                ),
                border: isMe
                    ? null
                    : Border.all(
                        color: cs.outlineVariant.withAlpha(80),
                        width: 1,
                      ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(8),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  // Sender name (diňe başgalaryň hatlarynda)
                  if (!isMe) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          message.senderName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isStarshy
                                ? const Color(0xFFD97706)
                                : cs.primary,
                          ),
                        ),
                        if (isStarshy) ...[
                          const Gap(4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Starşy ⭐',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFB45309),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const Gap(4),
                  ],

                  // Message text
                  SelectableText(
                    message.message,
                    style: TextStyle(
                      fontSize: 14.5,
                      height: 1.35,
                      color: isMe ? Colors.white : cs.onSurface,
                    ),
                  ),
                  const Gap(4),

                  // Timestamp
                  Text(
                    message.formattedTime,
                    style: TextStyle(
                      fontSize: 10,
                      color: isMe
                          ? Colors.white.withAlpha(180)
                          : cs.onSurfaceVariant.withAlpha(140),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

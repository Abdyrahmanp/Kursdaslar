import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  int _lastMessageCount = 0;
  ChatMessage? _replyingTo;

  @override
  void initState() {
    super.initState();
    _msgCtrl.addListener(() {
      final can = _msgCtrl.text.trim().isNotEmpty;
      if (can != _canSend) {
        setState(() => _canSend = can);
      }
    });
    // Ilkinji ýüklenende iň aşaga git
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom(immediate: true);
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

  void _setReply(ChatMessage msg) {
    HapticUtils.light();
    setState(() => _replyingTo = msg);
  }

  void _cancelReply() {
    HapticUtils.light();
    setState(() => _replyingTo = null);
  }

  Future<void> _handleSend() async {
    if (_isSending) return;
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;

    final authState = ref.read(authProvider);
    final student = authState.currentStudent;

    final senderName = student?.name ?? 'Talyp';
    final role = authState.isStarshy ? 'starshy' : 'student';

    ReplyInfo? replyInfo;
    if (_replyingTo != null) {
      replyInfo = ReplyInfo(
        messageId: _replyingTo!.id,
        senderName: _replyingTo!.senderName,
        message: _replyingTo!.message,
      );
    }

    final replyTarget = replyInfo;
    setState(() {
      _isSending = true;
      _replyingTo = null;
    });

    _msgCtrl.clear();
    HapticUtils.light();

    try {
      await ref.read(chatProvider.notifier).sendMessage(
            senderName: senderName,
            senderRole: role,
            message: text,
            replyTo: replyTarget,
          );
      _scrollToBottom();
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  /// Starşy ýa-da Döwletgulyýew Abdyrahman barlagy
  bool _canModerate(AuthState authState) {
    if (authState.isStarshy) return true;
    final s = authState.currentStudent;
    if (s == null) return false;
    final name = s.name.toLowerCase();
    return name.contains('döwletguly') ||
        name.contains('dowletguly') ||
        s.phone.contains('65254766');
  }

  void _showMessageMenu(BuildContext context, ChatMessage msg, AuthState authState) {
    final canModerate = _canModerate(authState);

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Text(
                  '"${msg.message.length > 60 ? '${msg.message.substring(0, 60)}…' : msg.message}"',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Divider(height: 1),
              // Jogap ber
              ListTile(
                leading: const Icon(Icons.reply_rounded, color: Color(0xFF6366F1)),
                title: const Text('Jogap ber'),
                onTap: () {
                  Navigator.pop(ctx);
                  _setReply(msg);
                },
              ),
              // Göçürip al
              ListTile(
                leading: const Icon(Icons.copy_rounded, color: Colors.grey),
                title: const Text('Teksti göçürip al'),
                onTap: () {
                  Navigator.pop(ctx);
                  Clipboard.setData(ClipboardData(text: msg.message));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Hat göçürildi! 📋'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              if (canModerate) ...[
                ListTile(
                  leading: const Icon(Icons.edit_rounded, color: Colors.blue),
                  title: const Text('Haty üýtget'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showEditDialog(context, msg);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_rounded, color: Colors.red),
                  title: const Text(
                    'Haty poz',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _confirmDelete(context, msg);
                  },
                ),
              ],
              const Gap(8),
            ],
          ),
        );
      },
    );
  }

  void _showEditDialog(BuildContext context, ChatMessage msg) {
    final ctrl = TextEditingController(text: msg.message);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Haty üýtget'),
        content: TextField(
          controller: ctrl,
          maxLines: null,
          decoration: const InputDecoration(
            hintText: 'Täze tekst…',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Ýatyr'),
          ),
          FilledButton(
            onPressed: () {
              final newText = ctrl.text.trim();
              if (newText.isNotEmpty && newText != msg.message) {
                ref.read(chatProvider.notifier).editMessage(msg.id, newText);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Sakla'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, ChatMessage msg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Haty pozmak'),
        content: const Text('Bu haty pozmak isleýärsiňizmi? Bu amal yza gaýtaryp bolmaz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Ýok'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              ref.read(chatProvider.notifier).deleteMessage(msg.id);
              Navigator.pop(ctx);
              HapticUtils.medium();
            },
            child: const Text('Hawa, poz'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatProvider);
    final authState = ref.watch(authProvider);
    final currentStudent = authState.currentStudent;
    final currentPhone = currentStudent?.phone ?? '';
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final canModerate = _canModerate(authState);

    // Täze hat gelende awtomatiki aşaga süýşür
    if (messages.length > _lastMessageCount) {
      _lastMessageCount = messages.length;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scrollCtrl.hasClients) return;
        final pos = _scrollCtrl.position;
        final atBottom = pos.maxScrollExtent - pos.pixels < 120;
        if (atBottom || _lastMessageCount <= 3) {
          _scrollToBottom();
        }
      });
    }

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
              Future.delayed(const Duration(milliseconds: 500), () {
                _scrollToBottom();
              });
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

                        // Sağa süýşürip jogap bermek (Bounded Swipe to Reply)
                        return _SwipeToReply(
                          onReply: () => _setReply(msg),
                          child: _ChatMessageBubble(
                            message: msg,
                            isMe: isMe,
                            canModerate: canModerate,
                            onReply: () => _setReply(msg),
                            onLongPress: () => _showMessageMenu(context, msg, authState),
                            onRetry: msg.isFailed
                                ? () => ref.read(chatProvider.notifier).retryMessage(msg.id)
                                : null,
                          ),
                        );
                      },
                    ),
            ),

            // Active Reply bar (Jogap berilýän hat)
            if (_replyingTo != null) _buildReplyPreviewBar(context),

            // Quick emoji bar
            _buildQuickEmojiBar(),

            // Message Composer input
            _buildComposer(context),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyPreviewBar(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final msg = _replyingTo!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withAlpha(160),
        border: Border(
          top: BorderSide(color: cs.outlineVariant.withAlpha(60)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 3.5,
            height: 36,
            decoration: BoxDecoration(
              color: cs.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Gap(10),
          Icon(Icons.reply_rounded, size: 18, color: cs.primary),
          const Gap(8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Jogap berilýär: ${msg.senderName}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: cs.primary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Gap(2),
                Text(
                  msg.message,
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18),
            color: cs.onSurfaceVariant,
            tooltip: 'Ýatyr',
            onPressed: _cancelReply,
          ),
        ],
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
              constraints: const BoxConstraints(maxHeight: 160),
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
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(fontSize: 15),
                decoration: InputDecoration(
                  hintText: _replyingTo != null
                      ? '${_replyingTo!.senderName} üçin jogap…'
                      : 'Hat ýazyň…',
                  hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
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

// ── Bounded Swipe to Reply ──────────────────────────────────────────────────

class _SwipeToReply extends StatefulWidget {
  final Widget child;
  final VoidCallback onReply;

  const _SwipeToReply({
    super.key,
    required this.child,
    required this.onReply,
  });

  @override
  State<_SwipeToReply> createState() => _SwipeToReplyState();
}

class _SwipeToReplyState extends State<_SwipeToReply>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Animation<double>? _animation;
  double _dragOffset = 0.0;
  static const double _maxDragOffset = 64.0; // Strictly bounded range
  static const double _triggerThreshold = 38.0;
  bool _hasTriggered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if ((details.primaryDelta ?? 0) > 0 || _dragOffset > 0) {
      final delta = details.primaryDelta ?? 0;
      double newOffset = _dragOffset + delta;
      if (newOffset < 0) newOffset = 0;
      if (newOffset > _maxDragOffset) {
        // Friction when pulled beyond max
        newOffset = _maxDragOffset + (newOffset - _maxDragOffset) * 0.1;
      }
      setState(() {
        _dragOffset = newOffset;
        if (_dragOffset >= _triggerThreshold && !_hasTriggered) {
          _hasTriggered = true;
          HapticUtils.light();
        }
      });
    }
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_hasTriggered) {
      widget.onReply();
    }
    _hasTriggered = false;
    _animation = Tween<double>(begin: _dragOffset, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    )..addListener(() {
        setState(() => _dragOffset = _animation!.value);
      });
    _controller.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final progress = (_dragOffset / _triggerThreshold).clamp(0.0, 1.0);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          if (_dragOffset > 4)
            Positioned(
              left: 12,
              child: Opacity(
                opacity: progress,
                child: Transform.scale(
                  scale: 0.5 + 0.5 * progress,
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: _hasTriggered ? cs.primary : cs.primary.withAlpha(50),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.reply_rounded,
                      color: _hasTriggered ? Colors.white : cs.primary,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
          Transform.translate(
            offset: Offset(_dragOffset, 0),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}

// ── Message Bubble ────────────────────────────────────────────────────────────

class _ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final bool canModerate;
  final VoidCallback? onReply;
  final VoidCallback? onLongPress;
  final VoidCallback? onRetry;

  const _ChatMessageBubble({
    required this.message,
    required this.isMe,
    required this.canModerate,
    this.onReply,
    this.onLongPress,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isStarshy = message.isStarshy;
    final isPending = message.isPending;
    final isFailed = message.isFailed;
    final hasReply = message.hasReply;

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
            child: GestureDetector(
              onLongPress: onLongPress,
              child: AnimatedOpacity(
                opacity: isPending ? 0.65 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.74,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: isMe && !isFailed
                        ? LinearGradient(
                            colors: [cs.primary, const Color(0xFF4F46E5)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isFailed
                        ? Colors.red.shade50
                        : (isMe ? null : cs.surfaceContainerLow),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isMe ? 18 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 18),
                    ),
                    border: isFailed
                        ? Border.all(color: Colors.red.shade300, width: 1.5)
                        : (isMe
                            ? null
                            : Border.all(
                                color: cs.outlineVariant.withAlpha(80),
                                width: 1,
                              )),
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

                      // Quoted Message (Alıntı / Jogap berilýän hat)
                      if (hasReply && message.replyTo != null) ...[
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isMe
                                ? Colors.white.withAlpha(35)
                                : cs.surfaceContainerHighest.withAlpha(160),
                            borderRadius: BorderRadius.circular(10),
                            border: Border(
                              left: BorderSide(
                                color: isMe ? Colors.white : cs.primary,
                                width: 3.5,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.reply_rounded,
                                    size: 13,
                                    color: isMe
                                        ? Colors.white.withAlpha(220)
                                        : cs.primary,
                                  ),
                                  const Gap(4),
                                  Flexible(
                                    child: Text(
                                      message.replyTo!.senderName,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isMe ? Colors.white : cs.primary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const Gap(2),
                              Text(
                                message.replyTo!.preview,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: isMe
                                      ? Colors.white.withAlpha(200)
                                      : cs.onSurfaceVariant,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Message text
                      SelectableText(
                        message.message,
                        style: TextStyle(
                          fontSize: 14.5,
                          height: 1.35,
                          color: isFailed
                              ? Colors.red.shade700
                              : (isMe ? Colors.white : cs.onSurface),
                        ),
                      ),
                      const Gap(4),

                      // Timestamp + status row
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isFailed) ...[
                            GestureDetector(
                              onTap: onRetry,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.refresh_rounded,
                                        size: 11, color: Colors.red.shade700),
                                    const Gap(3),
                                    Text(
                                      'Täzeden ugrat',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.red.shade700,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const Gap(6),
                          ],
                          Text(
                            message.formattedTime,
                            style: TextStyle(
                              fontSize: 10,
                              color: isFailed
                                  ? Colors.red.shade400
                                  : (isMe
                                      ? Colors.white.withAlpha(180)
                                      : cs.onSurfaceVariant.withAlpha(140)),
                            ),
                          ),
                          if (isPending) ...[
                            const Gap(4),
                            SizedBox(
                              width: 10,
                              height: 10,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: isMe
                                    ? Colors.white.withAlpha(180)
                                    : cs.primary.withAlpha(150),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
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

import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:car/services/translation_service.dart';

class ChatPage extends StatefulWidget {
  final SupabaseClient? supabaseClient;
  const ChatPage({super.key, this.supabaseClient});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late final SupabaseClient _supabase;
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final ts = TranslationService();

  List<Map<String, dynamic>> _messages = [];
  Map<String, dynamic>? _request;
  Map<String, dynamic>? _agent;
  String? _conversationId;
  bool _isLoading = true;
  bool _isSending = false;
  bool _isAgentTyping = false;
  bool _isSupportMode = false;
  RealtimeChannel? _channel;
  Timer? _typingTimer;
  Timer? _myTypingDebounce;
  bool _initialized = false;

  static const _primaryColor = Color(0xFFD4AF37);
  static const _backgroundColor = Color(0xFF0A0A0A);
  static const _cardColor = Color(0xFF141414);
  static const _borderColor = Color(0xFF2A2A2A);
  static const _mutedForeground = Color(0xFFA3A3A3);
  static const _secondaryColor = Color(0xFF1F1F1F);

  @override
  void initState() {
    super.initState();
    _supabase = widget.supabaseClient ?? Supabase.instance.client;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map && args['is_support'] == true) {
        _isSupportMode = true;
        _request = null;
      } else {
        _request = args as Map<String, dynamic>?;
      }
      _initialized = true;
      _loadData();
    }
  }

  Future<void> _loadData() async {
    if (_isSupportMode) {
      await _ensureSupportConversation();
    } else {
      _loadAgentFromRequest();
      await _ensureConversation();
    }
    if (_conversationId != null) {
      await _fetchMessages();
      _subscribeToMessages();
    }
    if (mounted) setState(() => _isLoading = false);
    _scrollToBottom();
  }

  void _loadAgentFromRequest() {
    final agentData = _request?['agents'];
    if (agentData != null) {
      if (mounted) {
        setState(() => _agent = {
          'full_name': agentData['name'] ?? agentData['full_name'] ?? '',
          'avatar_url': agentData['avatar_url'],
          'specialty': agentData['specialty'],
        });
      }
    }
  }

  Future<void> _ensureConversation() async {
    final requestId = _request?['id'];
    if (requestId == null) return;

    try {
      final existing = await _supabase
          .schema('cartel')
          .from('conversations')
          .select('id')
          .eq('request_id', requestId)
          .maybeSingle();

      if (existing != null) {
        _conversationId = existing['id'] as String;
        return;
      }

      final userId = _supabase.auth.currentUser?.id;
      final agentId = _request?['agent_id'];
      if (userId == null || agentId == null) return;

      final created = await _supabase
          .schema('cartel')
          .from('conversations')
          .insert({
            'request_id': requestId,
            'client_id': userId,
            'agent_id': agentId,
          })
          .select('id')
          .single();

      _conversationId = created['id'] as String;
    } catch (e) {
      debugPrint('Error ensuring conversation: $e');
    }
  }

  Future<void> _ensureSupportConversation() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // Look for an existing support conversation for this user
      final existing = await _supabase
          .schema('cartel')
          .from('conversations')
          .select('id, agent_id, agents(name, avatar_url, specialty)')
          .eq('client_id', userId)
          .eq('is_support', true)
          .maybeSingle();

      if (existing != null) {
        _conversationId = existing['id'] as String;
        _setAgentFromData(existing['agents']);
        return;
      }

      // Find an admin/support agent
      final adminAgent = await _supabase
          .schema('cartel')
          .from('agents')
          .select('id, name, avatar_url, specialty')
          .eq('role', 'admin')
          .maybeSingle();

      _setAgentFromData(adminAgent);

      final created = await _supabase
          .schema('cartel')
          .from('conversations')
          .insert({
            'client_id': userId,
            'agent_id': adminAgent?['id'],
            'is_support': true,
          })
          .select('id')
          .single();

      _conversationId = created['id'] as String;
    } catch (e) {
      debugPrint('Error ensuring support conversation: $e');
    }
  }

  void _setAgentFromData(dynamic agentData) {
    if (!mounted) return;
    setState(() => _agent = {
      'full_name': agentData?['name'] ?? ts.translate('support_center'),
      'avatar_url': agentData?['avatar_url'],
      'specialty': agentData?['specialty'] ?? ts.translate('support_center'),
    });
  }

  Future<void> _fetchMessages() async {
    final convId = _conversationId;
    if (convId == null) return;
    try {
      final response = await _supabase
          .schema('cartel')
          .from('messages')
          .select()
          .eq('conversation_id', convId)
          .order('created_at', ascending: true);
      if (mounted) {
        setState(() => _messages = List<Map<String, dynamic>>.from(response));
      }
      await _markAgentMessagesAsRead();
    } catch (e) {
      debugPrint('Error fetching messages: $e');
    }
  }

  Future<void> _markAgentMessagesAsRead() async {
    final convId = _conversationId;
    if (convId == null) return;
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      final updated = await _supabase
          .schema('cartel')
          .from('messages')
          .update({'read_at': now})
          .eq('conversation_id', convId)
          .inFilter('sender_role', ['Agent', 'Admin'])
          .isFilter('read_at', null)
          .select('id');
      if (mounted && (updated as List).isNotEmpty) {
        setState(() {
          for (final u in updated) {
            final id = u['id'] as String?;
            if (id == null) continue;
            final idx = _messages.indexWhere((m) => m['id'] == id);
            if (idx != -1) _messages[idx] = {..._messages[idx], 'read_at': now};
          }
        });
      }
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  void _subscribeToMessages() {
    final convId = _conversationId;
    if (convId == null) return;

    _channel = _supabase
        .channel('chat:$convId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'cartel',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: convId,
          ),
          callback: (payload) {
            if (!mounted) return;
            final incoming = payload.newRecord;
            final id = incoming['id'] as String?;
            final alreadyExists = id != null && _messages.any((m) => m['id'] == id);
            if (!alreadyExists) {
              setState(() => _messages.add(incoming));
              _scrollToBottom();
              final role = incoming['sender_role'] as String?;
              if (role == 'Agent' || role == 'Admin') {
                _markAgentMessagesAsRead();
              }
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'cartel',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: convId,
          ),
          callback: (payload) {
            if (!mounted) return;
            final updated = payload.newRecord;
            final id = updated['id'] as String?;
            if (id == null) return;
            setState(() {
              final idx = _messages.indexWhere((m) => m['id'] == id);
              if (idx != -1) _messages[idx] = {..._messages[idx], ...updated};
            });
          },
        )
        .onBroadcast(
          event: 'typing',
          callback: (payload) {
            if (!mounted) return;
            final role = payload['role'] as String?;
            if (role == 'Agent' || role == 'Admin') {
              _typingTimer?.cancel();
              setState(() => _isAgentTyping = true);
              _scrollToBottom();
              _typingTimer = Timer(const Duration(seconds: 3), () {
                if (mounted) setState(() => _isAgentTyping = false);
              });
            }
          },
        )
        .subscribe();
  }

  void _onTextChanged(String value) {
    _myTypingDebounce?.cancel();
    if (value.trim().isEmpty || _conversationId == null) return;
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    _channel?.sendBroadcastMessage(
      event: 'typing',
      payload: {'role': 'Client', 'sender_id': userId},
    );
    _myTypingDebounce = Timer(const Duration(milliseconds: 2000), () {});
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    final convId = _conversationId;
    final userId = _supabase.auth.currentUser?.id;
    if (convId == null || userId == null) return;

    _controller.clear();

    final optimisticId = 'optimistic_${DateTime.now().millisecondsSinceEpoch}';
    final optimisticMsg = {
      'id': optimisticId,
      'conversation_id': convId,
      'sender_id': userId,
      'sender_role': 'Client',
      'content': text,
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'read_at': null,
    };

    setState(() {
      _messages.add(optimisticMsg);
      _isSending = true;
    });
    _scrollToBottom();

    try {
      final inserted = await _supabase
          .schema('cartel')
          .from('messages')
          .insert({
            'conversation_id': convId,
            'sender_id': userId,
            'sender_role': 'Client',
            'content': text,
          })
          .select()
          .single();

      if (mounted) {
        setState(() {
          final idx = _messages.indexWhere((m) => m['id'] == optimisticId);
          if (idx != -1) _messages[idx] = inserted;
        });
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
      if (mounted) {
        setState(() => _messages.removeWhere((m) => m['id'] == optimisticId));
        _controller.text = text;
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
  void dispose() {
    _typingTimer?.cancel();
    _myTypingDebounce?.cancel();
    _channel?.unsubscribe();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ts,
      builder: (context, _) => Scaffold(
        backgroundColor: _backgroundColor,
        body: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: _primaryColor))
                  : _messages.isEmpty
                      ? _buildEmptyState()
                      : _buildMessageList(),
            ),
            _buildInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final agentName = _agent?['full_name'] as String? ?? '—';
    final agentAvatar = _agent?['avatar_url'] as String?;
    final specialty = _agent?['specialty'] as String? ?? ts.translate('luxury_expert');

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        bottom: 16,
        left: 16,
        right: 16,
      ),
      decoration: BoxDecoration(
        color: _backgroundColor.withValues(alpha: 0.92),
        border: const Border(bottom: BorderSide(color: _borderColor, width: 0.5)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _secondaryColor.withValues(alpha: 0.5),
                shape: BoxShape.circle,
                border: Border.all(color: _borderColor),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: agentAvatar != null ? CachedNetworkImageProvider(agentAvatar) : null,
                      backgroundColor: _secondaryColor,
                      child: agentAvatar == null
                          ? Text(
                              agentName.isNotEmpty ? agentName[0].toUpperCase() : 'A',
                              style: GoogleFonts.montserrat(color: _primaryColor, fontWeight: FontWeight.bold),
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: _backgroundColor, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      agentName,
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(color: _primaryColor, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${ts.translate('online')} • $specialty',
                          style: GoogleFonts.dmSans(
                            color: _primaryColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.chat_bubble_outline_rounded, size: 48, color: _mutedForeground),
          const SizedBox(height: 12),
          Text(
            ts.translate('chat_with_agent'),
            style: GoogleFonts.dmSans(color: _mutedForeground, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    final currentUserId = _supabase.auth.currentUser?.id;
    final grouped = _groupByDate(_messages);
    final itemCount = grouped.length + (_isAgentTyping ? 1 : 0);

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index == grouped.length && _isAgentTyping) {
          return _buildTypingIndicator();
        }
        final item = grouped[index];
        if (item['type'] == 'date') {
          return _buildDateSeparator(item['label'] as String);
        }
        final msg = item['message'] as Map<String, dynamic>;
        final isMe = msg['sender_id'] == currentUserId ||
            msg['sender_role'] == 'Client';
        return _buildMessage(msg, isMe);
      },
    );
  }

  Widget _buildTypingIndicator() {
    final agentName = _agent?['full_name'] as String? ?? '';
    final label = agentName.isNotEmpty
        ? '$agentName ${ts.translate('typing')}'
        : ts.translate('typing');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TypingDots(),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.dmSans(
              color: _mutedForeground,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _groupByDate(List<Map<String, dynamic>> messages) {
    final result = <Map<String, dynamic>>[];
    String? lastDate;

    for (final msg in messages) {
      final dt = DateTime.tryParse(msg['created_at'] ?? '');
      if (dt == null) continue;
      final dateStr = DateFormat('yyyy-MM-dd').format(dt.toLocal());
      if (dateStr != lastDate) {
        lastDate = dateStr;
        result.add({'type': 'date', 'label': _formatDateLabel(dt.toLocal())});
      }
      result.add({'type': 'message', 'message': msg});
    }
    return result;
  }

  String _formatDateLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final msgDay = DateTime(dt.year, dt.month, dt.day);
    if (msgDay == today) return ts.translate('today');
    if (msgDay == yesterday) return ts.translate('yesterday');
    return DateFormat('dd MMM yyyy').format(dt);
  }

  Widget _buildDateSeparator(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: _secondaryColor.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text(
            label,
            style: GoogleFonts.dmSans(
              color: _mutedForeground,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessage(Map<String, dynamic> msg, bool isMe) {
    final content = msg['content'] as String? ?? '';
    final imageUrl = msg['image_url'] as String?;
    final dt = DateTime.tryParse(msg['created_at'] ?? '')?.toLocal();
    final timeStr = dt != null ? DateFormat('hh:mm a').format(dt) : '';
    final isRead = msg['read_at'] != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (imageUrl != null)
                _buildImageMessage(imageUrl, content, isMe)
              else
                _buildTextBubble(content, isMe),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    timeStr,
                    style: GoogleFonts.dmSans(color: _mutedForeground, fontSize: 8, fontWeight: FontWeight.w500),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.done_all_rounded,
                      color: isRead ? _primaryColor : _mutedForeground,
                      size: 12,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextBubble(String content, bool isMe) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isMe ? _primaryColor : _cardColor.withValues(alpha: 0.6),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: isMe ? const Radius.circular(18) : const Radius.circular(4),
          bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(18),
        ),
        border: isMe ? null : Border.all(color: _borderColor.withValues(alpha: 0.4)),
        boxShadow: isMe
            ? [BoxShadow(color: _primaryColor.withValues(alpha: 0.2), blurRadius: 15, offset: const Offset(0, 4))]
            : null,
      ),
      child: Text(
        content,
        style: GoogleFonts.plusJakartaSans(
          color: isMe ? Colors.black : Colors.white,
          fontSize: 13,
          height: 1.5,
          fontWeight: isMe ? FontWeight.w500 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildImageMessage(String imageUrl, String caption, bool isMe) {
    return Container(
      decoration: BoxDecoration(
        color: _cardColor.withValues(alpha: 0.6),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: isMe ? const Radius.circular(18) : const Radius.circular(4),
          bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(18),
        ),
        border: Border.all(color: _borderColor.withValues(alpha: 0.4)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(17),
          topRight: const Radius.circular(17),
          bottomLeft: isMe ? const Radius.circular(17) : const Radius.circular(3),
          bottomRight: isMe ? const Radius.circular(3) : const Radius.circular(17),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CachedNetworkImage(
              imageUrl: imageUrl,
              height: 140,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(height: 140, color: _secondaryColor),
              errorWidget: (context, url, error) => Container(height: 140, color: _secondaryColor),
            ),
            if (caption.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(10),
                child: Text(
                  caption,
                  style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: _backgroundColor.withValues(alpha: 0.92),
        border: const Border(top: BorderSide(color: _borderColor, width: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _secondaryColor.withValues(alpha: 0.4),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add_circle_outline_rounded, color: _mutedForeground, size: 22),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _controller,
              style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: ts.translate('write_message'),
                hintStyle: GoogleFonts.plusJakartaSans(color: _mutedForeground, fontSize: 13),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onChanged: _onTextChanged,
              onSubmitted: (_) => _sendMessage(),
              textInputAction: TextInputAction.send,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: _primaryColor,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Color(0x33D4AF37), blurRadius: 12, offset: Offset(0, 4))],
              ),
              child: _isSending
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded, color: Colors.black, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF141414).withValues(alpha: 0.6),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
          bottomRight: Radius.circular(18),
          bottomLeft: Radius.circular(4),
        ),
        border: Border.all(color: const Color(0xFF2A2A2A).withValues(alpha: 0.4)),
      ),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              final offset = ((_controller.value * 3) - i).clamp(0.0, 1.0);
              final bounce = offset < 0.5 ? offset * 2 : (1 - offset) * 2;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Transform.translate(
                  offset: Offset(0, -4 * bounce),
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: const Color(0xFFA3A3A3).withValues(alpha: 0.6 + 0.4 * bounce),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

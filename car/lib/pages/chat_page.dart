import 'dart:async';
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
  bool _isLoading = true;
  bool _isSending = false;
  RealtimeChannel? _channel;
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
      _request = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      _initialized = true;
      _loadData();
    }
  }

  Future<void> _loadData() async {
    _loadAgentFromRequest();
    await _fetchMessages();
    _subscribeToMessages();
    if (mounted) setState(() => _isLoading = false);
    _scrollToBottom();
  }

  void _loadAgentFromRequest() {
    final agentData = _request?['agents'];
    if (agentData != null) {
      setState(() => _agent = {
        'full_name': agentData['name'] ?? agentData['full_name'] ?? '',
        'avatar_url': agentData['avatar_url'],
        'specialty': agentData['specialty'],
      });
    }
  }

  Future<void> _fetchMessages() async {
    final requestId = _request?['id'];
    if (requestId == null) return;
    try {
      final response = await _supabase
          .schema('cartel')
          .from('messages')
          .select()
          .eq('request_id', requestId)
          .order('created_at', ascending: true);
      if (mounted) {
        setState(() => _messages = List<Map<String, dynamic>>.from(response));
      }
    } catch (e) {
      debugPrint('Error fetching messages: $e');
    }
  }

  void _subscribeToMessages() {
    final requestId = _request?['id'];
    if (requestId == null) return;

    _channel = _supabase
        .channel('chat:$requestId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'cartel',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'request_id',
            value: requestId,
          ),
          callback: (payload) {
            if (mounted) {
              setState(() => _messages.add(payload.newRecord));
              _scrollToBottom();
            }
          },
        )
        .subscribe();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    final userId = _supabase.auth.currentUser?.id;
    final requestId = _request?['id'];
    if (userId == null || requestId == null) return;

    _controller.clear();
    setState(() => _isSending = true);

    try {
      await _supabase.schema('cartel').from('messages').insert({
        'request_id': requestId,
        'sender_id': userId,
        'content': text,
        'sender_role': 'user',
      });
    } catch (e) {
      debugPrint('Error sending message: $e');
      if (mounted) _controller.text = text;
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
                      backgroundImage: agentAvatar != null ? NetworkImage(agentAvatar) : null,
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
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _secondaryColor.withValues(alpha: 0.5),
              shape: BoxShape.circle,
              border: Border.all(color: _borderColor),
            ),
            child: const Icon(Icons.phone_outlined, color: Colors.white, size: 18),
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

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final item = grouped[index];
        if (item['type'] == 'date') {
          return _buildDateSeparator(item['label'] as String);
        }
        final msg = item['message'] as Map<String, dynamic>;
        final isMe = msg['sender_id'] == currentUserId || msg['sender_role'] == 'user';
        return _buildMessage(msg, isMe);
      },
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
                    const Icon(Icons.done_all_rounded, color: _primaryColor, size: 12),
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
            Image.network(
              imageUrl,
              height: 140,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(height: 140, color: _secondaryColor),
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

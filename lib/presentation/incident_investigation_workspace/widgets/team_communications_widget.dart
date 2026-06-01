import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../../services/investigation_workspace_service.dart';
import '../../../services/supabase_service.dart';

class TeamCommunicationsWidget extends StatefulWidget {
  final String incidentId;

  const TeamCommunicationsWidget({super.key, required this.incidentId});

  @override
  State<TeamCommunicationsWidget> createState() =>
      _TeamCommunicationsWidgetState();
}

class _TeamCommunicationsWidgetState extends State<TeamCommunicationsWidget> {
  final _workspaceService = InvestigationWorkspaceService();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _isDecision = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      final messages = await _workspaceService.getMessages(widget.incidentId);
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
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

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final currentUserId = SupabaseService.instance.client.auth.currentUser?.id;
    if (currentUserId == null) return;

    try {
      await _workspaceService.sendMessage(
        incidentId: widget.incidentId,
        senderId: currentUserId,
        message: _messageController.text.trim(),
        isDecision: _isDecision,
      );

      _messageController.clear();
      setState(() {
        _isDecision = false;
      });
      await _loadMessages();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Expanded(
          child: _messages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline,
                          size: 64, color: Colors.grey[400]),
                      SizedBox(height: 2.h),
                      Text(
                        'No messages yet',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.all(3.w),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    final sender = message['sender'] as Map<String, dynamic>?;
                    final currentUserId =
                        SupabaseService.instance.client.auth.currentUser?.id;
                    final isOwnMessage = message['sender_id'] == currentUserId;

                    return Padding(
                      padding: EdgeInsets.only(bottom: 2.h),
                      child: Row(
                        mainAxisAlignment: isOwnMessage
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isOwnMessage) ...[
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.blue[100],
                              backgroundImage: sender?['avatar_url'] != null
                                  ? NetworkImage(sender!['avatar_url'])
                                  : null,
                              child: sender?['avatar_url'] == null
                                  ? Text(
                                      sender?['full_name']?[0]?.toUpperCase() ??
                                          'U',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue[700],
                                      ),
                                    )
                                  : null,
                            ),
                            SizedBox(width: 2.w),
                          ],
                          Flexible(
                            child: Container(
                              padding: EdgeInsets.all(3.w),
                              decoration: BoxDecoration(
                                color: isOwnMessage
                                    ? Colors.blue[700]
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(12),
                                  topRight: const Radius.circular(12),
                                  bottomLeft:
                                      Radius.circular(isOwnMessage ? 12 : 0),
                                  bottomRight:
                                      Radius.circular(isOwnMessage ? 0 : 12),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (!isOwnMessage)
                                    Text(
                                      sender?['full_name'] ?? 'Unknown',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  if (message['is_decision'] == true) ...[
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 2.w,
                                        vertical: 0.5.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.amber[100],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.gavel,
                                            size: 12.sp,
                                            color: Colors.amber[900],
                                          ),
                                          SizedBox(width: 1.w),
                                          Text(
                                            'DECISION',
                                            style: TextStyle(
                                              fontSize: 10.sp,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.amber[900],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: 1.h),
                                  ],
                                  Text(
                                    message['message'],
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      color: isOwnMessage
                                          ? Colors.white
                                          : Colors.grey[800],
                                    ),
                                  ),
                                  SizedBox(height: 1.h),
                                  Text(
                                    DateFormat('HH:mm').format(
                                      DateTime.parse(message['created_at']),
                                    ),
                                    style: TextStyle(
                                      fontSize: 10.sp,
                                      color: isOwnMessage
                                          ? Colors.white.withAlpha(179)
                                          : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (isOwnMessage) SizedBox(width: 2.w),
                        ],
                      ),
                    );
                  },
                ),
        ),
        Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withAlpha(51),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              children: [
                if (_isDecision)
                  Container(
                    padding: EdgeInsets.all(2.w),
                    margin: EdgeInsets.only(bottom: 2.h),
                    decoration: BoxDecoration(
                      color: Colors.amber[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.gavel, color: Colors.amber[900], size: 20),
                        SizedBox(width: 2.w),
                        Text(
                          'Logging as Decision',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.amber[900],
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          iconSize: 20,
                          onPressed: () {
                            setState(() {
                              _isDecision = false;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.gavel,
                        color:
                            _isDecision ? Colors.amber[900] : Colors.grey[600],
                      ),
                      onPressed: () {
                        setState(() {
                          _isDecision = !_isDecision;
                        });
                      },
                    ),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 4.w,
                            vertical: 1.h,
                          ),
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.send, color: Colors.blue[700]),
                      onPressed: _sendMessage,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

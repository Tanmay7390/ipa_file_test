import 'package:flutter/cupertino.dart';

class ChatPage extends StatefulWidget {
  final String userName;
  final String? userPhoto;

  const ChatPage({
    super.key,
    required this.userName,
    this.userPhoto,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    // Add some static messages
    _messages.addAll([
      {
        'text': 'Hi! Looking forward to connecting at the conference.',
        'isSender': false,
        'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
      },
      {
        'text': 'Hello! Yes, me too. Are you attending the panel discussion tomorrow?',
        'isSender': true,
        'timestamp': DateTime.now().subtract(const Duration(hours: 1, minutes: 55)),
      },
      {
        'text': 'Absolutely! I\'m really interested in the future trends topic.',
        'isSender': false,
        'timestamp': DateTime.now().subtract(const Duration(hours: 1, minutes: 50)),
      },
      {
        'text': 'Great! We should definitely meet up after the session.',
        'isSender': true,
        'timestamp': DateTime.now().subtract(const Duration(hours: 1, minutes: 45)),
      },
    ]);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isNotEmpty) {
      setState(() {
        _messages.add({
          'text': _messageController.text.trim(),
          'isSender': true,
          'timestamp': DateTime.now(),
        });
      });
      _messageController.clear();

      // Scroll to bottom
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
  }

  String _formatTime(DateTime timestamp) {
    final hour = timestamp.hour > 12 ? timestamp.hour - 12 : timestamp.hour;
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final period = timestamp.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? Color(0xFF23C061) : Color(0xFF21AA62);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.systemBackground.resolveFrom(context),
        border: const Border(
          bottom: BorderSide(
            color: CupertinoColors.systemGrey,
            width: 0.2,
          ),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CupertinoIcons.back,
                color: activeColor,
                size: 28,
              ),
              const SizedBox(width: 4),
              Text(
                'Back',
                style: TextStyle(
                  fontSize: 17,
                  fontFamily: 'SF Pro Display',
                  letterSpacing: 0.2,
                  color: activeColor,
                ),
              ),
            ],
          ),
        ),
        middle: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.userPhoto != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.network(
                  widget.userPhoto!,
                  width: 30,
                  height: 30,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey5.resolveFrom(context),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      CupertinoIcons.person_fill,
                      size: 16,
                      color: CupertinoColors.systemGrey.resolveFrom(context),
                    ),
                  ),
                ),
              ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                widget.userName,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'SF Pro Display',
                  letterSpacing: 0.2,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {},
          child: Icon(
            CupertinoIcons.phone_fill,
            color: activeColor,
            size: 22,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Messages list
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  final isSender = message['isSender'] as bool;
                  final text = message['text'] as String;
                  final timestamp = message['timestamp'] as DateTime;

                  return _buildMessageBubble(
                    text: text,
                    isSender: isSender,
                    timestamp: timestamp,
                    isDark: isDark,
                  );
                },
              ),
            ),

            // Message input area
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: CupertinoColors.systemBackground.resolveFrom(context),
                border: Border(
                  top: BorderSide(
                    color: CupertinoColors.separator.resolveFrom(context),
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Camera button
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {},
                    child: Icon(
                      CupertinoIcons.camera_fill,
                      color: CupertinoColors.systemGrey.resolveFrom(context),
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Text input
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemGrey6.resolveFrom(context),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: CupertinoTextField(
                              controller: _messageController,
                              placeholder: 'Message',
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: null,
                              style: TextStyle(
                                fontSize: 16,
                                fontFamily: 'SF Pro Display',
                                letterSpacing: 0.2,
                              ),
                              maxLines: null,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Send button
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _sendMessage,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: activeColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        CupertinoIcons.arrow_up,
                        color: CupertinoColors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble({
    required String text,
    required bool isSender,
    required DateTime timestamp,
    required bool isDark,
  }) {
    final activeColor = isDark ? Color(0xFF23C061) : Color(0xFF21AA62);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isSender ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isSender)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: widget.userPhoto != null
                    ? Image.network(
                        widget.userPhoto!,
                        width: 30,
                        height: 30,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemGrey5.resolveFrom(context),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Icon(
                            CupertinoIcons.person_fill,
                            size: 16,
                            color: CupertinoColors.systemGrey.resolveFrom(context),
                          ),
                        ),
                      )
                    : Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemGrey5.resolveFrom(context),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(
                          CupertinoIcons.person_fill,
                          size: 16,
                          color: CupertinoColors.systemGrey.resolveFrom(context),
                        ),
                      ),
              ),
            ),
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSender
                        ? activeColor
                        : (isDark
                            ? CupertinoColors.systemGrey5.darkColor
                            : CupertinoColors.systemGrey6),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft:
                          isSender ? const Radius.circular(18) : Radius.zero,
                      bottomRight:
                          isSender ? Radius.zero : const Radius.circular(18),
                    ),
                  ),
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'SF Pro Display',
                      letterSpacing: 0.2,
                      color: isSender
                          ? CupertinoColors.white
                          : CupertinoTheme.of(context).textTheme.textStyle.color,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'SF Pro Display',
                    letterSpacing: 0.2,
                    color: CupertinoColors.systemGrey.resolveFrom(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

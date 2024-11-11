// view.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../controllers/chat_group_controller.dart';
import '../models/chat_group_model.dart';

class GroupChatPage extends StatefulWidget {
  final String userId;

  const GroupChatPage({Key? key, required this.userId}) : super(key: key);

  @override
  _GroupChatPageState createState() => _GroupChatPageState();
}

class _GroupChatPageState extends State<GroupChatPage> {
  late GroupChatController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = GroupChatController(userId: widget.userId);
    _initializeController();
  }

  Future<void> _initializeController() async {
    try {
      await _controller.fetchUserData();
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildMessageComposer() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller.messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: InputBorder.none,
              ),
              onSubmitted: (_) => _controller.sendMessage(context),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send),
            color: Colors.blue,
            onPressed: () => _controller.sendMessage(context),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble({
    required String message,
    required bool isMe,
    required String sender,
    required Timestamp timestamp,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            sender,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            decoration: BoxDecoration(
              color: isMe ? Colors.brown[300] : Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              message,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black,
              ),
            ),
          ),
          Text(
            _controller.formatTimestamp(timestamp),
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5E6D3),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Factory Group Chat',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: CustomPaint(
              painter: TopHillPainter(),
              size: Size(MediaQuery.of(context).size.width, 250),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: _isLoading
                      ? Center(child: CircularProgressIndicator())
                      : StreamBuilder<QuerySnapshot>(
                          stream: _controller.getChatStream(),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Center(child: Text('Error: ${snapshot.error}'));
                            }

                            if (!snapshot.hasData) {
                              return Center(child: CircularProgressIndicator());
                            }

                            List<DocumentSnapshot> docs = snapshot.data!.docs;

                            if (docs.isEmpty) {
                              return Center(
                                child: Text(
                                  'No messages yet.\nBe the first to send a message!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                ),
                              );
                            }

                            return ListView.builder(
                              reverse: true,
                              controller: _controller.scrollController,
                              itemCount: docs.length,
                              itemBuilder: (context, index) {
                                Map<String, dynamic> data = 
                                    docs[index].data() as Map<String, dynamic>;
                                bool isMe = data['userId'] == widget.userId;

                                return _buildMessageBubble(
                                  message: data['message'] ?? '',
                                  isMe: isMe,
                                  sender: data['senderName'] ?? 'Unknown User',
                                  timestamp: data['timestamp'] ?? Timestamp.now(),
                                );
                              },
                            );
                          },
                        ),
                ),
                _buildMessageComposer(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class TopHillPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.brown[300]!
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(0, size.height * 0.7);
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height * 1.2,
      size.width,
      size.height * 0.7,
    );
    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
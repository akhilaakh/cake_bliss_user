import 'package:cake_bliss/constants/app_colors.dart';
import 'package:flutter/material.dart';

class Chat extends StatefulWidget {
  const Chat({super.key});

  @override
  State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildChatMessages(),
          _buildMessageInputField(),
        ],
      ),
    );
  }

  /// Builds the custom app bar with user details
  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors().mainColor,
      toolbarHeight: 100,
      title: const Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: NetworkImage(
              '', // Replace with your image URL
            ),
          ),
          SizedBox(width: 10),
          Text(
            'Akhi',
            style: TextStyle(fontSize: 20, color: Colors.white),
          ),
        ],
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(25),
          bottomRight: Radius.circular(25),
        ),
      ),
    );
  }

  /// Builds the list of chat messages
  Expanded _buildChatMessages() {
    return Expanded(
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildReceivedMessage('Hello'),
          const SizedBox(height: 10),
          _buildSentMessage('hii'),
        ],
      ),
    );
  }

  /// Builds a received message bubble
  Widget _buildReceivedMessage(String message) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFCEDE4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black12),
        ),
        child: Text(
          message,
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  /// Builds a sent message bubble
  Widget _buildSentMessage(String message) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors().mainColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          message,
          style: const TextStyle(fontSize: 16, color: Colors.white),
        ),
      ),
    );
  }

  /// Builds the message input field with attachments and send button
  Padding _buildMessageInputField() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          // Attach image button
          IconButton(
            onPressed: () {
              // Implement image attachment functionality
            },
            icon: Icon(Icons.image, color: AppColors().mainColor),
          ),
          // Input field for typing messages
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: 'Message',
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          // Send message button
          IconButton(
            onPressed: () {
              // Implement send message functionality
            },
            icon: Icon(Icons.send, color: AppColors().mainColor),
          ),
        ],
      ),
    );
  }
}

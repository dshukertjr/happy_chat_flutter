import 'dart:async';

import 'package:flutter/material.dart';
import 'package:happychat/models/message.dart';
import 'package:happychat/models/profile.dart';
import 'package:happychat/models/room.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatRoomPage extends StatefulWidget {
  const ChatRoomPage({
    Key? key,
    required this.room,
  }) : super(key: key);

  final Room room;

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  List<Message>? _messages;

  final Map<String, Profile> _profileCache = {};

  StreamSubscription<List<Message>>? _messagesListener;

  @override
  void initState() {
    _messagesListener = Supabase.instance.client
        .from('messages:room_id=eq.${widget.room.id}')
        .stream(['id'])
        .order('created_at')
        .execute()
        .map((maps) => maps.map(Message.fromMap).toList())
        .listen((messages) {
          setState(() {
            _messages = messages;
          });
          for (final message in messages) {
            _fetchProfile(message.profileId);
          }
        });
    super.initState();
  }

  Future<void> _fetchProfile(String userId) async {
    if (_profileCache.containsKey(userId)) {
      return;
    }
    final res = await Supabase.instance.client
        .from('profiles')
        .select()
        .eq('id', userId)
        .single()
        .execute();
    final data = res.data;
    if (data != null) {
      setState(() {
        _profileCache[userId] = Profile.fromMap(data);
      });
    }
  }

  Widget _messageList() {
    if (_messages == null) {
      return const Center(
        child: Text('Loading...'),
      );
    }
    if (_messages!.isEmpty) {
      return const Center(
        child: Text('No one has started talking yet...'),
      );
    }
    final userId = Supabase.instance.client.auth.user()?.id;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      reverse: true,
      itemCount: _messages!.length,
      itemBuilder: ((context, index) {
        final message = _messages![index];
        return Align(
          alignment: userId == message.profileId
              ? Alignment.centerRight
              : Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ChatBubble(
              userId: userId,
              message: message,
              profileCache: _profileCache,
            ),
          ),
        );
      }),
    );
  }

  @override
  void dispose() {
    _messagesListener?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextButton(
          child: Text(
            widget.room.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
            ),
          ),
          onPressed: () {
            showDialog(
                context: context,
                builder: (context) {
                  return EditTitleDialog(
                    roomId: widget.room.id,
                  );
                });
          },
        ),
        actions: [
          TextButton(
              onPressed: () {
                showDialog(
                    context: context,
                    builder: (context) {
                      return InviteDialog(roomId: widget.room.id);
                    });
              },
              child: const Text('Invite')),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _messageList(),
            ),
            ChatForm(
              roomId: widget.room.id,
            ),
          ],
        ),
      ),
    );
  }
}

class EditTitleDialog extends StatelessWidget {
  EditTitleDialog({
    Key? key,
    required this.roomId,
  }) : super(key: key);

  final String roomId;
  final _titleController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: const Text('Change Room Title'),
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _titleController,
              ),
            ),
            TextButton(
                onPressed: () async {
                  final res = await Supabase.instance.client
                      .from('rooms')
                      .update({
                        'name': _titleController.text,
                      })
                      .eq('id', roomId)
                      .execute();
                  Navigator.of(context).pop();
                },
                child: const Text('Save'))
          ],
        ),
      ],
    );
  }
}

class InviteDialog extends StatefulWidget {
  const InviteDialog({
    Key? key,
    required this.roomId,
  }) : super(key: key);

  final String roomId;

  @override
  State<InviteDialog> createState() => _InviteDialogState();
}

class _InviteDialogState extends State<InviteDialog> {
  final _textController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: const Text('Invite a user'),
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _textController,
              ),
            ),
            TextButton(
              onPressed: () async {
                final username = _textController.text;
                final res = await Supabase.instance.client
                    .from('profiles')
                    .select()
                    .eq('username', username)
                    .single()
                    .execute();
                final data = res.data;
                final insertRes = await Supabase.instance.client
                    .from('room_participants')
                    .insert({
                  'room_id': widget.roomId,
                  'profile_id': data['id'],
                }).execute();
                Navigator.of(context).pop();
              },
              child: const Text('Invite'),
            ),
          ],
        ),
      ],
    );
  }
}

class ChatBubble extends StatelessWidget {
  const ChatBubble({
    Key? key,
    required this.userId,
    required this.message,
    required this.profileCache,
  }) : super(key: key);

  final String? userId;
  final Message message;
  final Map<String, Profile> profileCache;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(4),
      color: userId == message.profileId ? Colors.grey[300] : Colors.blue[200],
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              profileCache[message.profileId]?.username ?? 'loading...',
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 14,
              ),
            ),
            Text(
              message.content,
              style: const TextStyle(
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatForm extends StatefulWidget {
  const ChatForm({
    Key? key,
    required this.roomId,
  }) : super(key: key);

  final String roomId;

  @override
  State<ChatForm> createState() => _ChatFormState();
}

class _ChatFormState extends State<ChatForm> {
  final _textController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _textController,
              decoration: const InputDecoration(
                hintText: 'Type something',
                fillColor: Colors.white,
                filled: true,
                border: InputBorder.none,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              final text = _textController.text;
              if (text.isEmpty) {
                return;
              }
              _textController.clear();
              final res =
                  await Supabase.instance.client.from('messages').insert({
                'room_id': widget.roomId,
                'profile_id': Supabase.instance.client.auth.user()?.id,
                'content': text,
              }).execute();

              final error = res.error;
              if (error != null && mounted) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(error.message)));
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}

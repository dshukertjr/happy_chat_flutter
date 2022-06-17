import 'package:flutter/material.dart';
import 'package:happychat/models/message.dart';
import 'package:happychat/models/room.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatRoomPage extends StatelessWidget {
  const ChatRoomPage({
    Key? key,
    required this.room,
  }) : super(key: key);

  final Room room;

  @override
  Widget build(BuildContext context) {
    final userId = Supabase.instance.client.auth.user()?.id;
    return Scaffold(
      appBar: AppBar(
        title: Text(room.name),
      ),
      body: StreamBuilder<List<Message>>(
        stream: Supabase.instance.client
            .from('messages:room_id=eq.${room.id}')
            .stream(['id'])
            .order('created_at')
            .execute()
            .map((maps) => maps.map(Message.fromMap).toList()),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: Text('Loading...'),
            );
          }
          final messages = snapshot.data!;
          if (messages.isEmpty) {
            return const Center(
              child: Text('Noone has started talking yet...'),
            );
          }
          return ListView.builder(
            reverse: true,
            itemCount: messages.length,
            itemBuilder: ((context, index) {
              final message = messages[index];
              return Align(
                alignment: userId == message.profileId
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(4),
                    color: userId == message.profileId
                        ? Colors.grey[300]
                        : Colors.blue[200],
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        message.content,
                        style: const TextStyle(
                          color: Colors.black,
                        ),
                      ),
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

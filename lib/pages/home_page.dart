import 'package:flutter/material.dart';
import 'package:happychat/models/room.dart';
import 'package:happychat/pages/chat_room_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rooms'),
      ),
      body: StreamBuilder<List<Room>>(
        stream: Supabase.instance.client
            .from('rooms')
            .stream(['id'])
            .execute()
            .map((maps) => maps.map(Room.fromMap).toList()),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: Text('loading...'),
            );
          }
          final rooms = snapshot.data!;
          if (rooms.isEmpty) {
            return const Center(
              child: Text('Create a room'),
            );
          }
          return ListView.builder(
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];
              return ListTile(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) {
                      return ChatRoomPage(room: room);
                    }),
                  );
                },
                title: Text(room.name),
              );
            },
          );
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }
}

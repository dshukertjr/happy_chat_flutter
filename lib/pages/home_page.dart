import 'package:flutter/material.dart';
import 'package:happychat/models/room.dart';
import 'package:happychat/pages/chat_room_page.dart';
import 'package:happychat/pages/register_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends SupabaseAuthState<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rooms'),
        actions: [
          TextButton(
              onPressed: () {
                Supabase.instance.client.auth.signOut();
              },
              child: const Text('signout')),
        ],
      ),
      body: StreamBuilder<List<Room>>(
        stream: Supabase.instance.client
            .from('rooms')
            .stream(['id'])
            .order('created_at')
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
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final res =
              await Supabase.instance.client.rpc('create_room').execute();
          final data = res.data;
          final error = res.error;
          if (error != null) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(error.message)));
            return;
          }
          final room = Room.fromMap(data);

          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) {
              return ChatRoomPage(room: room);
            }),
          );
        },
        child: const Icon(Icons.add),
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

  @override
  void onAuthenticated(Session session) {
    // TODO: implement onAuthenticated
  }

  @override
  void onErrorAuthenticating(String message) {
    // TODO: implement onErrorAuthenticating
  }

  @override
  void onPasswordRecovery(Session session) {
    // TODO: implement onPasswordRecovery
  }

  @override
  void onUnauthenticated() {
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const RegisterPage()),
        (route) => false);
  }
}

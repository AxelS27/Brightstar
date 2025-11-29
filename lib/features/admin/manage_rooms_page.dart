import 'package:flutter/material.dart';
import '../../../core/config/api_config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ManageRoomsPage extends StatefulWidget {
  const ManageRoomsPage({super.key});

  @override
  State<ManageRoomsPage> createState() => _ManageRoomsPageState();
}

class _ManageRoomsPageState extends State<ManageRoomsPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController();
  List<Map<String, dynamic>> _rooms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    try {
      final url = Uri.parse("${ApiConfig.baseUrl}/get_all_rooms.php");
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['status'] == 'success') {
          setState(() {
            _rooms = List<Map<String, dynamic>>.from(data['data']);
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _rooms = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _createRoom() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Room name is required")));
      return;
    }
    final url = Uri.parse("${ApiConfig.baseUrl}/create_room.php");
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'name': _nameController.text,
          'capacity': int.tryParse(_capacityController.text) ?? 0,
        }),
      );
      final data = jsonDecode(response.body);
      if (data['status'] == 'success') {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Room created")));
        _nameController.clear();
        _capacityController.clear();
        _loadRooms();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(data['message'] ?? 'Failed')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Network error")));
    }
  }

  Future<void> _editRoom(Map<String, dynamic> room) async {
    _nameController.text = room['name'];
    _capacityController.text = room['capacity'].toString();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Room"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Room Name"),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _capacityController,
              decoration: const InputDecoration(labelText: "Capacity"),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final url = Uri.parse("${ApiConfig.baseUrl}/update_room.php");
              try {
                final res = await http.post(
                  url,
                  headers: {"Content-Type": "application/json"},
                  body: jsonEncode({
                    'id': room['id'],
                    'name': _nameController.text,
                    'capacity': int.tryParse(_capacityController.text) ?? 0,
                  }),
                );
                final data = jsonDecode(res.body);
                if (data['status'] == 'success') {
                  _loadRooms();
                  Navigator.pop(context);
                }
              } catch (e) {}
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteRoom(String id) async {
    bool confirm =
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Delete Room"),
            content: const Text("Are you sure?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("No"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Yes"),
              ),
            ],
          ),
        ) ??
        false;
    if (confirm) {
      final url = Uri.parse("${ApiConfig.baseUrl}/delete_room.php");
      try {
        await http.post(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({'id': id}),
        );
        _loadRooms();
      } catch (e) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Rooms")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _rooms.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Card(
                    margin: const EdgeInsets.all(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          TextField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: "Room Name",
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _capacityController,
                            decoration: const InputDecoration(
                              labelText: "Capacity",
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _createRoom,
                            child: const Text("Create Room"),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                final room = _rooms[index - 1];
                return ListTile(
                  title: Text(room['name']),
                  subtitle: Text("Capacity: ${room['capacity']}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _editRoom(room),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteRoom(room['id']),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

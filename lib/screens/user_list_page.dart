import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import 'create_user_page.dart';

class UserListPage extends StatefulWidget {
  const UserListPage({super.key});

  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  final _service = UserService();
  late Future<List<UserModel>> _futureUsers;

  @override
  void initState() {
    super.initState();
    _futureUsers = _service.getUsers();
  }

  void _refresh() {
    setState(() => _futureUsers = _service.getUsers());
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? Colors.red : Colors.green,
    ));
  }

  Future<void> _delete(UserModel u) async {
    try {
      await _service.deleteUser(u.id);
      _snack('${u.fullName} berhasil dihapus (DELETE)');
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''), error: true);
    }
  }

  Future<void> _edit(UserModel u) async {
    final nameCtrl = TextEditingController(text: u.fullName);
    final jobCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Update User (PUT)'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama')),
          TextField(controller: jobCtrl, decoration: const InputDecoration(labelText: 'Pekerjaan')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Simpan')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final res = await _service.updateUser(u.id, nameCtrl.text, jobCtrl.text);
      _snack('Update berhasil pada ${res['updatedAt']}');
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar User'),
        actions: [IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh))],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateUserPage()),
        ),
      ),
      body: FutureBuilder<List<UserModel>>(
        future: _futureUsers,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Text(
                    snap.error.toString().replaceFirst('Exception: ', ''),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(onPressed: _refresh, child: const Text('Coba Lagi')),
                ]),
              ),
            );
          }
          final users = snap.data ?? [];
          if (users.isEmpty) return const Center(child: Text('Data kosong'));
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (_, i) {
              final u = users[i];
              return ListTile(
                leading: ClipOval(
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: Image.network(
                      u.avatar,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        final initial = u.firstName.isNotEmpty ? u.firstName[0] : '?';
                        return Container(
                          color: Colors.indigo.shade100,
                          alignment: Alignment.center,
                          child: Text(
                            initial.toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                title: Text(u.fullName),
                subtitle: Text(u.email),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(icon: const Icon(Icons.edit), onPressed: () => _edit(u)),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _delete(u),
                  ),
                ]),
              );
            },
          );
        },
      ),
    );
  }
}
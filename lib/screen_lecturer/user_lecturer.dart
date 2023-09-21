import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../gobal/drawerbar_lecturer.dart'; // Custom drawer imported

class UserLecturer extends StatefulWidget {
  @override
  _UserLecturerState createState() => _UserLecturerState();
}

class _UserLecturerState extends State<UserLecturer> {
  late final String userId; // Declare the userId variable

  @override
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser!.uid; // Initialize userId
  }

  Future<bool?> _showDeleteConfirmationDialog(
      BuildContext context, String docId) async {
    // Show a dialog box to confirm deletion
    bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('ยืนยันการลบ'),
          content: const Text('คุณต้องการลบรายวิชานี้ใช่หรือไม่?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('ยกเลิก'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('ลบ'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('subjects')
          .doc(docId)
          .delete(); // Delete only the selected subject
    }
  }

  Future<void> _addSubject() async {
    TextEditingController codeController = TextEditingController();
    TextEditingController nameController = TextEditingController();
    TextEditingController groupController = TextEditingController();

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('เพิ่มรายวิชาใหม่'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: codeController,
                decoration: const InputDecoration(labelText: 'รหัสวิชา'),
              ),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'ชื่อรายวิชา'),
              ),
              TextField(
                controller: groupController,
                decoration: const InputDecoration(labelText: 'หมู่เรียน'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ยกเลิก'),
            ),
            TextButton(
              onPressed: () async {
                if (codeController.text.isNotEmpty &&
                    nameController.text.isNotEmpty &&
                    groupController.text.isNotEmpty) {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .collection('subjects')
                      .add({
                    'code': codeController.text.trim(),
                    'name': nameController.text.trim(),
                    'group': groupController.text.trim(),
                  });
                  Navigator.of(context).pop();
                }
              },
              child: const Text('เพิ่ม'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Lecturer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addSubject,
          ),
        ],
      ),
      drawer: DrawerbarLecturer(),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('subjects')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const CircularProgressIndicator();
          }
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              DocumentSnapshot doc = snapshot.data!.docs[index];
              Map<String, dynamic> subject = doc.data() as Map<String, dynamic>;
              return Card(
                margin:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(15), // Less rounded corners
                ),
                child: ListTile(
                  tileColor: Colors.white,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  title: Text(
                    subject['name'] ?? '',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  subtitle: Text(
                    'Code: ${subject['code']}, Group: ${subject['group']}',
                    style: TextStyle(
                      color: Colors.grey[800],
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    color: Colors.red,
                    onPressed: () =>
                        _showDeleteConfirmationDialog(context, doc.id),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

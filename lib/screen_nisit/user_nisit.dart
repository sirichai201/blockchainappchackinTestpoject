import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../gobal/drawerbar_nisit.dart';
import 'subject_detail_nisit.dart';

class UserNisit extends StatefulWidget {
  @override
  _UserNisitState createState() => _UserNisitState();
}

class _UserNisitState extends State<UserNisit> {
  final List<String> subjects = [];
  final TextEditingController _codeController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late String currentUserUid;

  @override
  void initState() {
    super.initState();
    currentUserUid = _auth.currentUser!.uid;
    fetchSubjects();
  }

//สร้างฟังก์ชันในการลบวิชา:
  Future<void> _deleteSubject(String docId) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserUid)
        .collection('enrolledSubjects')
        .doc(docId)
        .delete();

    // อัพเดท UI
    setState(() {
      subjects.removeWhere((subject) => subject == docId);
    });
  }

  /// ฟังก์ชั่นสำหรับดึงวิชาที่นิสิตเข้าร่วม
  Future<void> fetchSubjects() async {
    var userSubjects = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserUid)
        .collection('enrolledSubjects')
        .get();

    List<String> fetchedSubjects = [];
    for (var doc in userSubjects.docs) {
      fetchedSubjects.add(doc.data()['name'] as String);
    }

    setState(() {
      subjects.addAll(fetchedSubjects);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("UserNisit"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addSubject,
          ),
        ],
      ),
      drawer: const DrawerBarNisit(),
      body: _buildSubjectList(),
    );
  }

  Widget _buildSubjectList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserUid)
          .collection('enrolledSubjects')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            DocumentSnapshot doc = snapshot.data!.docs[index];
            Map<String, dynamic> subject = doc.data() as Map<String, dynamic>;
            return _buildSubjectTile(subject, doc.id, context);
          },
        );
      },
    );
  }

  Widget _buildSubjectTile(
      Map<String, dynamic> subject, String docId, BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SubjectDetailNisit(
                  userId: currentUserUid,
                  docId: docId,
                  subjectName: subject['name'], // ส่งชื่อวิชา
                  subjectCode: subject['code'], // ส่งรหัสวิชา
                  subjectGroup: subject['group'], // ส่งหมู่เรียน
                  uidTeacher: subject['uidTeacher']),
            ),
          );
        },
        title: Text(
          subject['name'] ?? '',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Text(
          'Code: ${subject['code']}, Group: ${subject['group']},',
          style: TextStyle(color: Colors.grey[800]),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete),
          color: Colors.red,
          onPressed: () =>
              _showDeleteConfirmationDialog(context, docId, subject['name']),
        ),
      ),
    );
  }

  Future<bool?> _showDeleteConfirmationDialog(
      BuildContext context, String subjectId, String? subjectName) async {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('ยืนยัน'),
          content: Text('คุณต้องการลบวิชา $subjectId, $subjectName หรือไม่?'),
          actions: <Widget>[
            TextButton(
              child: const Text('ไม่'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('ใช่'),
              onPressed: () {
                _deleteSubject(subjectId);
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
  }

  void _addSubject() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('กรอกรหัสเพื่อเข้าร่วมวิชา'),
          content: TextField(
            controller: _codeController,
            decoration: InputDecoration(hintText: "กรอกรหัส"),
          ),
          actions: [
            TextButton(
              child: const Text('ยกเลิก'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('เข้าร่วม'),
              onPressed: _processSubjectJoining,
            ),
          ],
        );
      },
    );
  }

  Future<void> _processSubjectJoining() async {
    String code = _codeController.text;
    var query = await FirebaseFirestore.instance
        .collectionGroup('subjects')
        .where('inviteCode', isEqualTo: code)
        .get();

    var userData = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserUid)
        .get();

    String currentUserName = userData.data()?['Username'];
    String currentUserEmail = userData.data()?['email'];

    if (query.docs.isNotEmpty) {
      var subjectData = query.docs.first.data();
      String subjectName = subjectData['name'];
      bool isApproved = subjectData['students'] != null &&
          subjectData['students'].contains(currentUserUid);

      if (isApproved) {
        setState(() {
          subjects.add(subjectName);
        });
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserUid)
            .collection('subjects')
            .doc(subjectName)
            .set(subjectData);
      } else {
        await FirebaseFirestore.instance
            .doc(query.docs.first.reference.path)
            .update({
          'pendingStudents': FieldValue.arrayUnion([
            {
              'uid': currentUserUid,
              'name':
                  currentUserName, // ค่านี้ควรมาจากตัวแปรที่เก็บชื่อของนิสิต
              'email':
                  currentUserEmail, // ค่านี้ควรมาจากตัวแปรที่เก็บอีเมลของนิสิต
            }
          ])
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("รอคำอนุมัติ"),
        ));
        Navigator.of(context).pop();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("รหัสไม่ถูกต้อง!"),
      ));
      Navigator.of(context).pop();
    }
  }
}

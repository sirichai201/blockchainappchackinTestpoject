import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SubjectDetail extends StatefulWidget {
  final String userId;
  final String docId;
  SubjectDetail({required this.userId, required this.docId, Key? key})
      : super(key: key);

  @override
  _SubjectDetailState createState() => _SubjectDetailState();
}

class _SubjectDetailState extends State<SubjectDetail> {
  final CollectionReference subjects =
      FirebaseFirestore.instance.collection('users');

  Future<void> approveStudent(String studentUid) async {
    DocumentSnapshot subjectDoc = await subjects
        .doc(widget.userId)
        .collection('subjects')
        .doc(widget.docId)
        .get();

    Map<String, dynamic> subject = subjectDoc.data() as Map<String, dynamic>;

    await subjects
        .doc(widget.userId)
        .collection('subjects')
        .doc(widget.docId)
        .update({
      'students': FieldValue.arrayUnion([studentUid]),
      'pendingStudents': FieldValue.arrayRemove([studentUid])
    });

    // ตรงนี้คือการเพิ่มวิชานั้นๆ ในส่วนของนิสิต
    await subjects
        .doc(studentUid)
        .collection('enrolledSubjects')
        .doc(widget.docId)
        .set({
      'name': subject['name'], // ดึงข้อมูลชื่อวิชาจาก subject
      'code': subject['code'], // ดึงรหัสวิชาจาก subject
      'group': subject['group'], // ดึงกลุ่มวิชาจาก subject
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('ได้ยืนยันเรียบร้อยแล้ว')));

    setState(() {});
  }

  Future<void> rejectStudent(String studentUid) async {
    await subjects
        .doc(widget.userId)
        .collection('subjects')
        .doc(widget.docId)
        .update({
      'pendingStudents': FieldValue.arrayRemove([studentUid])
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('ลบเรียบร้อยแล้ว')));

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<DocumentSnapshot>(
          future: subjects
              .doc(widget.userId)
              .collection('subjects')
              .doc(widget.docId)
              .get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text("Loading...");
            }

            if (!snapshot.hasData || snapshot.data == null) {
              return Text("Error loading data");
            }

            Map<String, dynamic> subject =
                snapshot.data!.data() as Map<String, dynamic>;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject['name'] ?? '',
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(height: 4),
                Text(
                  'Code: ${subject['code']}, Group: ${subject['group']}',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            );
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<DocumentSnapshot>(
          future: subjects
              .doc(widget.userId)
              .collection('subjects')
              .doc(widget.docId)
              .get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }

            if (!snapshot.hasData || snapshot.data == null) {
              return Text("Error loading data");
            }

            Map<String, dynamic> subject =
                snapshot.data!.data() as Map<String, dynamic>;

            List<dynamic> pendingStudents = subject['pendingStudents'] ?? [];
            List<dynamic> approvedStudents = subject['students'] ?? [];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Invite Code: ${subject['inviteCode']}'),
                SizedBox(height: 16.0),
                Text('Pending Students:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Expanded(
                  child: pendingStudents.isEmpty
                      ? Text('ไม่มีนิสิตที่รอการอนุมัติ')
                      : ListView.builder(
                          itemCount: pendingStudents.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              title: Text(pendingStudents[index]),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon:
                                        Icon(Icons.check, color: Colors.green),
                                    onPressed: () =>
                                        approveStudent(pendingStudents[index]),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.close, color: Colors.red),
                                    onPressed: () =>
                                        rejectStudent(pendingStudents[index]),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                SizedBox(height: 16.0),
                Text('Approved Students:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Expanded(
                  child: approvedStudents.isEmpty
                      ? Text('ไม่มีนิสิตที่ได้รับการอนุมัติ')
                      : ListView.builder(
                          itemCount: approvedStudents.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              title: Text(approvedStudents[index]),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

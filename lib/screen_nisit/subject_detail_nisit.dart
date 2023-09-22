import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SubjectDetailNisit extends StatefulWidget {
  final String userId;
  final String docId;

  const SubjectDetailNisit({required this.userId, required this.docId});

  @override
  _SubjectDetailNisitState createState() => _SubjectDetailNisitState();
}

class _SubjectDetailNisitState extends State<SubjectDetailNisit> {
  Map<String, dynamic>? subjectDetails;

  @override
  void initState() {
    super.initState();
    fetchSubjectDetails();
  }

  fetchSubjectDetails() async {
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('enrolledSubjects')
        .doc(widget.docId)
        .get();
    setState(() {
      subjectDetails = doc.data() as Map<String, dynamic>;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (subjectDetails == null) {
      return Scaffold(body: const CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
            '${subjectDetails!['name']} (${subjectDetails!['code']}) Group: ${subjectDetails!['group']}'),
      ),
      body: Center(
        child:
            Text('รายละเอียดวิชา'), // คุณสามารถเพิ่มเติมเนื้อหาต่าง ๆ ในที่นี้
      ),
    );
  }
}

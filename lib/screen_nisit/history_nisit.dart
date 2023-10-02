import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'user_nisit.dart';

class HistoryNisit extends StatefulWidget {
  @override
  _HistoryNisitState createState() => _HistoryNisitState();
}

class _HistoryNisitState extends State<HistoryNisit> {
  final userDocId = FirebaseAuth.instance.currentUser!.uid;
  List<Map<String, dynamic>> subjectsList = [];
  late DateTime selectedDate;

  String selectedSubject = '';
  final subjectController = TextEditingController();
  List<Map<String, dynamic>> attendanceList = []; // For storing attendance data
  @override
  void initState() {
    super.initState();
    loadSubjects();
    selectedDate = DateTime.now();
  }

  void loadSubjects() async {
    final subjectsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userDocId)
        .collection('enrolledSubjects');
    final snapshot = await subjectsRef.get();
    subjectsList = snapshot.docs
        .map((doc) => {'docId': doc.id, ...doc.data() as Map<String, dynamic>})
        .toList();

    if (subjectsList.isNotEmpty) {
      setState(() {
        selectedSubject = subjectsList[0]['name'] ?? '';
      });
    }
  }

  void loadAttendanceSchedules(String selectedenrolledSubjects) async {
    String formattedSelectedDate = DateFormat('yyyy-MM-dd').format(
        selectedDate); // Change the format to match your document ID format.

    final attendanceDocRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userDocId)
        .collection('enrolledSubjects')
        .doc(selectedenrolledSubjects)
        .collection('attendanceSchedulesRecords')
        .doc(formattedSelectedDate);

    final docSnapshot = await attendanceDocRef.get();
    if (!docSnapshot.exists) {
      print('No attendance data found for $formattedSelectedDate');
      setState(() {
        attendanceList = [];
      });
      return;
    }
    final data = docSnapshot.data() as Map<String, dynamic>;
    final studentsCheckedRecords =
        (data['studentsCheckedRecords'] as List<dynamic>?) ?? [];

    // Use setState to rebuild the widget with the new attendance list.
    setState(() {
      attendanceList = studentsCheckedRecords.map((student) {
        final studentMap = student as Map<String, dynamic>;
        final status = studentMap['status'] ?? 'unknown';
        final time = studentMap['time'];
        final studentId = studentMap['studentId'] ?? 'unknown student';
        final name = studentMap['name'] ?? 'unknown name';
        return {
          'status': status,
          'time': time,
          'studentId': studentId,
          'name': name,
        };
      }).toList();

      print('Loaded ${attendanceList.length} attendances');
      print('Attendance List: $attendanceList');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (context) => UserNisit()));
            }),
        title: const Text('ประวัติการเข้าเรียนนิสิต'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              DropdownButton<String>(
                value: selectedSubject.isNotEmpty ? selectedSubject : null,
                items: subjectsList.map((subjectMap) {
                  final subjectName = subjectMap['name'];
                  return DropdownMenuItem<String>(
                    value: subjectName,
                    child: Row(
                      children: [
                        Icon(Icons.book), // ใส่ Icon ที่คุณต้องการ
                        SizedBox(
                            width: 40), // สร้างระยะห่างระหว่าง Icon และ Text
                        Text(subjectName),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedSubject = newValue ?? '';
                  });
                },
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: Container(
                  margin: const EdgeInsets.only(
                      right: 5.0), // เพิ่มระยะห่างด้านขวาของไอคอน
                  child: const Icon(Icons.date_range),
                ),
                title: TextButton(
                  onPressed: () async {
                    final DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2101),
                    );
                    if (pickedDate != null && pickedDate != selectedDate)
                      setState(() {
                        selectedDate = pickedDate;
                      });
                  },
                  child: Text(
                    "วันที่เลือก: ${selectedDate.toLocal().toString().split(' ')[0]}",
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (subjectsList.isNotEmpty) {
                    final selectedSubjectMap = subjectsList.firstWhere(
                        (subjectMap) => subjectMap['name'] == selectedSubject,
                        orElse: () => subjectsList[0]);
                    final selectedSubjectDocId = selectedSubjectMap['docId'];
                    loadAttendanceSchedules(selectedSubjectDocId);
                  }
                },
                child: const Text('ยืนยัน'),
              ),
              const SizedBox(height: 20),
              // Count summaries

              ...[
                if (attendanceList.isEmpty)
                  Center(
                      child: Text(
                          'ไม่มีข้อมูลนิสิตในวันที่ ${selectedDate.toLocal().toString().split(' ')[0]}')),
                ...attendanceList.map((attendance) {
                  print(
                      'Building Card for ${attendance['studentId'] ?? 'unknown student'}');
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                  'ชื่อ: ${attendance['name'] ?? 'ไม่มีข้อมูล'}'),
                              Text(
                                  'รหัสนิสิต: ${attendance['studentId'] ?? 'ไม่มีข้อมูล'}'),
                            ],
                          ),
                          const SizedBox(height: 8.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                  'สถานะ: ${attendance['status'] ?? 'ไม่มีข้อมูล'}'),
                            ],
                          ),
                          const SizedBox(
                            height: 8.0,
                            width: 20,
                          ),
                          Text(
                              'เวลา: ${_formatTimestamp(attendance['time'] as Timestamp)}'),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final datetime = timestamp.toDate();
    final formatter = DateFormat('yyyy-MM-dd HH:mm'); // adjust format as needed
    return formatter.format(datetime);
  }
}

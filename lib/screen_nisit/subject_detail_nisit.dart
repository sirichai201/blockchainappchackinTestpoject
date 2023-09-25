import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:location/location.dart';

class SubjectDetailNisit extends StatefulWidget {
  final String userId;
  final String docId;
  final String subjectName;
  final String subjectCode;
  final String subjectGroup;

  const SubjectDetailNisit({
    required this.userId,
    required this.docId,
    required this.subjectName,
    required this.subjectCode,
    required this.subjectGroup,
    Key? key,
  }) : super(key: key);

  @override
  _SubjectDetailNisitState createState() => _SubjectDetailNisitState();
}

class _SubjectDetailNisitState extends State<SubjectDetailNisit> {
  String scheduleId = ''; // ประกาศตัวแปรที่นี่
  late final String currentUserUid;
  late final String subjectDocId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late User? currentUser;
  LocationData? _locationData;

  // Constants for the university location and allowed distance
  double universityLat = 17.272961;
  double universityLong = 104.131919;
  double allowedDistance = 100.0; // in meters

  @override
  void initState() {
    super.initState();
    currentUserUid = widget.userId;
    subjectDocId = widget.docId;
    getCurrentUser();
    _getLocation(); // Call this method to get the current location.
  }

  Future<void> getCurrentUser() async {
    currentUser = FirebaseAuth.instance.currentUser;
  }

  // Method to get the current location of the user.
  Future<void> _getLocation() async {
    final location = Location();
    final LocationData locationData = await location.getLocation();
    setState(() {
      _locationData = locationData;
    });
    print(
        'LocationData: ${_locationData?.latitude}, ${_locationData?.longitude}');
  }

  // Method to check if the user is within the allowed distance from the university.
  bool isWithinUniversity(LocationData? locationData) {
    if (locationData == null) return false;
    const earthRadius = 6371.0; // in km
    double toRadian(double degree) => degree * (pi / 180.0);

    double deltaLat = toRadian(locationData.latitude! - universityLat);
    double deltaLong = toRadian(locationData.longitude! - universityLong);
    double a = sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(toRadian(universityLat)) *
            cos(toRadian(locationData.latitude!)) *
            sin(deltaLong / 2) *
            sin(deltaLong / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    double distance = earthRadius * c; // in km
    print('Is within university: ${distance <= (allowedDistance / 1000.0)}');
    return distance <= (allowedDistance / 1000.0); // allowedDistance in m
  }

  Future<void> checkIn(String status) async {
    if (!isWithinUniversity(_locationData)) {
      print('User is not within the allowed check-in area.');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('You are not within the allowed check-in area.'),
      ));
      return;
    }
    final subjectsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('subjects');
    final subjectRef = subjectsRef.doc(widget.docId);
    final attendanceSchedulesRef = subjectRef.collection('attendanceSchedules');
    final String scheduleId = DateTime.now().toIso8601String().split('T')[0];
    this.scheduleId = scheduleId; // กำหนดค่าที่นี่
    final attendanceScheduleRef = attendanceSchedulesRef.doc(scheduleId);

    try {
      print('Check-in Successful for $currentUserUid at $scheduleId');
      final DocumentSnapshot scheduleDoc = await attendanceScheduleRef.get();
      if (!scheduleDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('No schedule available for today.'),
        ));
        return;
      }

      final Map<String, dynamic> scheduleData =
          scheduleDoc.data() as Map<String, dynamic>;
      final DateTime startDate = scheduleData['startDate'].toDate();
      final DateTime endDate = scheduleData['endDate'].toDate();
      final DateTime now = DateTime.now();

      if (now.isBefore(startDate) || now.isAfter(endDate)) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Not within check-in time range.'),
        ));
        return;
      }

      final userDoc =
          await _firestore.collection('users').doc(currentUserUid).get();
      final username = userDoc.get('username') ?? "";
      final email = userDoc.get('email') ?? "";
      final studentId = userDoc.get('studentId') ?? "";

      final newCheckIn = {
        'time': DateTime.now(),
        'uid': currentUserUid,
        'name': username,
        'email': email,
        'studentId': studentId,
        'status': status,
      };

      await attendanceScheduleRef.update({
        'studentsChecked': FieldValue.arrayUnion([newCheckIn])
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Check-in Successful!'),
      ));
    } catch (e) {
      print('Check-in Failed: $e');
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Check-in Failed!'),
      ));
    }
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // กำหนดขนาดขั้นต่ำของ Column
        children: [
          Text(widget.subjectName, style: TextStyle(fontSize: 18)),
          SizedBox(height: 4),
          Text(
            'Code: ${widget.subjectCode}, Group: ${widget.subjectGroup}',
            style: TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () => checkIn('attended'),
                child: Text('มาเรียน'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () => checkIn('leave'),
                child: Text('ลา'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Align(
                alignment: Alignment.center,
                child: ElevatedButton(
                  onPressed: _getLocation,
                  child: Text('Get Location'),
                ),
              ),
            ),
            if (_locationData != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Latitude: ${_locationData!.latitude}, Longitude: ${_locationData!.longitude}',
                ),
              ),
            StreamBuilder<DocumentSnapshot>(
              stream: _firestore
                  .collection('users')
                  .doc(currentUserUid)
                  .collection('subjects')
                  .doc(subjectDocId)
                  .collection('attendanceSchedules')
                  .doc(DateTime.now().toIso8601String().split('T')[0])
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  print('StreamBuilder waiting for data...');
                  return CircularProgressIndicator();
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  print('No data available for $scheduleId.');
                  return Text('No data available.');
                }

                final data = snapshot.data!.data() as Map<String, dynamic>;
                final List<dynamic>? studentsChecked = data['studentsChecked'];

                if (studentsChecked == null || studentsChecked.isEmpty) {
                  print('No check-ins yet for $scheduleId.');
                  return Text('No check-ins yet.');
                }
                print(
                    'Rendering ${studentsChecked.length} check-ins for $scheduleId.');
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: studentsChecked.length,
                  itemBuilder: (context, index) {
                    final checkIn =
                        studentsChecked[index] as Map<String, dynamic>;
                    final DateTime time = checkIn['time'].toDate();
                    return ListTile(
                      title: Text(
                          '${checkIn['name']} - ${time.toString()} - ${checkIn['status']}'),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

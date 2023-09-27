// ignore_for_file: unnecessary_type_check

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:location/location.dart';
import 'package:intl/intl.dart'; // สำหรับใช้งาน DateFormat
import 'dart:convert'; // ให้เพิ่ม import นี้ที่ส่วนบนของไฟล์
import 'package:http/http.dart'; // ควรมีการ import นี้ด้วย เพราะ web3dart ใช้งาน http package
import 'package:web3dart/web3dart.dart' as web3;

class SubjectDetailNisit extends StatefulWidget {
  final String userId;
  final String docId;
  final String subjectName;
  final String subjectCode;
  final String subjectGroup;
  final String uidTeacher;

  const SubjectDetailNisit({
    required this.userId,
    required this.docId,
    required this.subjectName,
    required this.subjectCode,
    required this.subjectGroup,
    required this.uidTeacher,
    Key? key,
  }) : super(key: key);

  @override
  _SubjectDetailNisitState createState() => _SubjectDetailNisitState();
}

class _SubjectDetailNisitState extends State<SubjectDetailNisit> {
  double rewardAmount = 0.2;
  BigInt? balanceInt;
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
    _getLocation();

    // Call this method to get the current location.
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
    try {
      if (!isWithinUniversity(_locationData)) {
        print('User is not within the allowed check-in area.');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('You are not within the allowed check-in area.'),
        ));
        print(
            'LocationData: ${_locationData?.latitude}, ${_locationData?.longitude}');
        print('User is not within the allowed check-in area.');
        print('User has already checked in.');

        return;
      }
      // ที่อยู่ของ Document ใน Firestore
      final attendanceScheduleRef = _firestore
          .collection('users')
          .doc(widget.uidTeacher)
          .collection('subjects')
          .doc(subjectDocId)
          .collection('attendanceSchedules')
          .doc(DateTime.now().toLocal().toString().split(' ')[0]);

      final DocumentSnapshot scheduleDoc = await attendanceScheduleRef.get();

      if (!scheduleDoc.exists) {
        throw Exception('Document does not exist at the expected path.');
      }

      final Map<String, dynamic> scheduleData =
          scheduleDoc.data() as Map<String, dynamic>;

      // ตรวจสอบว่าผู้ใช้ได้เช็คอินแล้วหรือยัง
      final List<dynamic>? studentsChecked = scheduleData['studentsChecked'];
      if (studentsChecked != null) {
        for (var student in studentsChecked) {
          if (student['uid'] == currentUserUid) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('คุณได้เช็คอินแล้ว!'),
            ));
            return;
          }
        }
      }

      // หากยังไม่ได้เช็คอิน ให้ทำการเช็คอิน
      final DateTime now = DateTime.now().toLocal();
      final DateTime startDate = scheduleData['startDate'].toDate();
      final DateTime endDate = scheduleData['endDate'].toDate();

      if (now.isBefore(startDate) || now.isAfter(endDate)) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Not within check-in time range.'),
        ));
        return;
      }

      final userDoc =
          await _firestore.collection('users').doc(currentUserUid).get();
      final username = userDoc.get('Username') ?? "";
      final email = userDoc.get('email') ?? "";
      final studentId = userDoc.get('studentId') ?? "";

      final client = web3.Web3Client('http://10.0.2.2:8545', Client());

      final contractAbiList = [
        {
          "anonymous": false,
          "inputs": [
            {
              "indexed": true,
              "internalType": "address",
              "name": "student",
              "type": "address"
            },
            {
              "indexed": false,
              "internalType": "uint256",
              "name": "date",
              "type": "uint256"
            },
            {
              "indexed": false,
              "internalType": "uint256",
              "name": "rewardAmount",
              "type": "uint256"
            }
          ],
          "name": "CheckedIn",
          "type": "event"
        },
        {
          "anonymous": false,
          "inputs": [
            {
              "indexed": true,
              "internalType": "address",
              "name": "student",
              "type": "address"
            },
            {
              "indexed": false,
              "internalType": "uint256",
              "name": "amount",
              "type": "uint256"
            }
          ],
          "name": "SpentCoin",
          "type": "event"
        },
        {
          "inputs": [
            {"internalType": "address", "name": "", "type": "address"},
            {"internalType": "uint256", "name": "", "type": "uint256"}
          ],
          "name": "attendanceRecords",
          "outputs": [
            {"internalType": "bool", "name": "", "type": "bool"}
          ],
          "stateMutability": "view",
          "type": "function"
        },
        {
          "inputs": [
            {"internalType": "address", "name": "", "type": "address"}
          ],
          "name": "balances",
          "outputs": [
            {"internalType": "uint256", "name": "", "type": "uint256"}
          ],
          "stateMutability": "view",
          "type": "function"
        },
        {
          "inputs": [
            {"internalType": "uint256", "name": "date", "type": "uint256"},
            {
              "internalType": "uint256",
              "name": "rewardAmount",
              "type": "uint256"
            }
          ],
          "name": "checkAttendanceAndReward",
          "outputs": [],
          "stateMutability": "nonpayable",
          "type": "function"
        },
        {
          "inputs": [
            {"internalType": "address", "name": "student", "type": "address"},
            {"internalType": "uint256", "name": "date", "type": "uint256"}
          ],
          "name": "isAttended",
          "outputs": [
            {"internalType": "bool", "name": "", "type": "bool"}
          ],
          "stateMutability": "view",
          "type": "function"
        },
        {
          "inputs": [],
          "name": "getBalance",
          "outputs": [
            {"internalType": "uint256", "name": "", "type": "uint256"}
          ],
          "stateMutability": "view",
          "type": "function"
        },
        {
          "inputs": [
            {"internalType": "uint256", "name": "amount", "type": "uint256"}
          ],
          "name": "spendCoin",
          "outputs": [],
          "stateMutability": "nonpayable",
          "type": "function"
        }
      ];
      final contractAddress = web3.EthereumAddress.fromHex(
          '0x2eFD35Fc72B4d90E135e6b3E0428f911e73C12E1');

      final credentials = await client.credentialsFromPrivateKey(
          '7868d1e4d98b02b48d352e615b8c4abcb49d8cacc37c1f57ed263e69825a671f');
      final contractAbi = web3.ContractAbi.fromJson(
          jsonEncode(contractAbiList), 'AttendanceContract');
      final contract = web3.DeployedContract(contractAbi, contractAddress);

      final dateBigInt = BigInt.from(DateTime.now().millisecondsSinceEpoch);

      final rewardAmount = 0.02; // จำนวนเหรียญที่คุณต้องการให้นักเรียนได้รับ
      final checkRewardFunction = contract.function('checkAttendanceAndReward');
      print(checkRewardFunction);
      final getBalanceFunction = contract.function('getBalance');
      print(getBalanceFunction);
      // ignore: unused_local_variable
      final response = await client.sendTransaction(
        credentials,
        web3.Transaction.callContract(
          contract: contract,
          function: checkRewardFunction,
          parameters: [
            dateBigInt,
            BigInt.from((rewardAmount * 1e18)
                .toInt()) // ใช้ BigInt ที่แปลงจาก 0.2 Ether ไปเป็น Wei แล้ว
          ],
        ),
      );
      final parameters = [
        dateBigInt,
        BigInt.from((rewardAmount * 1e18)
            .toInt()) // ใช้ BigInt ที่แปลงจาก 0.2 Ether ไปเป็น Wei แล้ว
      ];
      print(parameters);

      print(contract);
      print(dateBigInt); // แสดงค่าของ dateBigInt
      print(rewardAmount * 1e18); // แสดงค่าของ rewardAmount ที่ถูกแปลงเป็น Wei
      print(response);
      print(status);
      print(credentials);
      print(client);
      print(contractAbi);
      print(contractAddress);
      print(credentials);
      final balance = await client
          .call(contract: contract, function: getBalanceFunction, params: []);
      if (balance is List && balance.isNotEmpty && balance[0] is BigInt) {
        final balanceInt = balance[0] as BigInt;
        print('Balance: $balanceInt');
      } else {
        print(
            'Error: Unable to fetch balance or balance is not of type BigInt');
      }

      final newCheckIn = {
        'time': DateTime.now(),
        'uid': currentUserUid,
        'name': username,
        'email': email,
        'studentId': studentId,
        'status': status,
        'rewardAmount': rewardAmount,
        'balanceInt': balanceInt,
      };

      await attendanceScheduleRef.update({
        'studentsChecked': FieldValue.arrayUnion([newCheckIn])
      });
      print('Updated Firestore with new check-in data.');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(balanceInt != null
              ? 'Your new balance is ${balanceInt! / BigInt.from(1e18)} tokens.'
              : 'However, we could not retrieve your new balance.'),
        ),
      );
    } catch (e) {
      print('Error: $e');
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
            SizedBox(
              height: 30,
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceEvenly, // จัดวาง button ให้อยู่กลาง
                children: [
                  ElevatedButton(
                    onPressed: () => checkIn('attended'),
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(Colors.green),
                      shape: MaterialStateProperty.all(RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      )),
                      padding: MaterialStateProperty.all(
                        EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                      ),
                    ),
                    child: Text('มาเรียน',
                        style: TextStyle(color: Colors.white, fontSize: 18)),
                  ),
                  ElevatedButton(
                    onPressed: () => checkIn('leave'),
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(
                          Color.fromARGB(255, 40, 29, 139)),
                      shape: MaterialStateProperty.all(RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      )),
                      padding: MaterialStateProperty.all(
                        EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                      ),
                    ),
                    child: Text('ลา',
                        style: TextStyle(color: Colors.white, fontSize: 18)),
                  ),
                ],
              ),
            ),
            if (_locationData != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  elevation: 4.0, // ยกกรอบขึ้นมาเล็กน้อย
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0), // มุมโค้งของกรอบ
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.white, // สีพื้นหลังของ Text
                      borderRadius:
                          BorderRadius.circular(10.0), // มุมโค้งของพื้นหลัง
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5), // สีเงา
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: Offset(0, 2), // ตำแหน่งของเงา
                        ),
                      ],
                    ),
                    child: Text(
                      'Latitude: ${_locationData!.latitude}, Longitude: ${_locationData!.longitude}',
                      style: TextStyle(fontSize: 16.0),
                    ),
                  ),
                ),
              ),
            StreamBuilder<DocumentSnapshot>(
              stream: _firestore
                  .collection('users')
                  .doc(widget.uidTeacher)
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
                  return Text('No data available.');
                }

                final data = snapshot.data!.data() as Map<String, dynamic>;
                final List<dynamic>? studentsChecked = data['studentsChecked'];

                if (studentsChecked == null || studentsChecked.isEmpty) {
                  return Text('No check-ins yet.');
                }
                print('UI Updated.');

                return ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: studentsChecked
                      .where((student) => student['uid'] == currentUserUid)
                      .length, // กรองตัวเลือกรายการที่ uid ตรงกัน
                  itemBuilder: (context, index) {
                    final checkIn =
                        studentsChecked
                                .where((student) =>
                                    student['uid'] == currentUserUid)
                                .toList()[index]
                            as Map<String,
                                dynamic>; // กรองตัวเลือกรายการที่ uid ตรงกัน
                    final DateTime time = checkIn['time'].toDate();
                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      elevation: 4.0,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ชื่อ ${checkIn['name']}',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'ชื่อวิชา ${widget.subjectName} รหัสวิชา ${widget.subjectCode} หมู่เรียน ${widget.subjectGroup}',
                              style: TextStyle(fontSize: 14),
                            ),
                            SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'สภานะ ${checkIn['status'] == 'attended' ? 'มาเรียน' : 'ลา'}',
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: checkIn['status'] == 'attended'
                                          ? Colors.green
                                          : Color.fromARGB(255, 65, 59, 153)),
                                ),
                                Text(
                                    'เวลา ${DateFormat('HH:mm').format(time)}'),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'เหรียญที่ได้รับ: ${rewardAmount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.green),
                                ),
                                Text(
                                    'เหรียญที่มีอยู่: ${balanceInt != null ? (balanceInt! / BigInt.from(1e18)).toStringAsFixed(2) : 'Loading...'}'),
                              ],
                            )
                          ],
                        ),
                      ),
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

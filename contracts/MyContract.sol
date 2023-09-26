// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract AttendanceContract {
    // ตัวแปรเก็บข้อมูลการเช็คชื่อ
    mapping(address => mapping(uint256 => bool)) public attendanceRecords;

    // ฟังก์ชันเพิ่มการเช็คชื่อ
    function checkAttendance(uint256 date) public {
        require(date > block.timestamp);
        attendanceRecords[msg.sender][date] = true;
    }

    // ฟังก์ชันตรวจสอบการเช็คชื่อ
    function isAttended(address student, uint256 date) public view returns (bool) {
        return attendanceRecords[student][date];
    }
}

pragma solidity ^0.8.4;

contract AttendanceContract {
    // ตัวแปรเก็บข้อมูลการเช็คชื่อ
    mapping(address => mapping(uint256 => bool)) public attendanceRecords;
    mapping(address => uint256) public balances; // เพิ่มตัวแปรเก็บเหรียญในบัญชี

    // ฟังก์ชันเพิ่มการเช็คชื่อและให้เหรียญรางวัล
    function checkAttendanceAndReward(uint256 date, uint256 rewardAmount) public {
        require(date > block.timestamp, "Invalid date");
        require(!attendanceRecords[msg.sender][date], "Attendance already recorded");
        
        // ทำการเช็คชื่อ
        attendanceRecords[msg.sender][date] = true;
        
        // ให้เหรียญรางวัล
        balances[msg.sender] += rewardAmount;
    }

    // ฟังก์ชันตรวจสอบการเช็คชื่อ
    function isAttended(address student, uint256 date) public view returns (bool) {
        return attendanceRecords[student][date];
    }

    // ฟังก์ชันเพื่อดึงค่าเหรียญในบัญชี
    function getBalance() public view returns (uint256) {
        return balances[msg.sender];
    }
}


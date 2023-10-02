// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract MyContract {
    // จัดเก็บข้อมูลการเช็คชื่อของนักศึกษา
    mapping(address => mapping(uint256 => bool)) public attendanceRecords;
    // จัดเก็บยอดเงินของนักศึกษา
    mapping(address => uint256) public balances;
    
    // ประกาศ event เพื่อบันทึกเมื่อนักศึกษาเช็คชื่อและรับรางวัล
    event CheckedIn(address indexed student, uint256 date, uint256 rewardAmount);
    // ประกาศ event เพื่อบันทึกเมื่อนักศึกษาใช้เหรียญ
    event SpentCoin(address indexed student, uint256 amount);
    
    function checkAttendanceAndReward(uint256 date) public {
    

    // เพิ่ม balance ของผู้ที่เช็คชื่อ
    balances[msg.sender] += 0.02 ether;
    attendanceRecords[msg.sender][date] = true;
        
    // ทำการ emit event สำหรับการเช็คชื่อ
    emit CheckedIn(msg.sender, date, 0.02 ether);
}

    
    
    
    function getBalance() public view returns (uint256) {
        // ดึงยอดเงินปัจจุบันของนักศึกษา
        return balances[msg.sender];
    }
    
    function spendCoin(uint256 amount) public {
        // ตรวจสอบว่านักศึกษามียอดเงินเพียงพอที่จะใช้จ่าย
        require(balances[msg.sender] >= amount, "Insufficient balance");
        
        // หักยอดเงินของนักศึกษาที่ใช้จ่าย
        balances[msg.sender] -= amount;
        
        // ทำการ emit event สำหรับการใช้เหรียญ
        emit SpentCoin(msg.sender, amount);
    }
}


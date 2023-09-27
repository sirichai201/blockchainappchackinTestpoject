pragma solidity ^0.8.4;

contract AttendanceContract {
    mapping(address => mapping(uint256 => bool)) public attendanceRecords;
    mapping(address => uint256) public balances;

    function checkAttendanceAndReward(uint256 date, uint256 rewardAmount) public {
        require(date >= block.timestamp, "Invalid date");
        require(!attendanceRecords[msg.sender][date], "Attendance already recorded");
        
        attendanceRecords[msg.sender][date] = true;
        balances[msg.sender] += rewardAmount;
         emit CheckedIn(msg.sender, date, rewardAmount);
    }

    function isAttended(address student, uint256 date) public view returns (bool) {
        return attendanceRecords[student][date];
    }

    function getBalance() public view returns (uint256) {
        return balances[msg.sender];
    }

    function spendCoin(uint256 amount) public {
    require(balances[msg.sender] >= amount, "Insufficient balance");
    balances[msg.sender] -= amount;
    emit SpentCoin(msg.sender, amount);
}

event CheckedIn(address indexed student, uint256 date, uint256 rewardAmount);
event SpentCoin(address indexed student, uint256 amount);


}

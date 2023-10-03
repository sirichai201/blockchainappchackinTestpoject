

// ระบุสิทธิ์ในการใช้งานและเวอร์ชันของ Solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract MyContract {
    
    // ยอดเงิน (ควอยน์) ของนักศึกษาแต่ละคน
    mapping(address => uint256) public balances;

    // ที่อยู่ของเจ้าของสัญญา
    address public owner;

   
   
    // กำหนดเหตุการณ์ที่เกิดขึ้นเมื่อนักศึกษาใช้ควอยน์
    event SpentCoin(address indexed student, uint256 amount);

    // ฟังก์ชันสร้าง (Constructor) ที่ถูกเรียกขึ้นเมื่อมีการสร้างสัญญา
    constructor() {
        owner = msg.sender;
    }

    // ตัวคัดกรอง (modifier) ให้ฟังก์ชันนั้นๆ เรียกได้เฉพาะจากเจ้าของสัญญาเท่านั้น
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    // ฟังก์ชันสำหรับฝากเงินเข้าสู่สัญญา โดยเฉพาะเจ้าของสัญญาเท่านั้นที่สามารถเรียกใช้
    function deposit() public payable onlyOwner {}

   

    // ฟังก์ชันสำหรับตรวจสอบยอดควอยน์ของนักศึกษา
    function getBalance() public view returns (uint256) {
        return balances[msg.sender];
    }

    // ฟังก์ชันให้นักศึกษาใช้ควอยน์
    function spendCoin(uint256 amount) public {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        emit SpentCoin(msg.sender, amount);
    }

    // ฟังก์ชันสำหรับเจ้าของสัญญาให้ควอยน์รางวัลนักศึกษาที่เช็คชื่อ
   
function rewardStudent(address student) public onlyOwner {
    // จำนวนเงินที่ต้องการโอน
    uint256 rewardAmountEther = 0.05 ether;

    // ตรวจสอบว่าสัญญามีเงินเพียงพอที่จะส่งหรือไม่
    require(address(this).balance >= rewardAmountEther, "Contract does not have enough ether to reward");

    // โอน ether ไปยังที่อยู่ของนักเรียน
    payable(student).transfer(rewardAmountEther);
    
    // เพิ่มยอดเหรียญใน balances
    balances[student] += rewardAmountEther; // หรือจำนวนที่คุณต้องการ
}


}



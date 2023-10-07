// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract MyContract {
    
    // ยอดเงิน (ควอยน์) ของนักศึกษาแต่ละคน
    mapping(address => uint256) public balances;

    // ที่อยู่ของเจ้าของสัญญา
    address public owner;

    // กำหนดเหตุการณ์เมื่อนักศึกษาใช้ควอยน์
    event SpentCoin(address indexed student, uint256 amount);

    // กำหนดเหตุการณ์เมื่อนักศึกษาได้รับควอยน์รางวัล
    event Rewarded(address indexed student, uint256 amount);

    // ฟังก์ชันสร้างเมื่อสัญญาถูกสร้าง
    constructor() {
        owner = msg.sender;
    }

    // ตัวคัดกรอง: เฉพาะเจ้าของสัญญาเท่านั้นที่สามารถเรียกใช้
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    // ฟังก์ชันสำหรับฝากเงินเข้าสัญญา
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

    // ฟังก์ชันให้ควอยน์รางวัลนักศึกษาที่เช็คชื่อ
    function rewardStudent(address student) public onlyOwner {
        // จำนวนเงินที่ต้องการโอน
        uint256 rewardAmountEther = 0.05 ether;

        // ตรวจสอบว่าสัญญามีเงินเพียงพอที่จะส่งหรือไม่
        require(address(this).balance >= rewardAmountEther, "Contract does not have enough ether to reward");

        // โอน ether ไปยังที่อยู่ของนักเรียน
        payable(student).transfer(rewardAmountEther);
    
        // เพิ่มยอดเหรียญใน balances
        balances[student] += rewardAmountEther;

        // ส่งอีเวนท์แจ้งว่านักศึกษาได้รับควอยน์รางวัล
        emit Rewarded(student, rewardAmountEther);
    }

    struct Reward {
    string name;
    string imageUrl;
    uint256 coinCost;
    uint256 quantity;
    address rewardAddress; // เพิ่มฟิลด์นี้เพื่อเก็บ address ของรางวัล
}
    Reward[] public rewards;

    function addReward(string memory _name, string memory _imageUrl, uint256 _coinCost, uint256 _quantity) public onlyOwner {
    Reward memory newReward = Reward({
        name: _name,
        imageUrl: _imageUrl,
        coinCost: _coinCost,
        quantity: _quantity,
        rewardAddress: owner // กำหนดให้ address ของรางวัลเป็นเดียวกันกับ owner ของ contract
    });
    rewards.push(newReward);
}

   
}

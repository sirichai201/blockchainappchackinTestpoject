// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract MyContract {
    
    // ยอดเงินของแต่ละนิสิต
    mapping(address => uint256) public balances;
    // ที่อยู่ของเจ้าของสัญญา
    address public owner;

    // เหตุการณ์ที่เกิดขึ้น
    event SpentCoin(address indexed student, uint256 amount);
    event Rewarded(address indexed student, uint256 amount);
    event Redeemed(address indexed student, string rewardName, uint256 rewardCost, uint256 timestamp);

    // ฟังก์ชันที่ถูกเรียกเมื่อสัญญานี้ถูกสร้าง
    constructor() {
        owner = msg.sender;
    }

    // ตัวคัดกรอง: เฉพาะเจ้าของสัญญาเท่านั้นที่สามารถเรียกใช้
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    // ฟังก์ชันสำหรับฝากเงินเข้าสัญญา
    function deposit() public payable onlyOwner {
        require(msg.value > 0, "Must send some ether");
    }

    // ดึงยอดเงินของนิสิต
    function getBalance() public view returns (uint256) {
        return balances[msg.sender];
    }

    // ให้รางวัลแก่นิสิต
    function rewardStudent(address student) public onlyOwner {
        uint256 rewardAmountEther = 0.05 ether;
        require(address(this).balance >= rewardAmountEther, "Contract does not have enough ether to reward");
        payable(student).transfer(rewardAmountEther);
        balances[student] += rewardAmountEther;
        emit Rewarded(student, rewardAmountEther);
    }

    // ข้อมูลรางวัล
    struct Reward {
        string name;
        
        uint256 coinCost;
        uint256 quantity;
        address rewardAddress;
    }

    // รายการของรางวัล
    Reward[] public rewards;

    // เพิ่มรางวัล
    function addReward(string memory _name,  uint256 _coinCost, uint256 _quantity) public onlyOwner {
        require(_coinCost > 0, "Coin cost should be more than 0");
        require(_quantity > 0, "Quantity should be more than 0");
        Reward memory newReward = Reward({
            name: _name,
            
            coinCost: _coinCost,
            quantity: _quantity,
            rewardAddress: owner
        });
        rewards.push(newReward);
    }

    // ดึงรายการรางวัล
    function getRewards() public view returns (Reward[] memory) {
        return rewards;
    }

    // นิสิตแลกรางวัล
    function redeemReward(uint256 rewardIndex) public {
        require(rewardIndex < rewards.length, "Invalid reward index");
        Reward memory chosenReward = rewards[rewardIndex];
        require(balances[msg.sender] >= chosenReward.coinCost, "Not enough coins to redeem the reward");
        require(chosenReward.quantity > 0, "Reward out of stock");
        balances[msg.sender] -= chosenReward.coinCost;
        balances[chosenReward.rewardAddress] += chosenReward.coinCost;
        rewards[rewardIndex].quantity--;
        emit Redeemed(msg.sender, chosenReward.name, chosenReward.coinCost, block.timestamp);

        // บันทึกประวัติการแลกของรางวัล
        Redemption memory newRedemption = Redemption({
            rewardName: chosenReward.name,
            rewardCost: chosenReward.coinCost,
            timestamp: block.timestamp
        });
        redemptionHistory[msg.sender].push(newRedemption);
    }

    // ข้อมูลการแลกของรางวัล
    struct Redemption {
        string rewardName;
        uint256 rewardCost;
        uint256 timestamp;
    }

    // ประวัติการแลกรางวัล
    mapping(address => Redemption[]) public redemptionHistory;

    // ดึงประวัติการแลกรางวัล
    function getRedemptionHistory(address studentAddress) public view returns (Redemption[] memory) {
        return redemptionHistory[studentAddress];
    }
}

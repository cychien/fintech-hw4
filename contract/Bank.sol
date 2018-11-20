pragma solidity ^0.4.23;

contract Bank {
	// 此合約的擁有者
    address private owner;

	// 儲存所有會員的餘額
    mapping (address => uint256) private balance;
    mapping (address => uint256) private cDeposit;
    mapping (address => uint256) private period; 

	// 事件們，用於通知前端 web3.js
    event DepositEvent(address indexed from, uint256 value, uint256 timestamp);
    event WithdrawEvent(address indexed from, uint256 value, uint256 timestamp);
    event TransferEvent(address indexed from, address indexed to, uint256 value, uint256 timestamp);
    event SetCDepositEvent(address indexed from, uint256 value, uint256 timestamp);
    event ContractExpiredEvent(address indexed from, uint256 value, uint256 timestamp);
    event TerminateContractEvent(address indexed from, uint256 value, uint256 timestamp);

    modifier isOwner() {
        require(owner == msg.sender, "you are not owner");
        _;
    }
    
	// 建構子
    constructor() public payable {
        owner = msg.sender;
    }

	// 存錢
    function deposit() public payable {
        balance[msg.sender] += msg.value;

        emit DepositEvent(msg.sender, msg.value, now);
    }

	// 提錢
    function withdraw(uint256 etherValue) public {
        uint256 weiValue = etherValue * 1 ether;

        require(balance[msg.sender] >= weiValue, "your balances are not enough");

        msg.sender.transfer(weiValue);

        balance[msg.sender] -= weiValue;

        emit WithdrawEvent(msg.sender, etherValue, now);
    }

	// 轉帳
    function transfer(address to, uint256 etherValue) public {
        uint256 weiValue = etherValue * 1 ether;

        require(balance[msg.sender] >= weiValue, "your balances are not enough");

        balance[msg.sender] -= weiValue;
        balance[to] += weiValue;

        emit TransferEvent(msg.sender, to, etherValue, now);
    }

	// 檢查銀行帳戶餘額
    function getBankBalance() public view returns (uint256) {
        return balance[msg.sender];
    }

    /*
    setCDeposit功能，包含正整數定存金額，與正整數定存期間。
    紀錄會員的定存帳戶，並讓定存帳戶金額增加。
    紀錄會員的定存期間。
    通知SetCDepositEvent給web3.js
    */
    //購買定存
    function setCDeposit(uint256 setPeriod) public payable {
        // cDeposit[msg.sender] = cDeposit[msg.sender] + msg.value
        cDeposit[msg.sender] += msg.value;
        period[msg.sender] = setPeriod;

        emit SetCDepositEvent(msg.sender, msg.value, now);
    }

    /*
    ContractExpired功能
    計算本金+本金*期數/100
    將計算結果加回帳戶餘額中
    將定存餘額重設為0
    將定存期數重設為0
    通知ContractExpiredEvent給web3.js
    */
    // 合約期滿
    function contractExpired() public {
        uint256 result = cDeposit[msg.sender] + cDeposit[msg.sender] * period[msg.sender] / 100;
        balance[msg.sender] += result; 
        cDeposit[msg.sender] = 0;
        period[msg.sender] = 0;
        emit ContractExpiredEvent(msg.sender, result, now);
    }

    /*
    TerminateContract功能
    計算本金+本金*期數/100*經過期間/預設定存期間
    將計算結果加回帳戶餘額中
    將定存餘額重設為0
    將定存期數重設為0
    通知TerminateContractEvent給web3.js
    */
    // 提前解約
    function terminateContract(uint256 tPeriod) public {
        uint256 result = cDeposit[msg.sender] + cDeposit[msg.sender] * period[msg.sender] / 100 * tPeriod / period[msg.sender];
        balance[msg.sender] += result; 
        cDeposit[msg.sender] = 0;
        period[msg.sender] = 0;
        emit TerminateContractEvent(msg.sender, result, now);
    }

    // 檢查銀行定存金額
    function getCDeposit() public view returns (uint256) {
        return cDeposit[msg.sender];
    }

    // 檢查銀行定存期數
    function getPeriod() public view returns (uint256) {
        return period[msg.sender];
    }

    function kill() public isOwner {
        selfdestruct(owner);
    }
}
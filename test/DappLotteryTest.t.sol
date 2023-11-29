// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import {Test, console} from "lib/forge-std/src/Test.sol";
import {DappLottery} from "src/DappLottery.sol";
import {DeployLottery} from "../script/DeployLottery.s.sol";
import {ParamHelper} from "../script/helper/ParamHelper.s.sol";

contract DappLotteryTest is Test {
    uint256 public constant SERVICE_PERCENT = 10;

    address OWNER = makeAddr("owner");
    DappLottery public lottery;
    ParamHelper public helpering;

    string[] luckyNumbers = ["AAA", "BBB", "CCC", "DDD"];
    string[] luckyNumbersErr;

    //返回类型

    function setUp() public {
        DeployLottery deployLottery = new DeployLottery();
        helpering = new ParamHelper();
        //vm.startPrank(OWNER);
        address lotteryAddr = deployLottery.run();
        //vm.stopPrank();
        lottery = DappLottery(lotteryAddr);
    }

    function testDeployConstructorParamRight() public {
        uint256 _servicePercent = lottery.servicePercent();
        assertEq(_servicePercent, SERVICE_PERCENT);
    }

    function testCurrentTimeCalculRight() public {
        uint256 expectCurrentTime = (block.timestamp * 1000) + 1000;
        uint256 newTime = lottery.currentTime();
        assertEq(expectCurrentTime, newTime);
    }

    function testCreateLotteryWithRightParam() public {
        (
            string memory title,
            string memory description,
            string memory image,
            uint256 prize,
            uint256 ticketPrice,
            uint256 expirseAt
        ) = helpering.run(true);
        vm.startPrank(OWNER);
        lottery.createLottery(title, description, image, prize, ticketPrice, expirseAt);

        DappLottery.LotteryStruct[] memory _lotteries = lottery.getLotteries();
        DappLottery.LotteryStruct memory _lottery = _lotteries[0];
        vm.stopPrank();
        console.log("title", _lottery.title);
        assertEq(_lotteries.length, 1);
        assertEq(_lottery.title, title);
        assertEq(_lottery.description, description);
        assertEq(_lottery.image, image);
        assertEq(_lottery.prize, prize);
        assertEq(_lottery.ticketPrice, ticketPrice);
        assertEq(_lottery.expirseAt, expirseAt);
    }

    function testCreateLotteryIfRevertByErrorParam() public {
        (
            string memory title,
            string memory description,
            string memory image,
            uint256 prize,
            uint256 ticketPrice,
            uint256 expirseAt
        ) = helpering.run(false);
        vm.startPrank(OWNER);
        vm.expectRevert("title cannot be empty");
        // vm.expectRevert("description cannot be empty");
        // vm.expectRevert("image cannot be empty");
        // vm.expectRevert("prize cannot be zero");
        // vm.expectRevert("title cannot be empty");
        // vm.expectRevert("expireAt cannot be less than future");
        lottery.createLottery(title, description, image, prize, ticketPrice, expirseAt);
        vm.stopPrank();
    }

    modifier _createLottery() {
        (
            string memory title,
            string memory description,
            string memory image,
            uint256 prize,
            uint256 ticketPrice,
            uint256 expirseAt
        ) = helpering.run(true);
        vm.startPrank(OWNER);
        lottery.createLottery(title, description, image, prize, ticketPrice, expirseAt);
        vm.stopPrank();
        _;
    }

    function testImportLuckyNumbersIfRevertNotOwner() public _createLottery {
        address OTHERONE = makeAddr("otherone");
        vm.startPrank(OTHERONE);
        vm.expectRevert("Unauthorized entity");
        lottery.importLuckyNumbers(0, luckyNumbers);
        vm.stopPrank();
    }

    function testImportLuckyNumbersIfRevertNumbersIsNull() public _createLottery {
        vm.startPrank(OWNER);
        vm.expectRevert("Lucky Numbers cannot be zero");
        lottery.importLuckyNumbers(0, luckyNumbersErr);
        vm.stopPrank();
    }

    function testImportLuckyNumbersIfRevertSameIdImportTwice() public _createLottery {
        vm.startPrank(OWNER);
        lottery.importLuckyNumbers(0, luckyNumbers);
        vm.expectRevert("Already Generated");
        lottery.importLuckyNumbers(0, luckyNumbers);
        vm.stopPrank();
    }

    function testGetLuckyNumber() public _createLottery {
        vm.startPrank(OWNER);
        lottery.importLuckyNumbers(0, luckyNumbers);
        string[] memory lucks = lottery.getLotteryLuckyNumbers(0);
        assertEq(lucks.length, luckyNumbers.length);
        for (uint256 i = 0; i < lucks.length; i++) {
            assertEq(lucks[i], luckyNumbers[i]);
        }
        vm.stopPrank();
    }

    function testBuyTicketRevertIfLuckNumberUsed() public _createLottery {
        vm.startPrank(OWNER);
        deal(OWNER, 100 ether);
        lottery.importLuckyNumbers(0, luckyNumbers);
        lottery.buyTicket{value: 0.01 ether}(0, 0);
        vm.expectRevert("lucky number already used");
        lottery.buyTicket{value: 0.01 ether}(0, 0);
        vm.stopPrank();
    }

    modifier _createLotteryAndImportLuckyNumbers() {
        (
            string memory title,
            string memory description,
            string memory image,
            uint256 prize,
            uint256 ticketPrice,
            uint256 expirseAt
        ) = helpering.run(true);
        vm.startPrank(OWNER);
        lottery.createLottery(title, description, image, prize, ticketPrice, expirseAt);
        lottery.importLuckyNumbers(0, luckyNumbers);
        vm.stopPrank();
        _;
    }

    function testBuyTicketRevertIfNotEnoughEther() public _createLotteryAndImportLuckyNumbers {
        vm.startPrank(OWNER);
        vm.expectRevert("insufficient ethers to buy ticket");
        lottery.buyTicket(0, 0);
        vm.expectRevert("insufficient ethers to buy ticket");
        deal(OWNER, 10 ether);
        lottery.buyTicket{value: 0.0001 ether}(0, 0);
        vm.stopPrank();
    }

    function testBuyTicketCheckRightChange() public _createLotteryAndImportLuckyNumbers {
        vm.startPrank(OWNER);
        deal(OWNER, 100 ether);
        lottery.buyTicket{value: 0.01 ether}(0, 0);
        DappLottery.LotteryStruct[] memory _lotteries = lottery.getLotteries();
        assertEq(_lotteries[0].participants, 1);
        DappLottery.ParticipantStruct[] memory _participants = lottery.getLotteryParticipants(0);
        assertEq(_participants[0].account, OWNER);
        string memory _luckynumber = lottery.getLotteryLuckyNumbers(0)[0];
        assertEq(_participants[0].lotteryNumber, _luckynumber);
        assertEq(_participants[0].paid, false);
        bool isUsed = lottery.getLuckyNumberUsed(0, 0);
        assertEq(isUsed, true);
        uint256 s_balance = lottery.serviceBalance();
        assertEq(s_balance, 0.01 ether);
        vm.stopPrank();
    }

    function testRandomSelectWinnersRevertIfNotOwner() public _createLotteryAndImportLuckyNumbers {
        address OTHERONE = makeAddr("otherone");
        vm.startPrank(OTHERONE);
        vm.expectRevert("Unauthorized entity");
        lottery.randomlySelectWinners(0, 1);
        vm.stopPrank();
    }

    modifier _createLotteryAndImportLuckyNumbersAndBuyTicket() {
        (
            string memory title,
            string memory description,
            string memory image,
            uint256 prize,
            uint256 ticketPrice,
            uint256 expirseAt
        ) = helpering.run(true);
        vm.startPrank(OWNER);
        deal(OWNER, 100 ether);
        lottery.createLottery(title, description, image, prize, ticketPrice, expirseAt);
        lottery.importLuckyNumbers(0, luckyNumbers);
        lottery.buyTicket{value: 0.01 ether}(0, 0);
        vm.stopPrank();

        address OTHERONE = makeAddr("otherone");
        vm.startPrank(OTHERONE);
        deal(OTHERONE, 10 ether);
        lottery.buyTicket{value: 0.01 ether}(0, 1);
        vm.stopPrank();
        _;
    }

    function testRandomSelectWinnersRevertIfLotteryCompleted() public _createLotteryAndImportLuckyNumbersAndBuyTicket {
        vm.startPrank(OWNER);
        lottery.randomlySelectWinners(0, 1);
        vm.expectRevert("Lottery have already been completed");
        lottery.randomlySelectWinners(0, 1);
        vm.stopPrank();
    }

    function testRandomSelectWinnersRevertIfNumOfWinnersExpect()
        public
        _createLotteryAndImportLuckyNumbersAndBuyTicket
    {
        vm.startPrank(OWNER);
        vm.expectRevert("Number of Winners exceeds number of participants");
        lottery.randomlySelectWinners(0, 10);
        vm.stopPrank();
    }

    function testRandomSelectWinnersCheckStateChange() public _createLotteryAndImportLuckyNumbersAndBuyTicket {
        vm.startPrank(OWNER);
        lottery.randomlySelectWinners(0, 2);
        DappLottery.lotteryResultStruct memory _lotteryResult = lottery.getLotteryResult(0);
        assertEq(_lotteryResult.completed, true);
        assertEq(_lotteryResult.timestamp, lottery.currentTime());
        DappLottery.LotteryStruct memory _lottery = lottery.getLottery(0);
        assertEq(_lottery.winners, _lotteryResult.winners.length);
        assertEq(_lottery.drawn, true);
        vm.stopPrank();
    }
}

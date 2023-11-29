// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import {Script} from "lib/forge-std/src/Script.sol";
import {DappLottery} from "src/DappLottery.sol";

contract DeployLottery is Script {
    DappLottery public lottery;

    function run() external returns (address) {
        address lotteryAddr = deployDappLottery();
        return lotteryAddr;
    }

    function deployDappLottery() internal returns (address) {
        vm.startBroadcast();
        lottery = new DappLottery(10);
        vm.stopBroadcast();
        return address(lottery);
    }
}

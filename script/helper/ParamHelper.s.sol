// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import {Script} from "lib/forge-std/src/Script.sol";

contract ParamHelper is Script {
    string public title;
    string public description;
    string public image;
    uint256 public prize;
    uint256 public ticketPrice;
    uint256 public expirseAt;

    function run(bool flag)
        external
        view
        returns (
            string memory title,
            string memory description,
            string memory image,
            uint256 prize,
            uint256 ticketPrice,
            uint256 expirseAt
        )
    {
        if (flag) {
            (title, description, image, prize, ticketPrice, expirseAt) = getRightParams();
        } else {
            (title, description, image, prize, ticketPrice, expirseAt) = getErrorParams();
        }
    }

    function getRightParams()
        internal
        view
        returns (
            string memory title,
            string memory description,
            string memory image,
            uint256 prize,
            uint256 ticketPrice,
            uint256 expirseAt
        )
    {
        title = "DappLottory";
        description = "++++";
        image = "www.redlifan.online";
        prize = 100 ether;
        ticketPrice = 0.01 ether;
        expirseAt = block.timestamp + (7 * 24 * 60 * 60 * 1000);
    }

    function getErrorParams()
        internal
        view
        returns (
            string memory title,
            string memory description,
            string memory image,
            uint256 prize,
            uint256 ticketPrice,
            uint256 expirseAt
        )
    {
        title;
        description;
        image;
        prize = 0 ether;
        ticketPrice = 0 ether;
        expirseAt;
    }
}

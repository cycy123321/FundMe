// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
import {Script} from "forge-std/Script.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";
import {FundMe} from "../src/FundMe.sol";
import {console} from "forge-std/console.sol";
//取款操作
contract WithdrawFundMe is Script{
    function withdraw(address mostRecentlyDeployed) public {
        vm.startBroadcast();
        FundMe(payable(mostRecentlyDeployed)).withdraw();
        vm.stopBroadcast();
        console.log("Withdrawn from %s", mostRecentlyDeployed); 
    }

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("FundMe",block.chainid);
        withdraw(mostRecentlyDeployed);
    }
}

//资助
contract FundFundMe is Script{

    uint256 constant send_value = 0.1 ether; //发送的以太币数量
    //fund逻辑
    function fund(address mostRecentlyDeployed) public {
        vm.startBroadcast();
        //合约只有涉及到new才是往构造函数传参
        //FundMe(payable(mostRecentlyDeployed))只是将最近部署的合约地址转换为payable和FundMe合约类型
        FundMe(payable(mostRecentlyDeployed)).fund{value:send_value}();
        vm.stopBroadcast();
        console.log("Funded %s with %s wei", mostRecentlyDeployed, send_value);
        //获取funder的余额
        console.log("Funder balance is %s wei", address(msg.sender).balance );
    }

    function run() external {
        //获取最近部署的合约地址
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("FundMe",block.chainid);
        //调用fund
        fund(mostRecentlyDeployed);
    }
}
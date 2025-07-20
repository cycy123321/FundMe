// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
import {console} from "forge-std/Test.sol";
import {Script} from "forge-std/Script.sol";
import {FundMe} from "../src/FundMe.sol";
import {HelpConfig} from "./HelpConfig.sol";
contract DeployFundMe is Script {
    function run() external returns(FundMe) {
        //在vm.start 和 vm.stop之间的代码会被广播到区块链上 会消耗gas
        //helpConfig是一个帮助配置的合约 不需要上链
        HelpConfig helpConfig = new HelpConfig();
        //由于pricefeedConfigActive结构体只有一个成员变量pricefeed
        //所以可以直接获取pricefeed的地址
        //如果有多个成员变量可以使用(address pricefeed,_,_)=helpConfig.pricefeedConfigActive();
        address pricefeed = helpConfig.pricefeedConfigActive();
        console.log(helpConfig.pricefeedConfigActive());
        vm.startBroadcast();
        FundMe fundme = new FundMe(pricefeed);
        vm.stopBroadcast();
        return fundme;
    }
}
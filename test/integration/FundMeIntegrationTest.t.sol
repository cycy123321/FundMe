// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
import {Test,console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
import {FundFundMe} from "../../script/interaction.s.sol";
import {WithdrawFundMe} from "../../script/interaction.s.sol";

//测试交互功能
contract FundMeInteractionTest is Test {
    FundMe fundme;
    address USER = makeAddr("user");
    uint256 constant START_BALANCE = 10 ether;

    function setUp() external {
        DeployFundMe deployfundme = new DeployFundMe();
        fundme = deployfundme.run();
        vm.deal(USER, START_BALANCE); //给USER地址设置一个初始余额
    }
    function testUserCanFund() external  {
        vm.prank(USER);
        FundFundMe fundFundMe = new FundFundMe();
        fundFundMe.fund(address(fundme));

        WithdrawFundMe withdrawFundMe = new WithdrawFundMe();
        withdrawFundMe.withdraw(address(fundme));
    }
}
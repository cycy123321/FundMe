// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
import {Test,console} from "forge-std/Test.sol";

//简单展示
// contract FundMeTest is Test {
//     uint256 number;
//     function setUp() external {
//         number = 2;
//     }
//     function testDemo() public view {
//         //判断number是否等于2 
//         assertEq(number,2);
//         //console.log可以打印显示出来
//         console.log("number is %s",number);
//         console.log("hello!");
//     }
// }

//测试我们src中的FoundMe合约
import {FundMe} from '../../src/FundMe.sol';
import {DeployFundMe} from '../../script/DeployFundMe.s.sol';
contract FundMeTest is Test {
    //定义一个fundme合约变量
    FundMe fundme;

    address USER = makeAddr("user"); //user地址是没钱的 要设置一个初始余额 方便后续测试
    uint256 constant START_BALANCE = 10 ether;

    function setUp() external {
        //初始化部署deployfundme合约
        DeployFundMe deployfundme = new DeployFundMe();
        fundme = deployfundme.run();
        vm.deal(USER, START_BALANCE); //给USER地址设置一个初始余额 10ether
    }
    //测试合约中 Minimunusd是不是5e18
    function testMinimunUsd() public  view {
        //在 Solidity 中，状态变量会自动生成 getter 函数，这是语言的默认特性。当你看到 fundme.MINIMUM_USD() 时，实际上是通过 getter 函数访问状态变量 MINIMUM_USD，而非直接访问变量本身。
        assertEq(fundme.MINIMUM_USD(), 5e18, "Minimum USD should be 5e18");
    }
    //测试合约中owner是不是部署者
    //由于fundme合约是在FundMeTest的setUp函数中由deployfundme合约部署的，所以i_owner应该是setUp的调用者
    function testOwner() public view{
        console.log(fundme.getOwner());
        console.log(address(this));
        console.log(msg.sender);
        //会报错
        assertEq(fundme.getOwner(),msg.sender);
        //assertEq(fundme.i_owner(),address(this));
    }
    function testGetVersionIsAccurate() public view {
        //获取priceFeed的版本
        uint256 version = fundme.getVersion();
        //断言版本号是4
        assertEq(version, 4, "Price feed version should be 4");
    }
    function testFundFailWithoutEnoughEth() public {
        //测试异常情况：在编写智能合约的测试用例时，我们不仅要验证合约在正常情况下的行为，
        //还要确保合约在异常输入或者不合法操作时能够正确地拒绝执行。vm.expectRevert()就可以帮助我们验证这一点。
        vm.expectRevert();//预期下一行会出现回滚 若没有回滚就会报错
        fundme.fund{value:0}(); //fund函数中需要value大于等于5e18 才不会回滚 否则就会回滚
    }

    function testUpdatesFundDataStructure() public {
        //要自己先分辨好是谁做的
        // fundme.fund{value:5e18}();
        // uint256 amountFunded = fundme.getAddressToAmountFund(address(this));
        // address funder = fundme.getFunder(0);
        // assertEq(funder,address(this));
        // assertEq(amountFunded,5e18);

        //在测试中分辨是谁做的比较复杂  可以使用prank指定一个地址
        vm.prank(USER); //模拟USER调用fund函数
        fundme.fund{value:5e18}();
        uint256 amountFunded = fundme.getAddressToAmountFund(USER);
        assertEq(amountFunded,5e18);
        address funder = fundme.getFunder(0);
        assertEq(funder,USER);
    }

    modifier fund() {
        vm.prank(USER); //模拟USER调用fund函数
        fundme.fund{value:5e18}();
        _;
    }
    //添加了修饰符fund  其会先执行修饰符里面的代码 再执行该函数里面代码
    function testOnlyOwnerCanWithdraw() public fund {
        //先赞助 再把赞助提取 看看会不会报错**修饰符执行了
        //查看提取能否进行
        vm.prank(USER);
        vm.expectRevert();//期待下面回滚
        fundme.withdraw(); //是USER来调用withdraw进行的不是owner 回滚是正确的 
    }

    //只有单个赞助者 的取款情况
    function testWithdrawWithASingleFunder() public fund{
        //arrange
        uint256 startingOwnerBalance = fundme.getOwner().balance;
        uint256 staringFundMeBalance = address(fundme).balance;

        //act  取款操作
        vm.prank(fundme.getOwner()); //模拟owner调用withdraw函数
        fundme.withdraw();
        //assert
        uint256 endingOwnerBalance = fundme.getOwner().balance;
        uint256 endingFundMeBalance = address(fundme).balance;
        assertEq(endingFundMeBalance,0);
        assertEq(endingOwnerBalance, startingOwnerBalance + staringFundMeBalance);
    }
    //只有单个赞助者 的取款情况  cheaperWithdraw
    function testCheaperWithdrawWithASingleFunder() public fund{
        //arrange
        uint256 startingOwnerBalance = fundme.getOwner().balance;
        uint256 staringFundMeBalance = address(fundme).balance;

        //act  取款操作
        vm.prank(fundme.getOwner()); //模拟owner调用cheaperWithdraw函数
        fundme.cheaperWithdraw();
        //assert
        uint256 endingOwnerBalance = fundme.getOwner().balance;
        uint256 endingFundMeBalance = address(fundme).balance;
        assertEq(endingFundMeBalance,0);
        assertEq(endingOwnerBalance, startingOwnerBalance + staringFundMeBalance);
    }
    //有多个赞助者的取款情况
    function testWithdrawWithSomeFunders() public {
        //arrange
        //使用uint160模拟funder地址 address(uint160);
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for(uint160 i = startingFunderIndex;i<=numberOfFunders;i++){
            address funder = address(i);
            //hoax是 vm.prank + vm.deal 的组合函数
            hoax(funder,5e18);// 等于 vm.prank(funder); vm.deal(funder,5e18);
            fundme.fund{value:5e18}();
        }
        uint256 startingOwnerBalance = fundme.getOwner().balance;
        uint256 staringFundMeBalance = address(fundme).balance;

        //act
        vm.prank(fundme.getOwner());
        fundme.withdraw();

        //assert
        uint256 endingOwnerBalance = fundme.getOwner().balance;
        uint256 endingFundMeBalance = address(fundme).balance;
        assertEq(endingFundMeBalance,0);
        assertEq(endingOwnerBalance, startingOwnerBalance + staringFundMeBalance);

    }
    //有多个赞助者的取款情况 cheaperWithdraw
    function testCheaperWithdrawWithSomeFunders() public {
        //arrange
        //使用uint160模拟funder地址 address(uint160);
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for(uint160 i = startingFunderIndex;i<=numberOfFunders;i++){
            address funder = address(i);
            //hoax是 vm.prank + vm.deal 的组合函数
            hoax(funder,5e18);// 等于 vm.prank(funder); vm.deal(funder,5e18);
            fundme.fund{value:5e18}();
        }
        uint256 startingOwnerBalance = fundme.getOwner().balance;
        uint256 staringFundMeBalance = address(fundme).balance;

        //act
        vm.prank(fundme.getOwner());
        fundme.cheaperWithdraw();

        //assert
        uint256 endingOwnerBalance = fundme.getOwner().balance;
        uint256 endingFundMeBalance = address(fundme).balance;
        assertEq(endingFundMeBalance,0);
        assertEq(endingOwnerBalance, startingOwnerBalance + staringFundMeBalance);

    }
}
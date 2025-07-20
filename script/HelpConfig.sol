// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/MOCK/MockV3Aggregator.sol";
contract HelpConfig is Script{
    struct NetworkConfig{
        address pricefeed;
    }
    NetworkConfig public pricefeedConfigActive;

    //MockV3Aggregator合约对应类型 uint8 int256
    uint8 public constant DECIMALS = 8; //最小位数
    int256 public constant INITIAL_ANSWER = 2000e8; // 2000起始价格

    constructor() {
        //block.chainid 当前链上id
        //11155111 是Sepolia测试网络的链id
        if(block.chainid == 11155111) {
            pricefeedConfigActive = getSepoliaEthConfig();
        }
        //getAnvilEthConfig
        else{
            pricefeedConfigActive = getOrCreateAnvilEthConfig();
        }
    }

    function getSepoliaEthConfig() public pure returns(NetworkConfig memory){
        //先声明再赋值
        NetworkConfig memory sepoliaConfig;
        sepoliaConfig.pricefeed = 0x694AA1769357215DE4FAC081bf1f309aDC325306; //地址是sepolia链上实际存在的价格查询合约地址
        //实例化同时赋值
        // NetworkConfig memory sepoliaConfig = NetworkConfig({
        //     pricefeed:0x694AA1769357215DE4FAC081bf1f309aDC3253
        // });
        return sepoliaConfig;
    }
    function getOrCreateAnvilEthConfig() public  returns(NetworkConfig memory){
        //先执行一个判断pricefeedConfigActive是否已经被赋值 已经存在直接返回就行  不需要执行下面的操作
        if(pricefeedConfigActive.pricefeed != address(0)){
            return pricefeedConfigActive;
        }
        //anvil是本地的虚拟链环境 我们并没有在上面部署实际的pricefeed（可查询价格）合约
        //所以我们需要部署一个MockV3Aggregator虚拟合约
        vm.startBroadcast();
        MockV3Aggregator mockV3Aggregator = new MockV3Aggregator(DECIMALS, INITIAL_ANSWER);
        vm.stopBroadcast();      
        NetworkConfig memory anvilConfig;
        anvilConfig.pricefeed = address(mockV3Aggregator);
        return anvilConfig;
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/UniswapV2Factory.sol";
import "../src/ERC20.sol";

contract DeployUniswapV2 is Script {
    function run() external {
        vm.startBroadcast();

        // 1. 部署工厂
        UniswapV2Factory factory = new UniswapV2Factory(msg.sender);

        // 2. 部署测试币
        ERC20 tokenA = new ERC20(1_000_000 ether);
        ERC20 tokenB = new ERC20(1_000_000 ether);

        // 3. 创建交易对
        address pair = factory.createPair(address(tokenA), address(tokenB));

        console.log("Factory:", address(factory));
        console.log("TokenA:", address(tokenA));
        console.log("TokenB:", address(tokenB));
        console.log("Pair:", pair);

        vm.stopBroadcast();
    }
}

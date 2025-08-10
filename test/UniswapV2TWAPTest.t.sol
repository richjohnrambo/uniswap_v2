// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/UniswapV2Factory.sol";
import "../src/UniswapV2Pair.sol";
import "../src/MyToken.sol";
import "../src/UniswapV2FlashLoan.sol";

contract UniswapV2TWAPTest is Test {
    UniswapV2Factory factory;
    UniswapV2Pair pair;
    MyToken token0;
    MyToken token1;

    uint256 constant AMOUNT0 = 1000 * 10**18;  // Adjusted values
    uint256 constant AMOUNT1 = 1000 * 10**18;

    function setUp() public {
        // Deploy Uniswap V2 Factory and two ERC20 tokens
        factory = new UniswapV2Factory(address(this));
        token0 = new MyToken("Token0", "TK0");
        token1 = new MyToken("Token1", "TK1");

        // Create the Uniswap pair through the factory
        factory.createPair(address(token0), address(token1));
        address pairAddress = factory.getPair(address(token0), address(token1));
        pair = UniswapV2Pair(pairAddress);

        // Mint tokens and approve the pair contract
        token0.mint(address(pair), AMOUNT0);
        token1.mint(address(pair), AMOUNT1);

        // Approve tokens for liquidity deposit
        token0.approve(address(pair), AMOUNT0);
        token1.approve(address(pair), AMOUNT1);

        // Add liquidity to the pair
        pair.mint(address(this));  // Ensure liquidity is added to the pool
    }

    function testTWAPMultipleTradesOverTime() public {
        UniswapV2FlashLoan flashLoan = new UniswapV2FlashLoan(address(pair), address(token0), address(token1));

        token0.transfer(address(flashLoan), 1e18);
        token1.transfer(address(flashLoan), 1e18);

        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
        console.log("Initial Reserve0:", reserve0);
        console.log("Initial Reserve1:", reserve1);

        uint256 inputAmount = reserve0 / 20; // 每次交易投入5%

        // 读取初始累计价格和时间
        uint startPrice0Cumulative = pair.price0CumulativeLast();
        uint startPrice1Cumulative = pair.price1CumulativeLast();
        uint startTimestamp = block.timestamp;

        // 交易 1
        token0.transfer(address(pair), inputAmount);
        pair.swap((inputAmount * 9) / 10, 0, address(flashLoan), new bytes(0));
        vm.warp(block.timestamp + 10);   // 时间推进10秒
        pair.sync();                    // 触发累计价格更新

        // 交易 2
        token1.transfer(address(pair), inputAmount);
        pair.swap(0, (inputAmount * 9) / 10, address(flashLoan), new bytes(0));
        vm.warp(block.timestamp + 15);  // 时间推进15秒
        pair.sync();

        // 交易 3
        token0.transfer(address(pair), inputAmount * 2);
        pair.swap(inputAmount, 0, address(flashLoan), new bytes(0));
        vm.warp(block.timestamp + 20);  // 时间推进20秒
        pair.sync();

        // 交易 4
        token1.transfer(address(pair), inputAmount * 2);
        pair.swap(0, inputAmount, address(flashLoan), new bytes(0));
        vm.warp(block.timestamp + 25);  // 时间推进25秒
        pair.sync();

        // 读取最终累计价格和时间
        uint endPrice0Cumulative = pair.price0CumulativeLast();
        uint endPrice1Cumulative = pair.price1CumulativeLast();
        uint endTimestamp = block.timestamp;

        console.log("Start cumulative price0:", startPrice0Cumulative);
        console.log("Start cumulative price1:", startPrice1Cumulative);
        console.log("End cumulative price0:", endPrice0Cumulative);
        console.log("End cumulative price1:", endPrice1Cumulative);
        console.log("Time elapsed:", endTimestamp - startTimestamp);

        uint timeElapsed = endTimestamp - startTimestamp;

        // 计算区间TWAP
        uint avgPrice0 = (endPrice0Cumulative - startPrice0Cumulative) / timeElapsed;
        uint avgPrice1 = (endPrice1Cumulative - startPrice1Cumulative) / timeElapsed;

        assertTrue(avgPrice0 > 0, "TWAP price0 should be greater than 0");
        assertTrue(avgPrice1 > 0, "TWAP price1 should be greater than 0");
    }


}

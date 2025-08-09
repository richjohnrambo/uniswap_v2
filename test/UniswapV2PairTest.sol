// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

import "../src/UniswapV2Factory.sol";
import "../src/UniswapV2Pair.sol";
import "../src/ERC20.sol";

contract UniswapV2PairTest is Test {
    UniswapV2Factory factory;
    UniswapV2Pair pair;
    ERC20 token0;
    ERC20 token1;

    address wallet = vm.addr(1);
    address other = vm.addr(2);

    uint112 constant MINIMUM_LIQUIDITY = 1000;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Sync(uint112 reserve0, uint112 reserve1);
    event Mint(address sender, uint256 amount0, uint256 amount1);
    event Burn(address sender, uint256 amount0, uint256 amount1, address to);
    event Swap(address sender, uint256 amount0In, uint256 amount1In, uint256 amount0Out, uint256 amount1Out, address to);

    function setUp() public {
        vm.startPrank(wallet);
        factory = new UniswapV2Factory(wallet);

        token0 = new ERC20(1_000_000 ether);
        token1 = new ERC20(1_000_000 ether);

        address pairAddress = factory.createPair(address(token0), address(token1));
        pair = UniswapV2Pair(pairAddress);

        // 给 wallet 转点代币用于测试
        token0.transfer(wallet, 100 ether);
        token1.transfer(wallet, 100 ether);
        vm.stopPrank();
    }

    function addLiquidity(uint256 amount0, uint256 amount1) internal {
        vm.startPrank(wallet);
        token0.transfer(address(pair), amount0);
        token1.transfer(address(pair), amount1);
        pair.mint(wallet);
        vm.stopPrank();
    }

    function testMint() public {
        vm.startPrank(wallet);

        uint256 amount0 = 1 ether;
        uint256 amount1 = 4 ether;

        token0.transfer(address(pair), amount0);
        token1.transfer(address(pair), amount1);

        vm.expectEmit(true, true, false, true);
        emit Transfer(address(0), address(0), MINIMUM_LIQUIDITY);

        vm.expectEmit(true, true, false, true);
        emit Transfer(address(0), wallet, 2 ether - MINIMUM_LIQUIDITY);

        vm.expectEmit(false, false, false, true);
        emit Sync(uint112(amount0), uint112(amount1));

        vm.expectEmit(true, false, false, true);
        emit Mint(wallet, amount0, amount1);

        uint liquidity = pair.mint(wallet);

        assertEq(pair.totalSupply(), 2 ether);
        assertEq(pair.balanceOf(wallet), 2 ether - MINIMUM_LIQUIDITY);
        assertEq(token0.balanceOf(address(pair)), amount0);
        assertEq(token1.balanceOf(address(pair)), amount1);

        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
        assertEq(reserve0, uint112(amount0));
        assertEq(reserve1, uint112(amount1));

        vm.stopPrank();
    }

    function testSwap() public {
        addLiquidity(5 ether, 10 ether);

        uint256 swapAmount = 1 ether;

        vm.startPrank(wallet);
        token0.transfer(address(pair), swapAmount);

        uint256 expectedOutputAmount = 1662497915624478906; // 约1.6625 ether

        vm.expectEmit(true, true, false, true);
        emit Transfer(address(pair), wallet, expectedOutputAmount);

        vm.expectEmit(false, false, false, true);
        emit Sync(uint112(5 ether + swapAmount), uint112(10 ether - expectedOutputAmount));

        vm.expectEmit(true, false, false, true);
        emit Swap(wallet, swapAmount, 0, 0, expectedOutputAmount, wallet);

        pair.swap(0, expectedOutputAmount, wallet, "");

        vm.stopPrank();

        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
        assertEq(reserve0, uint112(5 ether + swapAmount));
        assertEq(reserve1, uint112(10 ether - expectedOutputAmount));
    }

    function testBurn() public {
        addLiquidity(3 ether, 3 ether);

        uint liquidity = 3 ether;

        vm.startPrank(wallet);
        pair.transfer(address(pair), liquidity - MINIMUM_LIQUIDITY);

        vm.expectEmit(true, true, false, true);
        emit Transfer(address(pair), address(0), liquidity - MINIMUM_LIQUIDITY);

        vm.expectEmit(true, false, false, true);
        emit Transfer(address(pair), wallet, 3 ether - 1000);

        vm.expectEmit(true, false, false, true);
        emit Transfer(address(pair), wallet, 3 ether - 1000);

        vm.expectEmit(false, false, false, true);
        emit Sync(1000, 1000);

        vm.expectEmit(true, false, false, true);
        emit Burn(wallet, 3 ether - 1000, 3 ether - 1000, wallet);

        pair.burn(wallet);

        assertEq(pair.balanceOf(wallet), 0);
        assertEq(pair.totalSupply(), MINIMUM_LIQUIDITY);
        assertEq(token0.balanceOf(address(pair)), 1000);
        assertEq(token1.balanceOf(address(pair)), 1000);

        vm.stopPrank();
    }
}

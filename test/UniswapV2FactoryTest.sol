// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

import "../src/UniswapV2Factory.sol";
import "../src/UniswapV2Pair.sol";

contract UniswapV2FactoryTest is Test {
    UniswapV2Factory factory;
    address wallet;
    address other;

    address constant token0 = 0x1000000000000000000000000000000000000000;
    address constant token1 = 0x2000000000000000000000000000000000000000;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function setUp() public {
        wallet = vm.addr(1);
        other = vm.addr(2);

        vm.prank(wallet);
        factory = new UniswapV2Factory(wallet);
    }

    function testInitialValues() public {
        assertEq(factory.feeTo(), address(0));
        assertEq(factory.feeToSetter(), wallet);
        assertEq(factory.allPairsLength(), 0);
    }

    function testCreatePair() public {
        vm.prank(wallet);

        // 监听 PairCreated 事件
        vm.expectEmit(true, true, false, true);
        emit PairCreated(token0, token1, address(0), 1); // pair地址不确定，先写0测试

        address pair = factory.createPair(token0, token1);
        assertTrue(pair != address(0));
        assertEq(factory.getPair(token0, token1), pair);
        assertEq(factory.getPair(token1, token0), pair);
        assertEq(factory.allPairs(0), pair);
        assertEq(factory.allPairsLength(), 1);

        UniswapV2Pair pairContract = UniswapV2Pair(pair);
        assertEq(pairContract.factory(), address(factory));
        assertEq(pairContract.token0(), token0);
        assertEq(pairContract.token1(), token1);
    }

    function testCreatePairDuplicateFails() public {
        vm.prank(wallet);
        factory.createPair(token0, token1);

        vm.prank(wallet);
        vm.expectRevert(bytes("UniswapV2: PAIR_EXISTS"));
        factory.createPair(token0, token1);

        vm.prank(wallet);
        vm.expectRevert(bytes("UniswapV2: PAIR_EXISTS"));
        factory.createPair(token1, token0);
    }

    function testCreatePairReverse() public {
        vm.prank(wallet);
        address pair1 = factory.createPair(token0, token1);

        vm.prank(wallet);
        // 反转顺序，应该 revert
        vm.expectRevert(bytes("UniswapV2: PAIR_EXISTS"));
        factory.createPair(token1, token0);

        assertEq(factory.getPair(token1, token0), pair1);
    }

    function testSetFeeTo() public {
        // 非feeToSetter 调用 setFeeTo 会 revert
        vm.prank(other);
        vm.expectRevert(bytes("UniswapV2: FORBIDDEN"));
        factory.setFeeTo(other);

        vm.prank(wallet);
        factory.setFeeTo(other);
        assertEq(factory.feeTo(), other);
    }

    function testSetFeeToSetter() public {
        // 非feeToSetter 调用 setFeeToSetter 会 revert
        vm.prank(other);
        vm.expectRevert(bytes("UniswapV2: FORBIDDEN"));
        factory.setFeeToSetter(other);

        vm.prank(wallet);
        factory.setFeeToSetter(other);
        assertEq(factory.feeToSetter(), other);

        // feeToSetter 权限转移后，旧的 setter 不能再修改
        vm.prank(wallet);
        vm.expectRevert(bytes("UniswapV2: FORBIDDEN"));
        factory.setFeeToSetter(wallet);
    }
}

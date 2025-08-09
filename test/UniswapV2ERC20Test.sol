// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/ERC20.sol"; // 路径根据你项目调整

contract UniswapV2ERC20Test is Test {
    ERC20 token;
    address wallet;
    address other;

    uint256 constant TOTAL_SUPPLY = 10_000 * 1e18;
    uint256 constant TEST_AMOUNT = 10 * 1e18;

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function setUp() public {
        wallet = vm.addr(1);
        other = vm.addr(2);

        vm.prank(wallet);
        token = new ERC20(100000 ether);

        // 这里假设你的合约构造函数会 mint 总量给部署者
        // 如果没有自动 mint，需要你手动 mint 或改写合约

        // 也可以直接模拟 mint
        vm.prank(wallet);
        token.mint(wallet, TOTAL_SUPPLY);
    }

    function testMetadata() public {
        assertEq(token.name(), "Uniswap V2");
        assertEq(token.symbol(), "UNI-V2");
        assertEq(token.decimals(), 18);
        assertEq(token.totalSupply(), TOTAL_SUPPLY);
        assertEq(token.balanceOf(wallet), TOTAL_SUPPLY);
        // DOMAIN_SEPARATOR 和 PERMIT_TYPEHASH 可以写测试，但计算比较复杂
    }

    function testApprove() public {
        vm.prank(wallet);

        vm.expectEmit(true, true, false, true);
        emit Approval(wallet, other, TEST_AMOUNT);

        bool success = token.approve(other, TEST_AMOUNT);
        assertTrue(success);
        assertEq(token.allowance(wallet, other), TEST_AMOUNT);
    }

    function testTransfer() public {
        vm.prank(wallet);

        vm.expectEmit(true, true, false, true);
        emit Transfer(wallet, other, TEST_AMOUNT);

        bool success = token.transfer(other, TEST_AMOUNT);
        assertTrue(success);
        assertEq(token.balanceOf(wallet), TOTAL_SUPPLY - TEST_AMOUNT);
        assertEq(token.balanceOf(other), TEST_AMOUNT);
    }

    function testTransferFail() public {
        vm.prank(wallet);
        vm.expectRevert();
        token.transfer(other, TOTAL_SUPPLY + 1);

        vm.prank(other);
        vm.expectRevert();
        token.transfer(wallet, 1);
    }

    function testTransferFrom() public {
        vm.prank(wallet);
        token.approve(other, TEST_AMOUNT);

        vm.prank(other);
        vm.expectEmit(true, true, false, true);
        emit Transfer(wallet, other, TEST_AMOUNT);

        bool success = token.transferFrom(wallet, other, TEST_AMOUNT);
        assertTrue(success);
        assertEq(token.allowance(wallet, other), 0);
        assertEq(token.balanceOf(wallet), TOTAL_SUPPLY - TEST_AMOUNT);
        assertEq(token.balanceOf(other), TEST_AMOUNT);
    }

    function testTransferFromMax() public {
        vm.prank(wallet);
        token.approve(other, type(uint256).max);

        vm.prank(other);
        vm.expectEmit(true, true, false, true);
        emit Transfer(wallet, other, TEST_AMOUNT);

        bool success = token.transferFrom(wallet, other, TEST_AMOUNT);
        assertTrue(success);
        assertEq(token.allowance(wallet, other), type(uint256).max);
        assertEq(token.balanceOf(wallet), TOTAL_SUPPLY - TEST_AMOUNT);
        assertEq(token.balanceOf(other), TEST_AMOUNT);
    }

    // permit 测试在 Solidity 写比较复杂，Foundry 里推荐用 JS 或者直接跳过
}

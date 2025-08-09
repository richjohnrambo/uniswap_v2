// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/UniswapV2Factory.sol";
import "../src/ERC20.sol";
import "../src/UniswapV2Library.sol";

contract UniswapV2LocalTest is Test {
    function testPairAddressMatch() public {
        UniswapV2Factory factory = new UniswapV2Factory(address(this));
        ERC20 tokenA = new ERC20(1000 ether);
        ERC20 tokenB = new ERC20(1000 ether);

        address createdPair = factory.createPair(address(tokenA), address(tokenB));
        address computedPair = UniswapV2Library.pairFor(address(factory), address(tokenA), address(tokenB));

        assertEq(createdPair, computedPair, "pairFor address mismatch!");
    }
}

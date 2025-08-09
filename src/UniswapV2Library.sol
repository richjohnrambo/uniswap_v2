// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library UniswapV2Library {

    bytes32 internal constant INIT_CODE_HASH = 0x9fa46c93b961d58beec8923c9dbabe7e80a95ad932dc0b285c1de86aa3b0d5b4;

    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        pair = address(
            uint160(uint(
                keccak256(
                    abi.encodePacked(
                        hex'ff',
                        factory,
                        keccak256(abi.encodePacked(token0, token1)),
                        INIT_CODE_HASH // 关键就是这个
                    )
                )
            ))
        );
    }
}

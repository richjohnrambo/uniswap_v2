// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IUniswapV2Callee.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract UniswapV2FlashLoan is IUniswapV2Callee {
    address private owner;
    IUniswapV2Pair private pair;
    address private token0;
    address private token1;

    // Constructor to set the pair and token addresses
    constructor(address _pair, address _token0, address _token1) {
        owner = msg.sender;
        pair = IUniswapV2Pair(_pair);
        token0 = _token0;
        token1 = _token1;
    }

    // Flash loan callback function (uniswapV2Call)
    function uniswapV2Call(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external override {
        // 获取当前池子的储备
        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
        console.log("Reserve0: ", reserve0);
        console.log("Reserve1: ", reserve1);
        
        // 检查传入的金额是否超过储备
        require(amount0 <= reserve0, "Insufficient liquidity for token0");
        require(amount1 <= reserve1, "Insufficient liquidity for token1");

        // 计算需要还款的金额（包括手续费）
        uint256 fee0 = amount0 * 3 / 997;
        uint256 fee1 = amount1 * 3 / 997;
        uint256 amount0ToRepay = amount0 + fee0;
        uint256 amount1ToRepay = amount1 + fee1;

        // 输出还款金额
        console.log("Amount0 to repay: ", amount0ToRepay);
        console.log("Amount1 to repay: ", amount1ToRepay);

        // 确保借款的金额连同手续费一起偿还
        if (amount0 > 0) {
            IERC20(token0).transfer(address(pair), amount0ToRepay);
        }
        if (amount1 > 0) {
            IERC20(token1).transfer(address(pair), amount1ToRepay);
        }
    }

    function triggerFlashLoan(uint256 amount0, uint256 amount1, address to) external {
        // 确保借款的金额不超过池子储备
        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
        require(amount0 <= reserve0 && amount1 <= reserve1, "Amount exceeds reserves");

        // 启动闪电贷
        pair.swap(amount0, amount1, to, new bytes(0));
    }


}

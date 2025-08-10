// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Minimal interface for UniswapV2Pair used by the oracle
interface IUniswapV2PairMinimal {
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function getReserves() external view returns (uint112, uint112, uint32);
}

/// @title UniswapV2TWAP
/// @dev 计算基于 UniswapV2 price cumulative 的 TWAP（token1 per token0 或反向）
contract UniswapV2TWAP {
    IUniswapV2PairMinimal public immutable pair;
    bool public immutable token0IsBase; // true => price0 = token1/token0 (quote per base)
    uint public priceCumulativeLast;
    uint32 public blockTimestampLast;

    // average price in UQ112x112 (fixed point) after last update
    uint public priceAverageUQ112;

    /// @param _pair UniswapV2 pair 地址
    /// @param _token0IsBase 如果你想要 price 表示 token1 per token0 填 true；否则用反向 price1 表示 token0 per token1
    constructor(address _pair, bool _token0IsBase) {
        pair = IUniswapV2PairMinimal(_pair);
        token0IsBase = _token0IsBase;

        // 初始化：读取当前 cumulative 和 timestamp
        if (_token0IsBase) {
            priceCumulativeLast = pair.price0CumulativeLast();
        } else {
            priceCumulativeLast = pair.price1CumulativeLast();
        }
        (, , uint32 blockTimestampLast_) = pair.getReserves();
        blockTimestampLast = blockTimestampLast_;
    }

    /// @notice 更新内部 snapshot 并计算区间 TWAP（基于上一次 snapshot 到当前）
    /// @dev 将新的 average 存在 priceAverageUQ112（UQ112.112 格式）
    function update() external {
        uint priceCumulative;
        if (token0IsBase) {
            priceCumulative = pair.price0CumulativeLast();
        } else {
            priceCumulative = pair.price1CumulativeLast();
        }

        (, , uint32 blockTimestamp) = pair.getReserves();
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // 32-bit overflow okay, same as Uniswap

        require(timeElapsed > 0, "No time elapsed");

        // average price in Q112 = (priceCumulative - last) / timeElapsed
        // store as uint (UQ112.112)
        uint priceAverage = (priceCumulative - priceCumulativeLast) / uint(timeElapsed);

        priceAverageUQ112 = priceAverage;
        // update state
        priceCumulativeLast = priceCumulative;
        blockTimestampLast = blockTimestamp;
    }

    /// @notice consult 返回 TWAP（以 1e18 缩放的价格： quote per base）
    /// @dev priceAverageUQ112 is UQ112.112, to convert to 1e18: (priceAverageUQ112 * 1e18) >> 112
    function consult() external view returns (uint priceScaled) {
        // priceAverageUQ112 might be zero if not updated; that's okay
        // convert to 1e18 fixed point
        priceScaled = (priceAverageUQ112 * 1e18) >> 112;
    }

    /// @notice 同时返回 UQ112.112 格式的平均值以及 1e18 缩放的价格，便于测试验证
    function consultBoth() external view returns (uint averageUQ112, uint price1e18) {
        averageUQ112 = priceAverageUQ112;
        price1e18 = (priceAverageUQ112 * 1e18) >> 112;
    }
}
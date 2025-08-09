// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./interfaces/IUniswapV2Factory.sol";
import "./UniswapV2Pair.sol";

/**
 * @title UniswapV2Factory
 * @notice Uniswap V2 核心工厂合约，负责创建交易对（Pair）。
 */
contract UniswapV2Factory is IUniswapV2Factory {
    /// @notice 收取协议手续费的地址（swap 费的一部分会转给这个地址）
    address public override feeTo;

    /// @notice 有权限设置 feeTo 和 feeToSetter 的地址
    address public override feeToSetter;

    /// @notice tokenA => tokenB => Pair 地址的映射（双向存储）
    mapping(address => mapping(address => address)) public getPair;

    /// @notice 存储所有创建过的 Pair 地址
    address[] public allPairs;

    /**
     * @param _feeToSetter 初始化 feeToSetter 地址
     */
    constructor(address _feeToSetter) {
        feeToSetter = _feeToSetter;
    }

    /// @notice 获取当前创建的所有 Pair 的数量
    function allPairsLength() external view override returns (uint) {
        return allPairs.length;
    }

    /**
     * @notice 创建交易对
     * @param tokenA ERC20 代币地址 A
     * @param tokenB ERC20 代币地址 B
     * @return pair 新创建的交易对合约地址
     */
    function createPair(address tokenA, address tokenB) external override returns (address pair) {
        require(tokenA != tokenB, "UniswapV2: IDENTICAL_ADDRESSES");

        // 按 token 地址大小排序，保证 token0 < token1
        (address token0_, address token1_) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0_ != address(0), "UniswapV2: ZERO_ADDRESS");
        require(getPair[token0_][token1_] == address(0), "UniswapV2: PAIR_EXISTS"); // 不能重复创建

        // 获取 UniswapV2Pair 合约字节码（creationCode）
        bytes memory bytecode = type(UniswapV2Pair).creationCode;

        // 计算 create2 的 salt（token0 + token1 的哈希）
        bytes32 salt = keccak256(abi.encodePacked(token0_, token1_));

        // 用 create2 确保 Pair 地址是可预测的（与 init_code_hash 配合）
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        // 初始化交易对
        UniswapV2Pair(pair).initialize(token0_, token1_);

        // 双向映射
        getPair[token0_][token1_] = pair;
        getPair[token1_][token0_] = pair;

        // 记录到数组
        allPairs.push(pair);

        emit PairCreated(token0_, token1_, pair, allPairs.length);
    }

    /// @notice 设置协议费接收地址
    function setFeeTo(address _feeTo) external override {
        require(msg.sender == feeToSetter, "UniswapV2: FORBIDDEN");
        feeTo = _feeTo;
    }

    /// @notice 设置 feeToSetter
    function setFeeToSetter(address _feeToSetter) external override {
        require(msg.sender == feeToSetter, "UniswapV2: FORBIDDEN");
        feeToSetter = _feeToSetter;
    }
}

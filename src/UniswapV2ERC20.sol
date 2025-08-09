// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import './interfaces/IUniswapV2ERC20.sol';

/**
 * @title UniswapV2ERC20
 * @dev Uniswap V2 的 LP Token 实现（ERC20 + EIP-2612 Permit）
 * 每个交易对（Pair）都会部署一个该合约实例，代表 LP Token
 */
contract UniswapV2ERC20 is IUniswapV2ERC20 {
    // ======== ERC20 基础信息 ========
    string public constant override name = 'Uniswap V2'; // Token 名称
    string public constant override symbol = 'UNI-V2';   // Token 符号
    uint8 public constant override decimals = 18;        // 精度
    uint public override totalSupply;                    // 总供应量

    // 余额和授权
    mapping(address => uint) public override balanceOf;                  // 每个账户余额
    mapping(address => mapping(address => uint)) public override allowance; // 授权额度

    // ======== EIP-2612 Permit 相关 ========
    bytes32 public override DOMAIN_SEPARATOR; // EIP-712 域分隔符
    bytes32 public constant override PERMIT_TYPEHASH =
        0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9; // permit() 类型哈希
    mapping(address => uint) public override nonces; // 每个账户的签名次数（防重放攻击）

    /**
     * @dev 构造函数中初始化 DOMAIN_SEPARATOR
     * 使用 EIP-712 标准生成，确保签名只在当前链 ID 和合约地址下有效
     */
    constructor() {
        uint chainId = block.chainid; // 获取当前链 ID
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    'EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'
                ),
                keccak256(bytes(name)), // Token 名称哈希
                keccak256(bytes('1')),  // 版本号哈希
                chainId,                // 链 ID
                address(this)           // 合约地址
            )
        );
    }

    // ======== 内部 Mint 方法 ========
    function _mint(address to, uint value) internal {
        totalSupply += value;
        balanceOf[to] += value;
        emit Transfer(address(0), to, value); // 标准 ERC20 Mint 事件
    }

    // ======== 内部 Burn 方法 ========
    function _burn(address from, uint value) internal {
        balanceOf[from] -= value;
        totalSupply -= value;
        emit Transfer(from, address(0), value);
    }

    // ======== 内部 Approve 方法 ========
    function _approve(address owner, address spender, uint value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    // ======== 内部 Transfer 方法 ========
    function _transfer(address from, address to, uint value) private {
        balanceOf[from] -= value;
        balanceOf[to] += value;
        emit Transfer(from, to, value);
    }

    // ======== 对外授权 ========
    function approve(address spender, uint value) external override returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    // ======== 对外转账 ========
    function transfer(address to, uint value) external override returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    // ======== 从他人账户转账（需授权） ========
    function transferFrom(address from, address to, uint value) external override returns (bool) {
        uint currentAllowance = allowance[from][msg.sender];
        // 如果不是无限授权，则检查额度并减少
        if (currentAllowance != type(uint).max) {
            require(currentAllowance >= value, "ERC20: transfer amount exceeds allowance");
            allowance[from][msg.sender] = currentAllowance - value;
        }
        _transfer(from, to, value);
        return true;
    }

    /**
     * @dev EIP-2612 Permit
     * 允许用户用签名直接授权，而不需要先发一笔 approve 交易
     * @param owner 授权人
     * @param spender 被授权地址
     * @param value 授权额度
     * @param deadline 签名有效期
     * @param v,r,s ECDSA 签名参数
     */
    function permit(
        address owner,
        address spender,
        uint value,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        require(deadline >= block.timestamp, 'UniswapV2: EXPIRED');

        // 构造 EIP-712 结构化数据哈希
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline)
                )
            )
        );

        // 从签名中恢复出地址
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(
            recoveredAddress != address(0) && recoveredAddress == owner,
            'UniswapV2: INVALID_SIGNATURE'
        );

        // 执行授权
        _approve(owner, spender, value);
    }
}

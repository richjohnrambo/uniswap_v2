pragma solidity >=0.5.16;

import '../src/UniswapV2ERC20.sol';

contract ERC20 is UniswapV2ERC20 {
    constructor(uint _totalSupply) {
        _mint(msg.sender, _totalSupply);
    }

     function mint(address to, uint amount) external {
        _mint(to, amount);
    }
}

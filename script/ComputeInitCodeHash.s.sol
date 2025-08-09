// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/UniswapV2Pair.sol";

contract ComputeInitCodeHash is Script {
    function run() public {
        bytes memory creationCode = type(UniswapV2Pair).creationCode;
        bytes32 initCodeHash = keccak256(creationCode);
        console.logBytes32(initCodeHash);
    }

    //  function run() public {
    //     vm.startBroadcast();

    //     counter = new Counter();

    //     vm.stopBroadcast();
    // }
}

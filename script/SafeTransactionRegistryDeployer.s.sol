// SPDX-License-Identifier: GNU GPLv3
pragma solidity >=0.8.19 <=0.9.0;

import { Script } from "forge-std/Script.sol";

import { SafeTransactionRegistry } from "../src/SafeTransactionRegistry.sol";

contract SeaportDeployer is Script {
    address private constant SAFE_SINGLETON_FACTORY = 0x914d7Fec6aaC8cd542e72Bca78B30650d45643d7;
    address private constant STR_ADDRESS;

    function run() public {
        bytes32 salt;

        bytes memory deployCall = abi.encodePacked(salt, type(SafeTransactionRegistry).creationCode);

        address deployedStr;
        assembly { }

        assert(deployedStr == STR_ADDRESS);

        vm.stopBroadcast();
    }
}

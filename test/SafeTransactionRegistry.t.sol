// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { PRBTest } from "@prb/test/PRBTest.sol";
import { console2 } from "forge-std/console2.sol";
import { StdCheats } from "forge-std/StdCheats.sol";

import { SafeTransactionRegistry, SafeTransaction } from "../src/SafeTransactionRegistry.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

/// @dev If this is your first time with Forge, read this tutorial in the Foundry Book:
/// https://book.getfoundry.sh/forge/writing-tests
contract SafeTransactionRegistryTest is PRBTest, StdCheats {
    SafeTransactionRegistry internal STRegistry;

    /// @dev A function invoked before each test case is run.
    function setUp() public virtual {
        // Instantiate the contract-under-test.
        STRegistry = new SafeTransactionRegistry();
    }

    function test_registerSafeTransaction() public {
        SafeTransaction memory safeTransaction = SafeTransaction({
            to: address(0x1),
            value: 0,
            data: bytes(""),
            operation: 0,
            safeTxGas: 0,
            baseGas: 0,
            gasPrice: 0,
            gasToken: address(0x1),
            refundReceiver: address(0x1),
            signatures: bytes("")
        });

        STRegistry.registerSafeTransaction(address(0x1), 0, safeTransaction);
    }
}

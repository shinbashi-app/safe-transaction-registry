// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { PRBTest } from "@prb/test/PRBTest.sol";
import { console2 } from "forge-std/console2.sol";
import { StdCheats } from "forge-std/StdCheats.sol";
import { MockContract } from "mock-contract/MockContract.sol";

import { SafeTransactionRegistry, SafeTransaction, ISafe } from "../src/SafeTransactionRegistry.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

/// @dev If this is your first time with Forge, read this tutorial in the Foundry Book:
/// https://book.getfoundry.sh/forge/writing-tests
contract SafeTransactionRegistryTest is PRBTest, StdCheats {
    SafeTransactionRegistry internal STRegistry;
    MockContract internal mock;

    /// @dev A function invoked before each test case is run.
    function setUp() public virtual {
        // Instantiate the contract-under-test.
        STRegistry = new SafeTransactionRegistry();
        mock = new MockContract();
    }

    function test_registersSafeTransaction(bytes32 transactionHash) public {
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

        bytes memory getTransactionHashCalldata = abi.encodeWithSelector(
            ISafe.getTransactionHash.selector,
            safeTransaction.to,
            safeTransaction.value,
            safeTransaction.data,
            safeTransaction.operation,
            safeTransaction.safeTxGas,
            safeTransaction.baseGas,
            safeTransaction.gasPrice,
            safeTransaction.gasToken,
            safeTransaction.refundReceiver,
            0
        );
        bytes memory checkSigsCalldata =
            abi.encodeWithSelector(ISafe.checkNSignatures.selector, transactionHash, "", safeTransaction.signatures, 1);
        mock.givenCalldataReturnBytes32(getTransactionHashCalldata, transactionHash);
        mock.givenCalldataReturn(checkSigsCalldata, "");

        STRegistry.registerSafeTransaction(address(mock), 0, safeTransaction);
    }

    function test_registerSafeTransactionSigCheckFails(bytes32 transactionHash) public {
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

        bytes memory getTransactionHashCalldata = abi.encodeWithSelector(
            ISafe.getTransactionHash.selector,
            safeTransaction.to,
            safeTransaction.value,
            safeTransaction.data,
            safeTransaction.operation,
            safeTransaction.safeTxGas,
            safeTransaction.baseGas,
            safeTransaction.gasPrice,
            safeTransaction.gasToken,
            safeTransaction.refundReceiver,
            0
        );
        bytes memory checkSigsCalldata =
            abi.encodeWithSelector(ISafe.checkNSignatures.selector, transactionHash, "", safeTransaction.signatures, 1);
        mock.givenCalldataReturnBytes32(getTransactionHashCalldata, transactionHash);
        mock.givenCalldataRevert(checkSigsCalldata);

        STRegistry.registerSafeTransaction(address(mock), 0, safeTransaction);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { PRBTest } from "@prb/test/PRBTest.sol";
import { console2 } from "forge-std/console2.sol";
import { StdCheats } from "forge-std/StdCheats.sol";
import { SafeL2 } from "safe-contracts/contracts/SafeL2.sol";
import { Enum } from "safe-contracts/contracts/common/Enum.sol";
import { MockContract } from "mock-contract/MockContract.sol";

import {
    SafeTransactionRegistry,
    SafeTransaction,
    SafeTransactionSignature,
    ISafe
} from "../src/SafeTransactionRegistry.sol";
import { TestUtils } from "./TestUtils.t.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

/// @dev If this is your first time with Forge, read this tutorial in the Foundry Book:
/// https://book.getfoundry.sh/forge/writing-tests
contract SafeTransactionRegistryTest is PRBTest, StdCheats {
    SafeTransactionRegistry internal STRegistry;
    TestUtils internal testUtils;
    SafeL2 internal safe;
    Account internal owner1;
    Account internal owner2;
    Account internal owner3;

    /// @dev A function invoked before each test case is run.
    function setUp() public virtual {
        // Instantiate the contract-under-test.
        STRegistry = new SafeTransactionRegistry();
        testUtils = new TestUtils();

        owner1 = makeAccount("owner1");
        owner2 = makeAccount("owner2");
        owner3 = makeAccount("owner3");

        address[] memory owners = new address[](2);
        owners[0] = owner1.addr;
        owners[1] = owner2.addr;

        safe = SafeL2(
            testUtils.deploySafe(
                owners, 1, address(0), bytes(""), testUtils.handler.address, address(0), 0, payable(address(0))
            )
        );
    }

    function test_registersSafeTransaction(bytes32 transactionHash) public { }

    function test_registersSafeTransaction() public {
        bytes32 transactionHash = safe.getTransactionHash(
            address(0x73), 73, bytes("0xbeef"), Enum.Operation.Call, 73, 73, 73, address(0x73), address(0x73), 0
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(owner1.key, transactionHash);
        SafeTransactionSignature[] memory signatures = new SafeTransactionSignature[](1);
        signatures[0] = SafeTransactionSignature({ v: v, r: r, s: s, dynamicPart: bytes("") });

        SafeTransaction memory safeTransaction = SafeTransaction({
            to: address(0x73),
            value: 73,
            data: bytes("0xbeef"),
            operation: 0,
            safeTxGas: 73,
            baseGas: 73,
            gasPrice: 73,
            gasToken: address(0x73),
            refundReceiver: address(0x73),
            safeTxHash: transactionHash,
            signatures: signatures
        });

        STRegistry.registerSafeTransaction(ISafe(address(safe)), 0, safeTransaction);

        SafeTransaction memory registeredSafeTransaction = STRegistry.getTransaction(address(safe), 0, 0);

        assert(testUtils.equals(safeTransaction, registeredSafeTransaction));
    }

    function test_registerSafeTransactionSigCheckFailsWithBadSafeTxHash(
        bytes32 hash,
        bytes32 r,
        bytes32 s,
        uint8 v
    )
        public
    {
        SafeTransactionSignature[] memory signatures = new SafeTransactionSignature[](1);
        signatures[0] = SafeTransactionSignature({ v: v, r: r, s: s, dynamicPart: bytes("") });

        SafeTransaction memory safeTransaction = SafeTransaction({
            to: address(0x73),
            value: 73,
            data: bytes("0xbeef"),
            operation: 0,
            safeTxGas: 73,
            baseGas: 73,
            gasPrice: 73,
            gasToken: address(0x73),
            refundReceiver: address(0x73),
            signatures: signatures,
            safeTxHash: hash
        });

        vm.expectRevert("Transaction hash does not match");
        STRegistry.registerSafeTransaction(ISafe(address(safe)), 0, safeTransaction);
    }

    function test_registerSafeTransactionSigCheckFailsWithEmptySignatures() public {
        SafeTransactionSignature[] memory signatures = new SafeTransactionSignature[](0);

        bytes32 transactionHash = safe.getTransactionHash(
            address(0x73), 73, bytes("0xbeef"), Enum.Operation.Call, 73, 73, 73, address(0x73), address(0x73), 0
        );

        SafeTransaction memory safeTransaction = SafeTransaction({
            to: address(0x73),
            value: 73,
            data: bytes("0xbeef"),
            operation: 0,
            safeTxGas: 73,
            baseGas: 73,
            gasPrice: 73,
            gasToken: address(0x73),
            refundReceiver: address(0x73),
            signatures: signatures,
            safeTxHash: transactionHash
        });

        vm.expectRevert("Signatures must not be empty");
        STRegistry.registerSafeTransaction(ISafe(address(safe)), 0, safeTransaction);
    }

    function test_registerSafeTransactionSigCheckFailsWithBadSignatures(bytes32 r, bytes32 s, uint8 v) public {
        SafeTransactionSignature[] memory signatures = new SafeTransactionSignature[](1);
        signatures[0] = SafeTransactionSignature({ v: v, r: r, s: s, dynamicPart: bytes("") });

        bytes32 transactionHash = safe.getTransactionHash(
            address(0x73), 73, bytes("0xbeef"), Enum.Operation.Call, 73, 73, 73, address(0x73), address(0x73), 0
        );

        SafeTransaction memory safeTransaction = SafeTransaction({
            to: address(0x73),
            value: 73,
            data: bytes("0xbeef"),
            operation: 0,
            safeTxGas: 73,
            baseGas: 73,
            gasPrice: 73,
            gasToken: address(0x73),
            refundReceiver: address(0x73),
            signatures: signatures,
            safeTxHash: transactionHash
        });

        vm.expectRevert();
        STRegistry.registerSafeTransaction(ISafe(address(safe)), 0, safeTransaction);
    }

    function test_encodeSignatures() public { }
}

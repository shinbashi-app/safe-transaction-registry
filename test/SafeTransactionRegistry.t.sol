// SPDX-License-Identifier: GNU GPLv3
pragma solidity >=0.8.19 <0.9.0;

import { PRBTest } from "@prb/test/PRBTest.sol";
import { console2 } from "forge-std/console2.sol";
import { StdCheats } from "forge-std/StdCheats.sol";
import { StdStorage, stdStorage } from "forge-std/StdStorage.sol";
import { SafeL2 } from "safe-contracts/contracts/SafeL2.sol";
import { CompatibilityFallbackHandler } from "safe-contracts/contracts/handler/CompatibilityFallbackHandler.sol";
import { Enum } from "safe-contracts/contracts/common/Enum.sol";
import { MockContract } from "mock-contract/MockContract.sol";

import {
    SafeTransactionRegistry,
    SafeTransaction,
    SafeTransactionSignature,
    ISafe
} from "../src/SafeTransactionRegistry.sol";
import { TestUtils } from "./TestUtils.t.sol";
import { SafeTransactionRegistryHarness } from "./STRHarness.t.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

/// @dev If this is your first time with Forge, read this tutorial in the Foundry Book:
/// https://book.getfoundry.sh/forge/writing-tests
contract SafeTransactionRegistryTest is PRBTest, StdCheats {
    using stdStorage for StdStorage;

    StdStorage internal stdstorage;

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
                owners, 1, address(0), bytes(""), address(testUtils.handler()), address(0), 0, payable(address(0))
            )
        );
    }

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

    function test_registersSafeTransactionMultipleSignatureTypes() public {
        address[] memory owners = new address[](3);
        owners[0] = owner1.addr;
        owners[1] = owner2.addr;
        owners[2] = address(safe);

        SafeL2 testSafe = SafeL2(
            testUtils.deploySafe(
                owners, 3, address(0), bytes(""), address(testUtils.handler()), address(0), 0, payable(address(0))
            )
        );

        bytes32 transactionHash = testSafe.getTransactionHash(
            address(0x73), 73, bytes("0xbeef"), Enum.Operation.Call, 73, 73, 73, address(0x73), address(0x73), 0
        );

        SafeTransactionSignature[] memory signatures = new SafeTransactionSignature[](3);
        // The signatures have to be sorted by the signer address, currently it's done manually here
        // That's rather silly, because the addresses may easily change (e.g., if we change the configuration of the
        // owner safe)
        // But cba to do it properly now

        bytes32 messageHash = testUtils.getMessageHashForSafe(payable(safe), abi.encodePacked(transactionHash));
        (uint8 v1, bytes32 r1, bytes32 s1) = vm.sign(owner2.key, messageHash);
        signatures[0] = SafeTransactionSignature({
            v: 0,
            r: bytes32(uint256(uint160(address(safe)))),
            s: bytes32(0),
            dynamicPart: abi.encodePacked(r1, s1, v1)
        });

        vm.prank(owner2.addr);
        testSafe.approveHash(transactionHash);
        signatures[1] = SafeTransactionSignature({
            v: 1,
            r: bytes32(uint256(uint160(owner2.addr))),
            s: bytes32(0),
            dynamicPart: bytes("")
        });
        assertEq(1, testSafe.approvedHashes(owner2.addr, transactionHash));

        (uint8 v2, bytes32 r2, bytes32 s2) = vm.sign(owner1.key, transactionHash);
        signatures[2] = SafeTransactionSignature({ v: v2, r: r2, s: s2, dynamicPart: bytes("") });

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

        STRegistry.registerSafeTransaction(ISafe(address(testSafe)), 0, safeTransaction);

        SafeTransaction memory registeredSafeTransaction = STRegistry.getTransaction(address(testSafe), 0, 0);

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

    function test_registerSafeTransactionSigCheckFailsWithBadNonce() public {
        stdstorage.target(address(safe)).sig("nonce()").checked_write(73);

        bytes32 transactionHash = safe.getTransactionHash(
            address(0x73), 73, bytes("0xbeef"), Enum.Operation.Call, 73, 73, 73, address(0x73), address(0x73), 1
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

        vm.expectRevert("Nonce is too low");
        STRegistry.registerSafeTransaction(ISafe(address(safe)), 1, safeTransaction);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

struct SafeTransaction {
    address to;
    uint256 value;
    bytes data;
    uint8 operation;
    uint256 safeTxGas;
    uint256 baseGas;
    uint256 gasPrice;
    address gasToken;
    address refundReceiver;
    bytes signatures;
}

interface ISafe {
    function checkNSignatures(
        bytes32 dataHash,
        bytes memory, /* data */
        bytes memory signatures,
        uint256 requiredSignatures
    )
        external;

    function getTransactionHash(
        address to,
        uint256 value,
        bytes calldata data,
        uint8 operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address refundReceiver,
        uint256 _nonce
    )
        external
        view
        returns (bytes32);
}

contract SafeTransactionRegistry {
    mapping(address safe => mapping(uint256 nonce => SafeTransaction[])) public transactions;

    constructor() { }

    function registerSafeTransaction(address safe, uint256 nonce, SafeTransaction memory safeTransaction) external {
        ISafe safeContract = ISafe(safe);

        bytes32 transactionHash = safeContract.getTransactionHash(
            safeTransaction.to,
            safeTransaction.value,
            safeTransaction.data,
            safeTransaction.operation,
            safeTransaction.safeTxGas,
            safeTransaction.baseGas,
            safeTransaction.gasPrice,
            safeTransaction.gasToken,
            safeTransaction.refundReceiver,
            nonce
        );
        safeContract.checkNSignatures(transactionHash, "", safeTransaction.signatures, 1);

        transactions[safe][nonce].push(safeTransaction);
    }

    function registerTransactionSignature(
        address safe,
        uint256 nonce,
        uint256 index,
        bytes memory signature
    )
        external
    {
        SafeTransaction storage safeTransaction = transactions[safe][nonce][index];
        safeTransaction.signatures = abi.encodePacked(safeTransaction.signatures, signature);
    }
}

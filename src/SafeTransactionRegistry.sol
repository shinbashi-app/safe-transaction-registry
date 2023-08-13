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
    /**
     * @notice Reads `length` bytes of storage in the currents contract
     * @param offset - the offset in the current contract's storage in words to start reading from
     * @param length - the number of words (32 bytes) of data to read
     * @return the bytes that were read.
     */
    function getStorageAt(uint256 offset, uint256 length) external view returns (bytes memory);

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

        require(getSafeNonce(safeContract) <= nonce, "Nonce is too low");

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

    function getTransaction(
        address safe,
        uint256 nonce,
        uint256 index
    )
        external
        view
        returns (SafeTransaction memory)
    {
        return transactions[safe][nonce][index];
    }

    function getStorageAt(uint256 offset, uint256 length) public view returns (bytes memory) {
        bytes memory result = new bytes(length * 32);
        for (uint256 index = 0; index < length; index++) {
            // solhint-disable-next-line no-inline-assembly
            /// @solidity memory-safe-assembly
            assembly {
                let word := sload(add(offset, index))
                mstore(add(add(result, 0x20), mul(index, 0x20)), word)
            }
        }
        return result;
    }

    function getSafeNonce(ISafe safe) internal view returns (uint256 nonce) {
        bytes memory nonceBytes = safe.getStorageAt(5, 1);

        assembly {
            nonce := mload(add(nonceBytes, 0x20))
        }
    }
}

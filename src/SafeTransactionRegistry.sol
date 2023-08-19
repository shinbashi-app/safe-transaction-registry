// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

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
    bytes32 safeTxHash;
    SafeTransactionSignature[] signatures;
}

struct SafeTransactionSignature {
    uint8 v;
    bytes32 r;
    bytes32 s;
    bytes dynamicPart;
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

    uint8 public constant SIGNATURE_LENGTH_BYTES = 65;

    constructor() { }

    function registerSafeTransaction(ISafe safe, uint256 nonce, SafeTransaction memory safeTransaction) external {
        require(getSafeNonce(safe) <= nonce, "Nonce is too low");

        bytes32 transactionHash = safe.getTransactionHash(
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
        bytes memory signatures = encodeSignatures(safeTransaction.signatures);
        safe.checkNSignatures(transactionHash, "", signatures, safeTransaction.signatures.length);

        transactions[address(safe)][nonce].push(safeTransaction);
    }

    function getTransaction(address safe, uint256 nonce, uint256 index) public view returns (SafeTransaction memory) {
        return transactions[safe][nonce][index];
    }

    function registerTransactionSignatures(
        ISafe safe,
        uint256 nonce,
        uint256 index,
        SafeTransactionSignature calldata signatures
    )
        external
    {
        ISafe safeContract = ISafe(safe);
        SafeTransaction storage safeTransaction = transactions[address(safe)][nonce][index];

        bytes memory signaturesBytes = encodeSignatures(safeTransaction.signatures);
        safeContract.checkNSignatures(
            safeTransaction.safeTxHash, "", signaturesBytes, safeTransaction.signatures.length
        );

        safeTransaction.signatures.push(signatures);
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

    /**
     * @notice Encodes signatures into bytes
     * @dev Signatures must be sorted by signer address, case-insensitive
     * @param signatures - array of signatures
     * @return signatures in bytes
     */
    function encodeSignatures(SafeTransactionSignature[] memory signatures) internal pure returns (bytes memory) {
        bytes memory signatureBytes;
        bytes memory dynamicBytes;
        for (uint256 i = 0; i < signatures.length; i++) {
            if (signatures[i].dynamicPart.length > 0) {
                /* 
                A contract signature has a static part of 65 bytes and the dynamic part that needs to be appended at the
                end of signature bytes.
                The signature format is
                Signature type == 0
                Constant part: 65 bytes
                {32-bytes signature verifier}{32-bytes dynamic data position}{1-byte signature type}
                Dynamic part (solidity bytes): 32 bytes + signature data length
                {32-bytes signature length}{bytes signature data}
            */
                bytes32 dynamicPartPosition = bytes32(signatures.length * SIGNATURE_LENGTH_BYTES + dynamicBytes.length);
                bytes32 dynamicPartLength = bytes32(signatures[i].dynamicPart.length);
                bytes memory staticSignature = abi.encodePacked(signatures[i].r, dynamicPartPosition, signatures[i].v);
                bytes memory dynamicPartWithLength = abi.encodePacked(dynamicPartLength, signatures[i].dynamicPart);

                signatureBytes = abi.encodePacked(signatureBytes, staticSignature);
                dynamicBytes = abi.encodePacked(dynamicBytes, dynamicPartWithLength);
            } else {
                signatureBytes = abi.encodePacked(signatureBytes, signatures[i].r, signatures[i].s);
            }
        }

        return abi.encodePacked(signatureBytes, dynamicBytes);
    }
}

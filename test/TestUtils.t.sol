// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { SafeTransactionRegistry, SafeTransaction, ISafe } from "../src/SafeTransactionRegistry.sol";

contract TestUtils {
    function equals(
        SafeTransaction memory firstTransaction,
        SafeTransaction memory secondTransaction
    )
        public
        pure
        returns (bool)
    {
        return (
            keccak256(
                abi.encodePacked(
                    firstTransaction.to,
                    firstTransaction.value,
                    firstTransaction.data,
                    firstTransaction.operation,
                    firstTransaction.safeTxGas,
                    firstTransaction.baseGas,
                    firstTransaction.gasPrice,
                    firstTransaction.gasToken,
                    firstTransaction.refundReceiver
                )
            )
                == keccak256(
                    abi.encodePacked(
                        secondTransaction.to,
                        secondTransaction.value,
                        secondTransaction.data,
                        secondTransaction.operation,
                        secondTransaction.safeTxGas,
                        secondTransaction.baseGas,
                        secondTransaction.gasPrice,
                        secondTransaction.gasToken,
                        secondTransaction.refundReceiver
                    )
                )
        );
    }
}

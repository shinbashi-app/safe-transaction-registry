// SPDX-License-Identifier: GNU GPLv3
pragma solidity >=0.8.19 <0.9.0;

import { SafeTransactionRegistry, SafeTransaction, ISafe } from "../src/SafeTransactionRegistry.sol";
import { SafeProxyFactory } from "safe-contracts/contracts/proxies/SafeProxyFactory.sol";
import { Safe, SafeL2 } from "safe-contracts/contracts/SafeL2.sol";
import { CompatibilityFallbackHandler } from "safe-contracts/contracts/handler/CompatibilityFallbackHandler.sol";

contract TestUtils {
    SafeL2 public safeSingleton = new SafeL2();
    SafeProxyFactory public factory = new SafeProxyFactory();
    CompatibilityFallbackHandler public handler = new CompatibilityFallbackHandler();

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

    function deploySafe(
        address[] calldata owners,
        uint256 threshold,
        address to,
        bytes calldata data,
        address fallbackHandler,
        address paymentToken,
        uint256 payment,
        address payable paymentReceiver
    )
        public
        returns (address payable safe)
    {
        safe = payable(
            factory.createProxyWithNonce(
                address(safeSingleton),
                abi.encodeWithSelector(
                    safeSingleton.setup.selector,
                    owners,
                    threshold,
                    to,
                    data,
                    fallbackHandler,
                    paymentToken,
                    payment,
                    paymentReceiver
                ),
                0
            )
        );
    }

    function getMessageHashForSafe(
        address payable safe,
        bytes calldata message
    )
        public
        view
        returns (bytes32 messageHash)
    {
        messageHash = handler.getMessageHashForSafe(Safe(safe), message);
    }
}

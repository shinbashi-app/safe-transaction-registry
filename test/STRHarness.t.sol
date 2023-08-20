import {
    SafeTransactionRegistry,
    SafeTransaction,
    SafeTransactionSignature,
    ISafe
} from "../src/SafeTransactionRegistry.sol";

contract SafeTransactionRegistryHarness is SafeTransactionRegistry {
    function encodeSignaturesPublic(SafeTransactionSignature[] memory signatures) public pure returns (bytes memory) {
        return encodeSignatures(signatures);
    }
}

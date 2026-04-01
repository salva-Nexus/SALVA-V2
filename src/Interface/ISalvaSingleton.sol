// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

interface ISalvaSingleton {
    /**
     * @notice Registers a unique namespace to a specific registry contract address.
     * @param registry The registry address to query.
     * @param namespaceHandle The bytes16 namespace assigned to this registry.
     * @param namespaceLength The length of the assigned namespace.
     */
    function initializeRegistry(address registry, bytes16 namespaceHandle, bytes1 namespaceLength)
        external
        returns (bool);

    /**
     * @notice Welds a name and namespace into a bytes32 alias and links it to a wallet or account number.
     * @dev Uses onlyOneLinkToData modifier logic internally to ensure mutual exclusivity.
     */
    function linkNameAlias(bytes calldata name, address wallet, uint256 accountNumber) external returns (bool isLinked);

    /**
     * @notice Removes the link between a welded name alias and its associated data.
     */
    function unlink(bytes calldata name) external returns (bool isUnlinked);

    /**
     * @notice Retrieves the wallet address associated with a name containing a namespace.
     * @param aliasName The full name including the namespace (e.g., "charles_okoronkwo@salva").
     */
    function resolveAddress(bytes calldata aliasName) external view returns (address wallet);

    /**
     * @notice Retrieves the account number associated with a name containing a namespace.
     * @param aliasName The full name including the namespace.
     */
    function resolveNumber(bytes calldata aliasName) external view returns (uint256 accountNumber);

    /**
     * @notice Checks the registered namespace and length of a registry contract.
     */
    function namespace(address registry) external view returns (bytes16 namespaceHandle, bytes1 namespaceLength);
}

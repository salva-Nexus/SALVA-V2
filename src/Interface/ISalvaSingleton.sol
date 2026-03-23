// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title ISalvaSingleton
 * @notice Interface for the core Salva naming and namespace management system.
 */
interface ISalvaSingleton {
    /// @notice Registers a unique namespace to a specific registry contract address.
    function initializeRegistry(address _registry, bytes16 _nspace) external returns (bool);

    /// @notice Welds a name and namespace into a bytes32 alias and links it to a wallet.
    function linkNameAlias(string memory _name, address _wallet) external returns (bool _isLinked);

    /// @notice Removes the link between a welded name alias and its associated wallet.
    function unlinkName(string memory _name) external returns (bool _isUnlinked);

    /// @notice Maps a uint128 number within a namespace to a specific wallet address.
    function linkNumberAlias(uint128 _num, address _wallet) external returns (bool _isLinked);

    /// @notice Clears the mapping for a specific number alias within the caller's namespace.
    function unlinkNumber(uint128 _num) external returns (bool _isUnlinked);

    /// @notice Retrieves the wallet address associated with a namespace-prefixed number.
    function resolveAddressViaNumber(uint128 _num, bytes16 _namespace) external view returns (address _wallet);

    /// @notice Returns the wallet address linked to a pre-welded bytes32 name alias.
    function resolveAddressViaName(bytes32 _name) external view returns (address _wallet);

    /// @notice Checks the registered namespace and initialization status of a registry contract.
    function namespace(address _registry) external view returns (bytes16 _nspace, bool _initialized);
}

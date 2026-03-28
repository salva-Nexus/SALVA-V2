// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {MultiSigModifier} from "@MultiSigModifier/MultiSigModifier.sol";

abstract contract MultiSigHelper is MultiSigModifier {
    ////////////////////////////////////////////////////////////////////////////////////////
    //                                      HELPERS                                       //
    ////////////////////////////////////////////////////////////////////////////////////////

    function _registryValidationCountRemains(address registry) external view returns (uint256) {
        Registry storage reg = _registry[registry];
        return uint256(reg.remaining);
    }

    function _validatorValidationCountRemains(address _addr) external view returns (uint256) {
        ValidatorUpdateRequest storage update = _updateValidator[_addr];
        return uint256(update.remaining);
    }

    function _hasValidatedRegistry(address registry) external view returns (bool) {
        Registry storage reg = _registry[registry];
        return reg.hasValidated[sender()];
    }

    function _hasValidatedValidatorUpdate(address _addr) external view returns (bool) {
        ValidatorUpdateRequest storage update = _updateValidator[_addr];
        return update.hasValidated[sender()];
    }

    function _isRecovery(address recovery) external view returns (bool) {
        return _recovery[recovery];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Errors } from "@Errors/Errors.sol";
import { Setup } from "@Setup/Setup.t.sol";
import { Vm } from "forge-std/Vm.sol";

contract RegistryProposal is Setup {
    function test_Registry_Proposal_Success() external {
        _changePrank(owner);
        (address clone,,) =
            multisig.proposeInitRegistry("@coinbase", address(singleton), address(factory));

        multisig.validateRegistryInit(clone);
        multisig.executeInitRegistry(clone);
    }

    function test_Cannot_Propose_Again_After_First_Proposal() external {
        _changePrank(owner);
        (address clone,,) =
            multisig.proposeInitRegistry("@coinbase", address(singleton), address(factory));

        multisig.validateRegistryInit(clone);
        multisig.executeInitRegistry(clone);

        (address clone2,,) =
            multisig.proposeInitRegistry("@coinbase", address(singleton), address(factory));

        assertNotEq(clone, clone2);
    }

    function test_Events() external {
        vm.recordLogs();
        multisig.proposeInitRegistry("@coinbase", address(singleton), address(factory));

        Vm.Log[] memory entries = vm.getRecordedLogs();
        address expectedClone = address(uint160(uint256(entries[0].topics[1])));
        bytes memory data = entries[0].data;

        uint256 vCount = multisig.registryInitVotesRemaining(expectedClone);

        (string memory nspace, uint256 required) = abi.decode(data, (string, uint256));

        assertEq(vCount, required);
        assertEq(nspace, "@coinbase");
    }
}

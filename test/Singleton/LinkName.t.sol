// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Errors } from "@Errors/Errors.sol";
import { Setup } from "@Setup/Setup.t.sol";

contract LinkName is Setup {
    function test_link_Name() external initialized {
        bytes memory name = bytes("abcdefghijklmnoprqstuvwxyz234567");
        uint256 sCount;
        uint256 fCount;

        bytes memory _name = new bytes(31);
        for (uint256 i = 0; i < 31;) {
            _name[i] = name[i];
            assembly ("memory-safe") {
                mstore(_name, add(i, 1))
            }

            _start(_name, owner, owner, owner, 0);
            try singleton.resolveAddress(bytes(abi.encodePacked(_name, "@salva"))) {
                sCount++;
            } catch {
                fCount++;
            }

            assembly ("memory-safe") {
                mstore(_name, 0x20)
            }

            unchecked {
                i++;
            }
        }
        assertEq(sCount, 31);
        assertEq(fCount, 0);
    }

    function test_Name_Not_Exceeding_32_Bytes() external initialized {
        bytes memory _name = bytes("my_name_is_long_and_cause_this_to_revert");
        bytes4 expectedRevert = Errors.Errors__MaxNameLengthExceeded.selector;
        _start(_name, owner, owner, owner, expectedRevert);
    }

    function test_link_From_External_Source() external initialized {
        // SHOULD REVERT
        bytes memory _name = bytes("cboi");
        bytes4 revertSelector = Errors.Errors__InvalidCallSource.selector;
        _start(_name, EOA, EOA, EOA, revertSelector);
    }

    function test_Phishing_Resistance(string memory _rNames) external initialized {
        vm.assume(bytes(_rNames).length > 0 && bytes(_rNames).length <= 31);
        for (uint256 i = 0; i < bytes(_rNames).length;) {
            bytes1 char = bytes(_rNames)[i];
            vm.assume((char < 0x32 && char > 0x39) || (char < 0x61 && char > 0x7A) || char != 0x5F);

            unchecked {
                i++;
            }
        }

        _changePrank(owner);
        _transfer(makeAddr("EOA2"));

        _changePrank(makeAddr("EOA2"));
        bytes memory _name0 = bytes(unicode"cbоi");
        bytes4 revertSelector = Errors.Errors__InvalidCharacter.selector;
        _start(_name0, makeAddr("EOA2"), owner, makeAddr("EOA2"), revertSelector);

        bytes memory _name1 = bytes("_rNames");
        _start(_name1, makeAddr("EOA2"), owner, makeAddr("EOA2"), revertSelector);

        bytes memory _name2 = bytes("cboi_");
        bytes4 revertSelector2 = Errors.Errors__InvalidSubNameFormat.selector;
        _start(_name2, makeAddr("EOA2"), owner, makeAddr("EOA2"), revertSelector2);

        bytes memory _name3 = bytes("_cboi");
        _start(_name3, makeAddr("EOA2"), owner, makeAddr("EOA2"), revertSelector2);
    }

    function test_Double_Linking(bytes32 _rBytes, uint8 _len) external initialized {
        vm.assume(_len > 0 && _len <= 31);
        bytes memory validChars = "abcdefghijklmnopqrstuvwxyz23456789";

        bytes memory _rName = new bytes(_len);
        for (uint256 i = 0; i < _len;) {
            _rName[i] = validChars[uint256(uint8(_rBytes[i])) % bytes(validChars).length];

            unchecked {
                i++;
            }
        }

        _start(_rName, owner, owner, owner, 0);
        _transfer(EOA);

        bytes4 expectedRevert = Errors.Errors__NameTaken.selector;
        _start(_rName, EOA, owner, EOA, expectedRevert);

        _start(bytes("cboi_salva"), owner, owner, owner, 0);
        _start(bytes("salva_cboi"), owner, owner, owner, expectedRevert);
    }

    function test_Arbitrary() external initialized {
        // length manipulation, extra length
        // should revert, cus extra data is 0
        _changePrank(address(registry));
        bytes memory data1 =
            hex"85b830a60000000000000000000000000000000000000000000000000000000000000060000000000000000000000000f2b2ade8117d3d777a679e73e60795a7e6771f19000000000000000000000000f2b2ade8117d3d777a679e73e60795a7e6771f190000000000000000000000000000000000000000000000000000000000000012636861726c65735f6f6b6f726f6e6b776f000000000000000000000000000000";

        (bool success, bytes memory rData) = address(singleton).call(data1);
        assertEq(success, false);
        assertEq(
            keccak256(rData), keccak256(abi.encodePacked(Errors.Errors__InvalidCharacter.selector))
        );

        // Reduced length (not actual length)
        // Should revert
        bytes memory data2 =
            hex"85b830a60000000000000000000000000000000000000000000000000000000000000060000000000000000000000000f2b2ade8117d3d777a679e73e60795a7e6771f19000000000000000000000000f2b2ade8117d3d777a679e73e60795a7e6771f190000000000000000000000000000000000000000000000000000000000000010636861726c65735f6f6b6f726f6e6b776f000000000000000000000000000000";
        (bool success2, bytes memory rData2) = address(singleton).call(data2);
        assertEq(success2, false);

        assertEq(
            keccak256(rData2), keccak256(abi.encodePacked(Errors.Errors__InvalidLength.selector))
        );
    }
}

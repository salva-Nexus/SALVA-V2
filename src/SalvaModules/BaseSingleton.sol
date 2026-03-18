// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Modifier} from "@Modifier/Modifier.sol";
import {Storage} from "@Storage/Storage.sol";
import {Salt} from "@Salt/Salt.sol";

abstract contract BaseSingleton is Modifier, Storage, Salt {}

'forge clean' running (wd: /home/cboi/Blockchain-Projects/SALVA-V2)
'forge config --json' running
'forge build --build-info --skip ./test/** ./script/** --force' running (wd: /home/cboi/Blockchain-Projects/SALVA-V2)
INFO:Detectors:
Detector: incorrect-exp
Math.mulDiv(uint256,uint256,uint256) (lib/openzeppelin-contracts/contracts/utils/math/Math.sol#206-277) has bitwise-xor operator ^ instead of the exponentiation operator **: 
	 - inverse = (3 * denominator) ^ 2 (lib/openzeppelin-contracts/contracts/utils/math/Math.sol#259)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#incorrect-exponentiation
INFO:Detectors:
Detector: divide-before-multiply
Math.mulDiv(uint256,uint256,uint256) (lib/openzeppelin-contracts/contracts/utils/math/Math.sol#206-277) performs a multiplication on the result of a division:
	- denominator = denominator / twos (lib/openzeppelin-contracts/contracts/utils/math/Math.sol#244)
	- inverse = (3 * denominator) ^ 2 (lib/openzeppelin-contracts/contracts/utils/math/Math.sol#259)
Math.mulDiv(uint256,uint256,uint256) (lib/openzeppelin-contracts/contracts/utils/math/Math.sol#206-277) performs a multiplication on the result of a division:
	- denominator = denominator / twos (lib/openzeppelin-contracts/contracts/utils/math/Math.sol#244)
	- inverse *= 2 - denominator * inverse (lib/openzeppelin-contracts/contracts/utils/math/Math.sol#263)
Math.mulDiv(uint256,uint256,uint256) (lib/openzeppelin-contracts/contracts/utils/math/Math.sol#206-277) performs a multiplication on the result of a division:
	- denominator = denominator / twos (lib/openzeppelin-contracts/contracts/utils/math/Math.sol#244)
	- inverse *= 2 - denominator * inverse (lib/openzeppelin-contracts/contracts/utils/math/Math.sol#264)
Math.mulDiv(uint256,uint256,uint256) (lib/openzeppelin-contracts/contracts/utils/math/Math.sol#206-277) performs a multiplication on the result of a division:
	- denominator = denominator / twos (lib/openzeppelin-contracts/contracts/utils/math/Math.sol#244)
	- inverse *= 2 - denominator * inverse (lib/openzeppelin-contracts/contracts/utils/math/Math.sol#265)
Math.mulDiv(uint256,uint256,uint256) (lib/openzeppelin-contracts/contracts/utils/math/Math.sol#206-277) performs a multiplication on the result of a division:
	- denominator = denominator / twos (lib/openzeppelin-contracts/contracts/utils/math/Math.sol#244)
	- inverse *= 2 - denominator * inverse (lib/openzeppelin-contracts/contracts/utils/math/Math.sol#266)
Math.mulDiv(uint256,uint256,uint256) (lib/openzeppelin-contracts/contracts/utils/math/Math.sol#206-277) performs a multiplication on the result of a division:
	- denominator = denominator / twos (lib/openzeppelin-contracts/contracts/utils/math/Math.sol#244)
	- inverse *= 2 - denominator * inverse (lib/openzeppelin-contracts/contracts/utils/math/Math.sol#267)
Math.mulDiv(uint256,uint256,uint256) (lib/openzeppelin-contracts/contracts/utils/math/Math.sol#206-277) performs a multiplication on the result of a division:
	- denominator = denominator / twos (lib/openzeppelin-contracts/contracts/utils/math/Math.sol#244)
	- inverse *= 2 - denominator * inverse (lib/openzeppelin-contracts/contracts/utils/math/Math.sol#268)
Math.mulDiv(uint256,uint256,uint256) (lib/openzeppelin-contracts/contracts/utils/math/Math.sol#206-277) performs a multiplication on the result of a division:
	- low = low / twos (lib/openzeppelin-contracts/contracts/utils/math/Math.sol#247)
	- result = low * inverse (lib/openzeppelin-contracts/contracts/utils/math/Math.sol#274)
Math.invMod(uint256,uint256) (lib/openzeppelin-contracts/contracts/utils/math/Math.sol#317-363) performs a multiplication on the result of a division:
	- quotient = gcd / remainder (lib/openzeppelin-contracts/contracts/utils/math/Math.sol#339)
	- (gcd,remainder) = (remainder,gcd - remainder * quotient) (lib/openzeppelin-contracts/contracts/utils/math/Math.sol#341-348)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#divide-before-multiply
INFO:Detectors:
Detector: mapping-deletion
Upgrades.cancelUpgrade(address) (src/SalvaMultiSig/Upgrades/Upgrades.sol#101-107) deletes MultiSigStorage.UpgradeProposal (src/SalvaMultiSig/MultiSigStorage.sol#104-114) which contains a mapping:
	-delete _upgradeProposal[newImpl] (src/SalvaMultiSig/Upgrades/Upgrades.sol#104)
FactoryUpdates.cancelSignerUpdate(address) (src/SalvaMultiSig/Updates/FactoryUpdates.sol#95-101) deletes MultiSigStorage.SignerUpdateProposal (src/SalvaMultiSig/MultiSigStorage.sol#166-175) which contains a mapping:
	-delete _signerUpdateProposal[newSigner] (src/SalvaMultiSig/Updates/FactoryUpdates.sol#98)
FactoryUpdates.cancelBaseRegistryImplUpdate(address) (src/SalvaMultiSig/Updates/FactoryUpdates.sol#209-219) deletes MultiSigStorage.BaseRegistryImplUpdateProposal (src/SalvaMultiSig/MultiSigStorage.sol#192-201) which contains a mapping:
	-delete _baseRegistryImplUpdateProposal[newImpl] (src/SalvaMultiSig/Updates/FactoryUpdates.sol#216)
StateUpdates.cancelUnpause(address) (src/SalvaMultiSig/Updates/StateUpdates.sol#118-124) deletes MultiSigStorage.UnpauseProposal (src/SalvaMultiSig/MultiSigStorage.sol#218-225) which contains a mapping:
	-delete _unpauseProposal[proxy] (src/SalvaMultiSig/Updates/StateUpdates.sol#121)
MultiSig.cancelRegistryInit(address) (src/SalvaMultiSig/MultiSig.sol#163-169) deletes MultiSigStorage.InitRegistryProposal (src/SalvaMultiSig/MultiSigStorage.sol#75-86) which contains a mapping:
	-delete _initRegistryProposal[registry] (src/SalvaMultiSig/MultiSig.sol#166)
MultiSig.cancelValidatorUpdate(address) (src/SalvaMultiSig/MultiSig.sol#266-272) deletes MultiSigStorage.ValidatorUpdateProposal (src/SalvaMultiSig/MultiSigStorage.sol#140-149) which contains a mapping:
	-delete _validatorUpdateProposal[target] (src/SalvaMultiSig/MultiSig.sol#269)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#deletion-on-mapping-containing-a-structure
INFO:Detectors:
Detector: unused-return
ERC1967Utils.upgradeToAndCall(address,bytes) (lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Utils.sol#67-76) ignores return value by Address.functionDelegateCall(newImplementation,data) (lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Utils.sol#72)
ERC1967Utils.upgradeBeaconToAndCall(address,bytes) (lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Utils.sol#157-166) ignores return value by Address.functionDelegateCall(IBeacon(newBeacon).implementation(),data) (lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Utils.sol#162)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#unused-return
INFO:Detectors:
Detector: missing-zero-check
BaseRegistry.initialize(address,address,string).singleton (src/SalvaRegistry/BaseRegistry.sol#70) lacks a zero-check on :
		- _singleton = singleton (src/SalvaRegistry/BaseRegistry.sol#74)
BaseRegistry.initialize(address,address,string).factory (src/SalvaRegistry/BaseRegistry.sol#70) lacks a zero-check on :
		- _factory = factory (src/SalvaRegistry/BaseRegistry.sol#75)
RegistryFactory.initialize(address,address,address,address).impl (src/SalvaRegistry/RegistryFactory.sol#88) lacks a zero-check on :
		- _implementation = impl (src/SalvaRegistry/RegistryFactory.sol#92)
RegistryFactory.initialize(address,address,address,address).multiSig (src/SalvaRegistry/RegistryFactory.sol#88) lacks a zero-check on :
		- _multiSig = multiSig (src/SalvaRegistry/RegistryFactory.sol#93)
RegistryFactory.initialize(address,address,address,address).signer (src/SalvaRegistry/RegistryFactory.sol#88) lacks a zero-check on :
		- _signer = signer (src/SalvaRegistry/RegistryFactory.sol#94)
RegistryFactory.initialize(address,address,address,address).ngns (src/SalvaRegistry/RegistryFactory.sol#88) lacks a zero-check on :
		- _ngns = ngns (src/SalvaRegistry/RegistryFactory.sol#95)
RegistryFactory.updateSigner(address).newSigner (src/SalvaRegistry/RegistryFactory.sol#117) lacks a zero-check on :
		- _signer = newSigner (src/SalvaRegistry/RegistryFactory.sol#118)
RegistryFactory.updateImplementation(address).newImpl (src/SalvaRegistry/RegistryFactory.sol#123) lacks a zero-check on :
		- _implementation = newImpl (src/SalvaRegistry/RegistryFactory.sol#124)
Singleton.initialize(address).multiSig (src/SalvaSingleton/Singleton.sol#67) lacks a zero-check on :
		- _multiSig = multiSig (src/SalvaSingleton/Singleton.sol#68)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#missing-zero-address-validation
INFO:Detectors:
Detector: reentrancy-benign
Reentrancy in MultiSig.proposeInitRegistry(string,address,address) (src/SalvaMultiSig/MultiSig.sol#74-95):
	External calls:
	- clone = _deployClone(singleton,factory,namespace_) (src/SalvaMultiSig/MultiSig.sol#78)
		- (success,returnData) = factory.call(data) (src/SalvaMultiSig/MultiSigHelper.sol#189)
	State variables written after the call(s):
	- r.clone = clone (src/SalvaMultiSig/MultiSig.sol#87)
	- r.namespace_ = packed (src/SalvaMultiSig/MultiSig.sol#88)
	- r.namespaceLen = _toBytes1(bytes(namespace_).length) (src/SalvaMultiSig/MultiSig.sol#89)
	- r.singleton = singleton (src/SalvaMultiSig/MultiSig.sol#90)
	- r.remaining = required (src/SalvaMultiSig/MultiSig.sol#91)
	- r.isProposed = true (src/SalvaMultiSig/MultiSig.sol#92)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#reentrancy-vulnerabilities-3
INFO:Detectors:
Detector: reentrancy-events
Reentrancy in BaseRegistry.link(bytes,address,bytes) (src/SalvaRegistry/BaseRegistry.sol#84-119):
	External calls:
	- isLinked = ISalvaSingleton(_singleton).linkNameAlias(name,wallet,caller) (src/SalvaRegistry/BaseRegistry.sol#114)
	Event emitted after the call(s):
	- LinkSuccess(name,wallet) (src/SalvaRegistry/BaseRegistry.sol#117)
Reentrancy in MultiSig.proposeInitRegistry(string,address,address) (src/SalvaMultiSig/MultiSig.sol#74-95):
	External calls:
	- clone = _deployClone(singleton,factory,namespace_) (src/SalvaMultiSig/MultiSig.sol#78)
		- (success,returnData) = factory.call(data) (src/SalvaMultiSig/MultiSigHelper.sol#189)
	Event emitted after the call(s):
	- RegistryInitProposed(clone,namespace_,required) (src/SalvaMultiSig/MultiSig.sol#94)
Reentrancy in BaseRegistry.unlink(bytes) (src/SalvaRegistry/BaseRegistry.sol#122-127):
	External calls:
	- isSuccess = ISalvaSingleton(_singleton).unlink(name,_msgSender()) (src/SalvaRegistry/BaseRegistry.sol#123)
	Event emitted after the call(s):
	- UnlinkSuccess(name) (src/SalvaRegistry/BaseRegistry.sol#125)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#reentrancy-vulnerabilities-4
INFO:Detectors:
Detector: timestamp
MultiSig.executeInitRegistry(address) (src/SalvaMultiSig/MultiSig.sol#138-156) uses timestamp for comparisons
	Dangerous comparisons:
	- ! r.isValidated || block.timestamp < r.timeLock (src/SalvaMultiSig/MultiSig.sol#147)
MultiSig.executeValidatorUpdate(address) (src/SalvaMultiSig/MultiSig.sol#242-259) uses timestamp for comparisons
	Dangerous comparisons:
	- ! v.isValidated || block.timestamp < v.timeLock (src/SalvaMultiSig/MultiSig.sol#251)
FactoryUpdates.executeSignerUpdate(address) (src/SalvaMultiSig/Updates/FactoryUpdates.sol#115-132) uses timestamp for comparisons
	Dangerous comparisons:
	- ! s.isValidated || block.timestamp < s.timeLock (src/SalvaMultiSig/Updates/FactoryUpdates.sol#124)
FactoryUpdates.executeBaseRegistryImplUpdate(address) (src/SalvaMultiSig/Updates/FactoryUpdates.sol#232-249) uses timestamp for comparisons
	Dangerous comparisons:
	- ! b.isValidated || block.timestamp < b.timeLock (src/SalvaMultiSig/Updates/FactoryUpdates.sol#241)
StateUpdates.executeUnpause(address) (src/SalvaMultiSig/Updates/StateUpdates.sol#137-156) uses timestamp for comparisons
	Dangerous comparisons:
	- ! u.isValidated || block.timestamp < u.timeLock (src/SalvaMultiSig/Updates/StateUpdates.sol#141)
Upgrades.executeUpgrade(address) (src/SalvaMultiSig/Upgrades/Upgrades.sol#122-144) uses timestamp for comparisons
	Dangerous comparisons:
	- ! p.isValidated || block.timestamp < p.timeLock (src/SalvaMultiSig/Upgrades/Upgrades.sol#131)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#block-timestamp
INFO:Detectors:
Detector: assembly
Clones.clone(address,uint256) (lib/openzeppelin-contracts/contracts/proxy/Clones.sol#47-62) uses assembly
	- INLINE ASM (lib/openzeppelin-contracts/contracts/proxy/Clones.sol#51-58)
Clones.cloneDeterministic(address,bytes32,uint256) (lib/openzeppelin-contracts/contracts/proxy/Clones.sol#90-109) uses assembly
	- INLINE ASM (lib/openzeppelin-contracts/contracts/proxy/Clones.sol#98-105)
Clones.predictDeterministicAddress(address,bytes32,address) (lib/openzeppelin-contracts/contracts/proxy/Clones.sol#114-129) uses assembly
	- INLINE ASM (lib/openzeppelin-contracts/contracts/proxy/Clones.sol#119-128)
Clones.cloneWithImmutableArgs(address,bytes,uint256) (lib/openzeppelin-contracts/contracts/proxy/Clones.sol#167-182) uses assembly
	- INLINE ASM (lib/openzeppelin-contracts/contracts/proxy/Clones.sol#176-178)
Clones.fetchCloneArgs(address) (lib/openzeppelin-contracts/contracts/proxy/Clones.sol#261-267) uses assembly
	- INLINE ASM (lib/openzeppelin-contracts/contracts/proxy/Clones.sol#263-265)
Initializable._getInitializableStorage() (lib/openzeppelin-contracts/contracts/proxy/utils/Initializable.sol#232-237) uses assembly
	- INLINE ASM (lib/openzeppelin-contracts/contracts/proxy/utils/Initializable.sol#234-236)
SafeERC20._safeTransfer(IERC20,address,uint256,bool) (lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol#176-200) uses assembly
	- INLINE ASM (lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol#179-199)
SafeERC20._safeTransferFrom(IERC20,address,address,uint256,bool) (lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol#212-244) uses assembly
	- INLINE ASM (lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol#221-243)
SafeERC20._safeApprove(IERC20,address,uint256,bool) (lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol#255-279) uses assembly
	- INLINE ASM (lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol#258-278)
Bytes.slice(bytes,uint256,uint256) (lib/openzeppelin-contracts/contracts/utils/Bytes.sol#86-98) uses assembly
	- INLINE ASM (lib/openzeppelin-contracts/contracts/utils/Bytes.sol#93-95)
Bytes.splice(bytes,uint256,uint256) (lib/openzeppelin-contracts/contracts/utils/Bytes.sol#117-129) uses assembly
	- INLINE ASM (lib/openzeppelin-contracts/contracts/utils/Bytes.sol#123-126)
Bytes.replace(bytes,uint256,bytes,uint256,uint256) (lib/openzeppelin-contracts/contracts/utils/Bytes.sol#154-172) uses assembly
	- INLINE ASM (lib/openzeppelin-contracts/contracts/utils/Bytes.sol#167-169)
Bytes.concat(bytes[]) (lib/openzeppelin-contracts/contracts/utils/Bytes.sol#183-203) uses assembly
	- INLINE ASM (lib/openzeppelin-contracts/contracts/utils/Bytes.sol#194-196)
Bytes.toNibbles(bytes) (lib/openzeppelin-contracts/contracts/utils/Bytes.sol#210-245) uses assembly
	- INLINE ASM (lib/openzeppelin-contracts/contracts/utils/Bytes.sol#211-244)
Bytes._unsafeReadBytesOffset(bytes,uint256) (lib/openzeppelin-contracts/contracts/utils/Bytes.sol#326-331) uses assembly
	- INLINE ASM (lib/openzeppelin-contracts/contracts/utils/Bytes.sol#328-330)
Create2.deploy(uint256,bytes32,bytes) (lib/openzeppelin-contracts/contracts/utils/Create2.sol#38-55) uses assembly
	- INLINE ASM (lib/openzeppelin-contracts/contracts/utils/Create2.sol#45-47)
Create2.computeAddress(bytes32,bytes32,address) (lib/openzeppelin-contracts/contracts/utils/Create2.sol#69-90) uses assembly
	- INLINE ASM (lib/openzeppelin-contracts/contracts/utils/Create2.sol#70-89)
LowLevelCall.callNoReturn(address,uint256,bytes) (lib/openzeppelin-contracts/contracts/utils/LowLevelCall.sol#19-23) uses assembly
	- INLINE ASM (lib/openzeppelin-contracts/contracts/utils/LowLevelCall.sol#20-22)
LowLevelCall.callReturn64Bytes(address,uint256,bytes) (lib/openzeppelin-contracts/contracts/utils/LowLevelCall.sol#38-48) uses assembly
	- INLINE ASM (lib/openzeppelin-contracts/contracts/utils/LowLevelCall.sol#43-47)
LowLevelCall.staticcallNoReturn(address,bytes) (lib/openzeppelin-contracts/contracts/utils/LowLevelCall.sol#51-55) uses assembly
	- INLINE ASM (lib/openzeppelin-contracts/contracts/utils/LowLevelCall.sol#52-54)
LowLevelCall.staticcallReturn64Bytes(address,bytes) (lib/openzeppelin-contracts/contracts/utils/LowLevelCall.sol#62-71) uses assembly
	- INLINE ASM (lib/openzeppelin-contracts/contracts/utils/LowLevelCall.sol#66-70)
LowLevelCall.delegatecallNoReturn(address,bytes) (lib/openzeppelin-contracts/contracts/utils/LowLevelCall.sol#74-78) uses assembly
	- INLINE ASM (lib/openzeppelin-contracts/contracts/utils/LowLevelCall.sol#75-77)
LowLevelCall.delegatecallReturn64Bytes(address,bytes) (lib/openzeppelin-contracts/contracts/utils/LowLevelCall.sol#85-94) uses assembly
	- INLINE ASM (lib/openzeppelin-contracts/contracts/utils/LowLevelCall.sol#89-93)
LowLevelCall.returnDataSize() (lib/openzeppelin-contracts/contracts/utils/LowLevelCall.sol#97-101) uses assembly
	- INLINE ASM (lib/openzeppelin-contracts/contracts/utils/LowLevelCall.sol#98-100)
LowLevelCall.returnData() (lib/openzeppelin-contracts/contracts/utils/LowLevelCall.sol#104-111) uses assembly
	- INLINE ASM (lib/openzeppelin-contracts/contracts/utils/LowLevelCall.sol#105-110)
LowLevelCall.bubbleRevert() (lib/openzeppelin-contracts/contracts/utils/LowLevelCall.sol#114-120) uses assembly
	- INLINE ASM (lib/openzeppelin-contracts/contracts/utils/LowLevelCall.sol#115-119)
LowLevelCall.bubbleRevert(bytes) (lib/openzeppelin-contracts/contracts/utils/LowLevelCall.sol#122-126) uses assembly
	- INLINE ASM (lib/openzeppelin-contracts/contracts/utils/LowLevelCall.sol#123-125)
Panic.panic(uint256) (lib/openzeppelin-contracts/contracts/utils/Panic.sol#50-56) uses assembly
	- INLINE ASM (lib/openzeppelin-contracts/contracts/utils/Panic.sol#51-55)
StorageSlot.getAddressSlot(bytes32) (lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#66-70) uses assembly
	- INLINE ASM (lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#67-69)
StorageSlot.getBooleanSlot(bytes32) (lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#75-79) uses assembly
	- INLINE ASM (lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#76-78)
StorageSlot.getBytes32Slot(bytes32) (lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#84-88) uses assembly
	- INLINE ASM (lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#85-87)
StorageSlot.getUint256Slot(bytes32) (lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#93-97) uses assembly
	- INLINE ASM (lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#94-96)
StorageSlot.getInt256Slot(bytes32) (lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#102-106) uses assembly
	- INLINE ASM (lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#103-105)
StorageSlot.getStringSlot(bytes32) (lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#111-115) uses assembly
	- INLINE ASM (lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#112-114)
StorageSlot.getStringSlot(string) (lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#120-124) uses assembly
	- INLINE ASM (lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#121-123)
StorageSlot.getBytesSlot(bytes32) (lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#129-133) uses assembly
	- INLINE ASM (lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#130-132)
StorageSlot.getBytesSlot(bytes) (lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#138-142) uses assembly
	- INLINE ASM (lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#139-141)
Strings.toString(uint256) (lib/openzeppelin-contracts/contracts/utils/Strings.sol#42-60) uses assembly
	- INLINE ASM (lib/openzeppelin-contracts/contracts/utils/Strings.sol#47-49)
	- INLINE ASM (lib/openzeppelin-contracts/contracts/utils/Strings.sol#52-54)
Strings.toChecksumHexString(address) (lib/openzeppelin-contracts/contracts/utils/Strings.sol#108-126) uses assembly
	- INLINE ASM (lib/openzeppelin-contracts/contracts/utils/Strings.sol#113-115)
Strings.escapeJSON(string) (lib/openzeppelin-contracts/contracts/utils/Strings.sol#461-505) uses assembly
	- INLINE ASM (lib/openzeppelin-contracts/contracts/utils/Strings.sol#468-470)
	- INLINE ASM (lib/openzeppelin-contracts/contracts/utils/Strings.sol#499-502)
Strings._unsafeReadBytesOffset(bytes,uint256) (lib/openzeppelin-contracts/contracts/utils/Strings.sol#513-518) uses assembly
	- INLINE ASM (lib/openzeppelin-contracts/contracts/utils/Strings.sol#515-517)
Strings._unsafeWriteBytesOffset(bytes,uint256,bytes1) (lib/openzeppelin-contracts/contracts/utils/Strings.sol#526-531) uses assembly
	- INLINE ASM (lib/openzeppelin-contracts/contracts/utils/Strings.sol#528-530)
ECDSA.tryRecover(bytes32,bytes) (lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol#61-80) uses assembly
	- INLINE ASM (lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol#71-75)
ECDSA.tryRecoverCalldata(bytes32,bytes) (lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol#85-104) uses assembly
	- INLINE ASM (lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol#95-99)
ECDSA.parse(bytes) (lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol#217-240) uses assembly
	- INLINE ASM (lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol#218-239)
ECDSA.parseCalldata(bytes) (lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol#245-268) uses assembly
	- INLINE ASM (lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol#246-267)
MessageHashUtils.toEthSignedMessageHash(bytes32) (lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol#32-38) uses assembly
	- INLINE ASM (lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol#33-37)
MessageHashUtils.toDataWithIntendedValidatorHash(address,bytes32) (lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol#71-81) uses assembly
	- INLINE ASM (lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol#75-80)
MessageHashUtils.toTypedDataHash(bytes32,bytes32) (lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol#92-100) uses assembly
	- INLINE ASM (lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol#93-99)
MessageHashUtils.toDomainSeparator(bytes1,bytes32,bytes32,uint256,address,bytes32) (lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol#137-179) uses assembly
	- INLINE ASM (lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol#147-178)
MessageHashUtils.toDomainTypeHash(bytes1) (lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol#182-227) uses assembly
	- INLINE ASM (lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol#185-226)
Math.add512(uint256,uint256) (lib/openzeppelin-contracts/contracts/utils/math/Math.sol#25-30) uses assembly
	- INLINE ASM (lib/openzeppelin-contracts/contracts/utils/math/Math.sol#26-29)
Math.mul512(uint256,uint256) (lib/openzeppelin-contracts/contracts/utils/math/Math.sol#37-46) uses assembly
	- INLINE ASM (lib/openzeppelin-contracts/contracts/utils/math/Math.sol#41-45)
Math.tryMul(uint256,uint256) (lib/openzeppelin-contracts/contracts/utils/math/Math.sol#73-84) uses assembly
	- INLINE ASM (lib/openzeppelin-contracts/contracts/utils/math/Math.sol#76-80)
Math.tryDiv(uint256,uint256) (lib/openzeppelin-contracts/contracts/utils/math/Math.sol#89-97) uses assembly
	- INLINE ASM (lib/openzeppelin-contracts/contracts/utils/math/Math.sol#92-95)
Math.tryMod(uint256,uint256) (lib/openzeppelin-contracts/contracts/utils/math/Math.sol#102-110) uses assembly
	- INLINE ASM (lib/openzeppelin-contracts/contracts/utils/math/Math.sol#105-108)
Math.mulDiv(uint256,uint256,uint256) (lib/openzeppelin-contracts/contracts/utils/math/Math.sol#206-277) uses assembly
	- INLINE ASM (lib/openzeppelin-contracts/contracts/utils/math/Math.sol#229-236)
	- INLINE ASM (lib/openzeppelin-contracts/contracts/utils/math/Math.sol#242-251)
Math.tryModExp(uint256,uint256,uint256) (lib/openzeppelin-contracts/contracts/utils/math/Math.sol#411-435) uses assembly
	- INLINE ASM (lib/openzeppelin-contracts/contracts/utils/math/Math.sol#413-434)
Math.tryModExp(bytes,bytes,bytes) (lib/openzeppelin-contracts/contracts/utils/math/Math.sol#451-473) uses assembly
	- INLINE ASM (lib/openzeppelin-contracts/contracts/utils/math/Math.sol#463-472)
Math._zeroBytes(bytes) (lib/openzeppelin-contracts/contracts/utils/math/Math.sol#478-490) uses assembly
	- INLINE ASM (lib/openzeppelin-contracts/contracts/utils/math/Math.sol#482-484)
Math.log2(uint256) (lib/openzeppelin-contracts/contracts/utils/math/Math.sol#619-658) uses assembly
	- INLINE ASM (lib/openzeppelin-contracts/contracts/utils/math/Math.sol#655-657)
SafeCast.toUint(bool) (lib/openzeppelin-contracts/contracts/utils/math/SafeCast.sol#1157-1161) uses assembly
	- INLINE ASM (lib/openzeppelin-contracts/contracts/utils/math/SafeCast.sol#1158-1160)
LinkName.linkNameAlias(bytes,address,address) (src/SalvaModules/Aliases/NameAlias/LinkName.sol#64-91) uses assembly
	- INLINE ASM (src/SalvaModules/Aliases/NameAlias/LinkName.sol#77-80)
UnlinkName.unlink(bytes,address) (src/SalvaModules/Aliases/NameAlias/UnlinkName.sol#56-80) uses assembly
	- INLINE ASM (src/SalvaModules/Aliases/NameAlias/UnlinkName.sol#64-67)
NameLib._computeNameHash(bytes31,uint256,uint256,uint256) (src/SalvaModules/Library/NameLib.sol#45-63) uses assembly
	- INLINE ASM (src/SalvaModules/Library/NameLib.sol#51-58)
NameLib._normalizeAndValidate(uint256,bytes32,uint8) (src/SalvaModules/Library/NameLib.sol#98-208) uses assembly
	- INLINE ASM (src/SalvaModules/Library/NameLib.sol#135-144)
	- INLINE ASM (src/SalvaModules/Library/NameLib.sol#148-152)
	- INLINE ASM (src/SalvaModules/Library/NameLib.sol#162-171)
	- INLINE ASM (src/SalvaModules/Library/NameLib.sol#176-179)
NameLib._normalizeSegments(bytes32,uint256,bytes32,uint256) (src/SalvaModules/Library/NameLib.sol#222-246) uses assembly
	- INLINE ASM (src/SalvaModules/Library/NameLib.sol#237-243)
NameLib._checkCollision(bytes32) (src/SalvaModules/Library/NameLib.sol#257-263) uses assembly
	- INLINE ASM (src/SalvaModules/Library/NameLib.sol#259-261)
NameLib._checkCaller(address,bytes32) (src/SalvaModules/Library/NameLib.sol#275-286) uses assembly
	- INLINE ASM (src/SalvaModules/Library/NameLib.sol#280-284)
NameLib._performLinkToWallet(bytes32,address,address) (src/SalvaModules/Library/NameLib.sol#299-311) uses assembly
	- INLINE ASM (src/SalvaModules/Library/NameLib.sol#303-309)
NameLib._performUnlink(bytes32,bytes32) (src/SalvaModules/Library/NameLib.sol#321-330) uses assembly
	- INLINE ASM (src/SalvaModules/Library/NameLib.sol#325-328)
Resolve.resolveAddress(bytes) (src/SalvaModules/Resolve.sol#53-93) uses assembly
	- INLINE ASM (src/SalvaModules/Resolve.sol#61-64)
	- INLINE ASM (src/SalvaModules/Resolve.sol#77-85)
	- INLINE ASM (src/SalvaModules/Resolve.sol#90-92)
BaseRegistry.link(bytes,address,bytes) (src/SalvaRegistry/BaseRegistry.sol#84-119) uses assembly
	- INLINE ASM (src/SalvaRegistry/BaseRegistry.sol#93-97)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#assembly-usage
INFO:Detectors:
Detector: pragma
8 different versions of Solidity are used:
	- Version constraint >=0.6.2 is used by:
		->=0.6.2 (lib/openzeppelin-contracts/contracts/interfaces/IERC1363.sol#4)
	- Version constraint >=0.4.16 is used by:
		->=0.4.16 (lib/openzeppelin-contracts/contracts/interfaces/IERC165.sol#4)
		->=0.4.16 (lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol#4)
		->=0.4.16 (lib/openzeppelin-contracts/contracts/interfaces/draft-IERC1822.sol#4)
		->=0.4.16 (lib/openzeppelin-contracts/contracts/proxy/beacon/IBeacon.sol#4)
		->=0.4.16 (lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol#4)
		->=0.4.16 (lib/openzeppelin-contracts/contracts/utils/introspection/IERC165.sol#4)
	- Version constraint >=0.4.11 is used by:
		->=0.4.11 (lib/openzeppelin-contracts/contracts/interfaces/IERC1967.sol#4)
	- Version constraint ^0.8.20 is used by:
		-^0.8.20 (lib/openzeppelin-contracts/contracts/proxy/Clones.sol#4)
		-^0.8.20 (lib/openzeppelin-contracts/contracts/proxy/utils/Initializable.sol#4)
		-^0.8.20 (lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol#4)
		-^0.8.20 (lib/openzeppelin-contracts/contracts/utils/Address.sol#4)
		-^0.8.20 (lib/openzeppelin-contracts/contracts/utils/Create2.sol#4)
		-^0.8.20 (lib/openzeppelin-contracts/contracts/utils/Errors.sol#4)
		-^0.8.20 (lib/openzeppelin-contracts/contracts/utils/LowLevelCall.sol#4)
		-^0.8.20 (lib/openzeppelin-contracts/contracts/utils/Panic.sol#4)
		-^0.8.20 (lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#5)
		-^0.8.20 (lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol#4)
		-^0.8.20 (lib/openzeppelin-contracts/contracts/utils/math/Math.sol#4)
		-^0.8.20 (lib/openzeppelin-contracts/contracts/utils/math/SafeCast.sol#5)
		-^0.8.20 (lib/openzeppelin-contracts/contracts/utils/math/SignedMath.sol#4)
	- Version constraint ^0.8.21 is used by:
		-^0.8.21 (lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Utils.sol#4)
	- Version constraint ^0.8.22 is used by:
		-^0.8.22 (lib/openzeppelin-contracts/contracts/proxy/utils/UUPSUpgradeable.sol#4)
	- Version constraint ^0.8.24 is used by:
		-^0.8.24 (lib/openzeppelin-contracts/contracts/utils/Bytes.sol#4)
		-^0.8.24 (lib/openzeppelin-contracts/contracts/utils/Strings.sol#4)
		-^0.8.24 (lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol#4)
	- Version constraint ^0.8.30 is used by:
		-^0.8.30 (src/Interface/IBaseRegistry.sol#2)
		-^0.8.30 (src/Interface/IRegistryFactory.sol#2)
		-^0.8.30 (src/Interface/ISalvaSingleton.sol#2)
		-^0.8.30 (src/SalvaModules/Aliases/NameAlias/LinkName.sol#2)
		-^0.8.30 (src/SalvaModules/Aliases/NameAlias/UnlinkName.sol#2)
		-^0.8.30 (src/SalvaModules/Initialize.sol#2)
		-^0.8.30 (src/SalvaModules/Library/Context.sol#2)
		-^0.8.30 (src/SalvaModules/Library/Errors.sol#2)
		-^0.8.30 (src/SalvaModules/Library/Modifier.sol#2)
		-^0.8.30 (src/SalvaModules/Library/NameLib.sol#2)
		-^0.8.30 (src/SalvaModules/Library/Storage.sol#2)
		-^0.8.30 (src/SalvaModules/Resolve.sol#2)
		-^0.8.30 (src/SalvaMultiSig/Events.sol#2)
		-^0.8.30 (src/SalvaMultiSig/MultiSig.sol#2)
		-^0.8.30 (src/SalvaMultiSig/MultiSigErrors.sol#2)
		-^0.8.30 (src/SalvaMultiSig/MultiSigHelper.sol#2)
		-^0.8.30 (src/SalvaMultiSig/MultiSigModifier.sol#2)
		-^0.8.30 (src/SalvaMultiSig/MultiSigStorage.sol#2)
		-^0.8.30 (src/SalvaMultiSig/Updates/FactoryUpdates.sol#2)
		-^0.8.30 (src/SalvaMultiSig/Updates/StateUpdates.sol#2)
		-^0.8.30 (src/SalvaMultiSig/Upgrades/Upgrades.sol#2)
		-^0.8.30 (src/SalvaRegistry/BaseRegistry.sol#2)
		-^0.8.30 (src/SalvaRegistry/RegistryErrors.sol#2)
		-^0.8.30 (src/SalvaRegistry/RegistryFactory.sol#2)
		-^0.8.30 (src/SalvaSingleton/Singleton.sol#2)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#different-pragma-directives-are-used
INFO:Detectors:
Detector: cyclomatic-complexity
NameLib._normalizeAndValidate(uint256,bytes32,uint8) (src/SalvaModules/Library/NameLib.sol#98-208) has a high cyclomatic complexity (19).
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#cyclomatic-complexity
INFO:Detectors:
Detector: solc-version
Version constraint >=0.6.2 contains known severe issues (https://solidity.readthedocs.io/en/latest/bugs.html)
	- MissingSideEffectsOnSelectorAccess
	- AbiReencodingHeadOverflowWithStaticArrayCleanup
	- DirtyBytesArrayToStorage
	- NestedCalldataArrayAbiReencodingSizeValidation
	- ABIDecodeTwoDimensionalArrayMemory
	- KeccakCaching
	- EmptyByteArrayCopy
	- DynamicArrayCleanup
	- MissingEscapingInFormatting
	- ArraySliceDynamicallyEncodedBaseType
	- ImplicitConstructorCallvalueCheck
	- TupleAssignmentMultiStackSlotComponents
	- MemoryArrayCreationOverflow.
It is used by:
	- >=0.6.2 (lib/openzeppelin-contracts/contracts/interfaces/IERC1363.sol#4)
Version constraint >=0.4.16 contains known severe issues (https://solidity.readthedocs.io/en/latest/bugs.html)
	- DirtyBytesArrayToStorage
	- ABIDecodeTwoDimensionalArrayMemory
	- KeccakCaching
	- EmptyByteArrayCopy
	- DynamicArrayCleanup
	- ImplicitConstructorCallvalueCheck
	- TupleAssignmentMultiStackSlotComponents
	- MemoryArrayCreationOverflow
	- privateCanBeOverridden
	- SignedArrayStorageCopy
	- ABIEncoderV2StorageArrayWithMultiSlotElement
	- DynamicConstructorArgumentsClippedABIV2
	- UninitializedFunctionPointerInConstructor_0.4.x
	- IncorrectEventSignatureInLibraries_0.4.x
	- ExpExponentCleanup
	- NestedArrayFunctionCallDecoder
	- ZeroFunctionSelector.
It is used by:
	- >=0.4.16 (lib/openzeppelin-contracts/contracts/interfaces/IERC165.sol#4)
	- >=0.4.16 (lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol#4)
	- >=0.4.16 (lib/openzeppelin-contracts/contracts/interfaces/draft-IERC1822.sol#4)
	- >=0.4.16 (lib/openzeppelin-contracts/contracts/proxy/beacon/IBeacon.sol#4)
	- >=0.4.16 (lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol#4)
	- >=0.4.16 (lib/openzeppelin-contracts/contracts/utils/introspection/IERC165.sol#4)
Version constraint >=0.4.11 contains known severe issues (https://solidity.readthedocs.io/en/latest/bugs.html)
	- DirtyBytesArrayToStorage
	- KeccakCaching
	- EmptyByteArrayCopy
	- DynamicArrayCleanup
	- ImplicitConstructorCallvalueCheck
	- TupleAssignmentMultiStackSlotComponents
	- MemoryArrayCreationOverflow
	- privateCanBeOverridden
	- SignedArrayStorageCopy
	- UninitializedFunctionPointerInConstructor_0.4.x
	- IncorrectEventSignatureInLibraries_0.4.x
	- ExpExponentCleanup
	- NestedArrayFunctionCallDecoder
	- ZeroFunctionSelector
	- DelegateCallReturnValue
	- ECRecoverMalformedInput
	- SkipEmptyStringLiteral.
It is used by:
	- >=0.4.11 (lib/openzeppelin-contracts/contracts/interfaces/IERC1967.sol#4)
Version constraint ^0.8.20 contains known severe issues (https://solidity.readthedocs.io/en/latest/bugs.html)
	- VerbatimInvalidDeduplication
	- FullInlinerNonExpressionSplitArgumentEvaluationOrder
	- MissingSideEffectsOnSelectorAccess.
It is used by:
	- ^0.8.20 (lib/openzeppelin-contracts/contracts/proxy/Clones.sol#4)
	- ^0.8.20 (lib/openzeppelin-contracts/contracts/proxy/utils/Initializable.sol#4)
	- ^0.8.20 (lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol#4)
	- ^0.8.20 (lib/openzeppelin-contracts/contracts/utils/Address.sol#4)
	- ^0.8.20 (lib/openzeppelin-contracts/contracts/utils/Create2.sol#4)
	- ^0.8.20 (lib/openzeppelin-contracts/contracts/utils/Errors.sol#4)
	- ^0.8.20 (lib/openzeppelin-contracts/contracts/utils/LowLevelCall.sol#4)
	- ^0.8.20 (lib/openzeppelin-contracts/contracts/utils/Panic.sol#4)
	- ^0.8.20 (lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#5)
	- ^0.8.20 (lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol#4)
	- ^0.8.20 (lib/openzeppelin-contracts/contracts/utils/math/Math.sol#4)
	- ^0.8.20 (lib/openzeppelin-contracts/contracts/utils/math/SafeCast.sol#5)
	- ^0.8.20 (lib/openzeppelin-contracts/contracts/utils/math/SignedMath.sol#4)
Version constraint ^0.8.21 contains known severe issues (https://solidity.readthedocs.io/en/latest/bugs.html)
	- VerbatimInvalidDeduplication.
It is used by:
	- ^0.8.21 (lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Utils.sol#4)
Version constraint ^0.8.22 contains known severe issues (https://solidity.readthedocs.io/en/latest/bugs.html)
	- VerbatimInvalidDeduplication.
It is used by:
	- ^0.8.22 (lib/openzeppelin-contracts/contracts/proxy/utils/UUPSUpgradeable.sol#4)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#incorrect-versions-of-solidity
INFO:Detectors:
Detector: low-level-calls
Low level call in MultiSigHelper._deployClone(address,address,string) (src/SalvaMultiSig/MultiSigHelper.sol#182-192):
	- (success,returnData) = factory.call(data) (src/SalvaMultiSig/MultiSigHelper.sol#189)
Low level call in StateUpdates._pauseExternalState(address) (src/SalvaMultiSig/Updates/StateUpdates.sol#166-169):
	- (success,None) = proxy.call(_encodePause()) (src/SalvaMultiSig/Updates/StateUpdates.sol#167)
Low level call in StateUpdates._unpauseExternalState(address) (src/SalvaMultiSig/Updates/StateUpdates.sol#175-178):
	- (success,None) = proxy.call(_encodeUnpause()) (src/SalvaMultiSig/Updates/StateUpdates.sol#176)
Low level call in Upgrades._executeExternalUpgrade(address,address) (src/SalvaMultiSig/Upgrades/Upgrades.sol#166-172):
	- (success,None) = proxy.call(_encodeUpgrade(newImpl)) (src/SalvaMultiSig/Upgrades/Upgrades.sol#170)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#low-level-calls
INFO:Detectors:
Detector: missing-inheritance
BaseRegistry (src/SalvaRegistry/BaseRegistry.sol#27-171) should inherit from IBaseRegistry (src/Interface/IBaseRegistry.sol#18-108)
RegistryFactory (src/SalvaRegistry/RegistryFactory.sol#27-204) should inherit from IRegistryFactory (src/Interface/IRegistryFactory.sol#13-86)
Singleton (src/SalvaSingleton/Singleton.sol#28-147) should inherit from ISalvaSingleton (src/Interface/ISalvaSingleton.sol#19-127)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#missing-inheritance
INFO:Detectors:
Detector: naming-convention
Variable UUPSUpgradeable.__self (lib/openzeppelin-contracts/contracts/proxy/utils/UUPSUpgradeable.sol#23) is not in mixedCase
Variable Storage._nameToWallet (src/SalvaModules/Library/Storage.sol#86) is not in mixedCase
Variable Storage.__gap (src/SalvaModules/Library/Storage.sol#96) is not in mixedCase
Variable MultiSigStorage._numOfValidators (src/SalvaMultiSig/MultiSigStorage.sol#34) is not in mixedCase
Variable MultiSigStorage.__gap (src/SalvaMultiSig/MultiSigStorage.sol#238) is not in mixedCase
Variable RegistryFactory.__gap (src/SalvaRegistry/RegistryFactory.sol#64) is not in mixedCase
Parameter Singleton.nameToByte(string)._name (src/SalvaSingleton/Singleton.sol#119) is not in mixedCase
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#conformance-to-solidity-naming-conventions
INFO:Detectors:
Detector: too-many-digits
Clones.clone(address,uint256) (lib/openzeppelin-contracts/contracts/proxy/Clones.sol#47-62) uses literals with too many digits:
	- mstore(uint256,uint256)(0x00,implementation << 96 >> 232 | 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000) (lib/openzeppelin-contracts/contracts/proxy/Clones.sol#54)
Clones.cloneDeterministic(address,bytes32,uint256) (lib/openzeppelin-contracts/contracts/proxy/Clones.sol#90-109) uses literals with too many digits:
	- mstore(uint256,uint256)(0x00,implementation << 96 >> 232 | 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000) (lib/openzeppelin-contracts/contracts/proxy/Clones.sol#101)
Bytes.toNibbles(bytes) (lib/openzeppelin-contracts/contracts/utils/Bytes.sol#210-245) uses literals with too many digits:
	- chunk_toNibbles_asm_0 = 0x0000000000000000ffffffffffffffff0000000000000000ffffffffffffffff & chunk_toNibbles_asm_0 << 64 | chunk_toNibbles_asm_0 (lib/openzeppelin-contracts/contracts/utils/Bytes.sol#222-225)
Bytes.toNibbles(bytes) (lib/openzeppelin-contracts/contracts/utils/Bytes.sol#210-245) uses literals with too many digits:
	- chunk_toNibbles_asm_0 = 0x00000000ffffffff00000000ffffffff00000000ffffffff00000000ffffffff & chunk_toNibbles_asm_0 << 32 | chunk_toNibbles_asm_0 (lib/openzeppelin-contracts/contracts/utils/Bytes.sol#226-229)
Bytes.reverseBytes32(bytes32) (lib/openzeppelin-contracts/contracts/utils/Bytes.sol#258-272) uses literals with too many digits:
	- value = ((value >> 32) & 0x00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF) | ((value & 0x00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF) << 32) (lib/openzeppelin-contracts/contracts/utils/Bytes.sol#265-267)
Bytes.reverseBytes32(bytes32) (lib/openzeppelin-contracts/contracts/utils/Bytes.sol#258-272) uses literals with too many digits:
	- value = ((value >> 64) & 0x0000000000000000FFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF) | ((value & 0x0000000000000000FFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF) << 64) (lib/openzeppelin-contracts/contracts/utils/Bytes.sol#268-270)
Bytes.reverseBytes16(bytes16) (lib/openzeppelin-contracts/contracts/utils/Bytes.sol#275-286) uses literals with too many digits:
	- value = ((value & 0xFFFFFFFF00000000FFFFFFFF00000000) >> 32) | ((value & 0x00000000FFFFFFFF00000000FFFFFFFF) << 32) (lib/openzeppelin-contracts/contracts/utils/Bytes.sol#282-284)
Math.log2(uint256) (lib/openzeppelin-contracts/contracts/utils/math/Math.sol#619-658) uses literals with too many digits:
	- r = r | byte(uint256,uint256)(x >> r,0x0000010102020202030303030303030300000000000000000000000000000000) (lib/openzeppelin-contracts/contracts/utils/math/Math.sol#656)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#too-many-digits
INFO:Detectors:
Detector: unindexed-event-address
Event IERC1967.AdminChanged(address,address) (lib/openzeppelin-contracts/contracts/interfaces/IERC1967.sol#18) has address parameters but no indexed parameters
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#unindexed-event-address-parameters
INFO:Detectors:
Detector: unused-state
RegistryFactory.__gap (src/SalvaRegistry/RegistryFactory.sol#64) is never used in RegistryFactory (src/SalvaRegistry/RegistryFactory.sol#27-204)
Storage._ownershipIndex (src/SalvaModules/Library/Storage.sol#76) is never used in Singleton (src/SalvaSingleton/Singleton.sol#28-147)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#unused-state-variable
**THIS CHECKLIST IS NOT COMPLETE**. Use `--show-ignored-findings` to show all the results.
Summary
 - [incorrect-exp](#incorrect-exp) (1 results) (High)
 - [divide-before-multiply](#divide-before-multiply) (9 results) (Medium)
 - [mapping-deletion](#mapping-deletion) (6 results) (Medium)
 - [unused-return](#unused-return) (2 results) (Medium)
 - [missing-zero-check](#missing-zero-check) (9 results) (Low)
 - [reentrancy-benign](#reentrancy-benign) (1 results) (Low)
 - [reentrancy-events](#reentrancy-events) (3 results) (Low)
 - [timestamp](#timestamp) (6 results) (Low)
 - [assembly](#assembly) (73 results) (Informational)
 - [pragma](#pragma) (1 results) (Informational)
 - [cyclomatic-complexity](#cyclomatic-complexity) (1 results) (Informational)
 - [solc-version](#solc-version) (6 results) (Informational)
 - [low-level-calls](#low-level-calls) (4 results) (Informational)
 - [missing-inheritance](#missing-inheritance) (3 results) (Informational)
 - [naming-convention](#naming-convention) (7 results) (Informational)
 - [too-many-digits](#too-many-digits) (8 results) (Informational)
 - [unindexed-event-address](#unindexed-event-address) (1 results) (Informational)
 - [unused-state](#unused-state) (2 results) (Informational)
## incorrect-exp
Impact: High
Confidence: Medium
 - [ ] ID-0
[Math.mulDiv(uint256,uint256,uint256)](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L206-L277) has bitwise-xor operator ^ instead of the exponentiation operator **: 
	 - [inverse = (3 * denominator) ^ 2](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L259)

https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L206-L277


## divide-before-multiply
Impact: Medium
Confidence: Medium
 - [ ] ID-1
[Math.mulDiv(uint256,uint256,uint256)](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L206-L277) performs a multiplication on the result of a division:
	- [denominator = denominator / twos](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L244)
	- [inverse = (3 * denominator) ^ 2](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L259)

https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L206-L277


 - [ ] ID-2
[Math.mulDiv(uint256,uint256,uint256)](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L206-L277) performs a multiplication on the result of a division:
	- [low = low / twos](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L247)
	- [result = low * inverse](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L274)

https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L206-L277


 - [ ] ID-3
[Math.mulDiv(uint256,uint256,uint256)](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L206-L277) performs a multiplication on the result of a division:
	- [denominator = denominator / twos](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L244)
	- [inverse *= 2 - denominator * inverse](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L265)

https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L206-L277


 - [ ] ID-4
[Math.invMod(uint256,uint256)](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L317-L363) performs a multiplication on the result of a division:
	- [quotient = gcd / remainder](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L339)
	- [(gcd,remainder) = (remainder,gcd - remainder * quotient)](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L341-L348)

https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L317-L363


 - [ ] ID-5
[Math.mulDiv(uint256,uint256,uint256)](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L206-L277) performs a multiplication on the result of a division:
	- [denominator = denominator / twos](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L244)
	- [inverse *= 2 - denominator * inverse](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L264)

https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L206-L277


 - [ ] ID-6
[Math.mulDiv(uint256,uint256,uint256)](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L206-L277) performs a multiplication on the result of a division:
	- [denominator = denominator / twos](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L244)
	- [inverse *= 2 - denominator * inverse](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L266)

https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L206-L277


 - [ ] ID-7
[Math.mulDiv(uint256,uint256,uint256)](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L206-L277) performs a multiplication on the result of a division:
	- [denominator = denominator / twos](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L244)
	- [inverse *= 2 - denominator * inverse](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L267)

https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L206-L277


 - [ ] ID-8
[Math.mulDiv(uint256,uint256,uint256)](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L206-L277) performs a multiplication on the result of a division:
	- [denominator = denominator / twos](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L244)
	- [inverse *= 2 - denominator * inverse](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L263)

https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L206-L277


 - [ ] ID-9
[Math.mulDiv(uint256,uint256,uint256)](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L206-L277) performs a multiplication on the result of a division:
	- [denominator = denominator / twos](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L244)
	- [inverse *= 2 - denominator * inverse](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L268)

https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L206-L277


## mapping-deletion
Impact: Medium
Confidence: High
 - [ ] ID-10
[MultiSig.cancelRegistryInit(address)](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaMultiSig/MultiSig.sol#L163-L169) deletes [MultiSigStorage.InitRegistryProposal](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaMultiSig/MultiSigStorage.sol#L75-L86) which contains a mapping:
	-[delete _initRegistryProposal[registry]](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaMultiSig/MultiSig.sol#L166)

https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaMultiSig/MultiSig.sol#L163-L169


 - [ ] ID-11
[Upgrades.cancelUpgrade(address)](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaMultiSig/Upgrades/Upgrades.sol#L101-L107) deletes [MultiSigStorage.UpgradeProposal](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaMultiSig/MultiSigStorage.sol#L104-L114) which contains a mapping:
	-[delete _upgradeProposal[newImpl]](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaMultiSig/Upgrades/Upgrades.sol#L104)

https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaMultiSig/Upgrades/Upgrades.sol#L101-L107


 - [ ] ID-12
[FactoryUpdates.cancelBaseRegistryImplUpdate(address)](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaMultiSig/Updates/FactoryUpdates.sol#L209-L219) deletes [MultiSigStorage.BaseRegistryImplUpdateProposal](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaMultiSig/MultiSigStorage.sol#L192-L201) which contains a mapping:
	-[delete _baseRegistryImplUpdateProposal[newImpl]](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaMultiSig/Updates/FactoryUpdates.sol#L216)

https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaMultiSig/Updates/FactoryUpdates.sol#L209-L219


 - [ ] ID-13
[MultiSig.cancelValidatorUpdate(address)](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaMultiSig/MultiSig.sol#L266-L272) deletes [MultiSigStorage.ValidatorUpdateProposal](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaMultiSig/MultiSigStorage.sol#L140-L149) which contains a mapping:
	-[delete _validatorUpdateProposal[target]](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaMultiSig/MultiSig.sol#L269)

https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaMultiSig/MultiSig.sol#L266-L272


 - [ ] ID-14
[StateUpdates.cancelUnpause(address)](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaMultiSig/Updates/StateUpdates.sol#L118-L124) deletes [MultiSigStorage.UnpauseProposal](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaMultiSig/MultiSigStorage.sol#L218-L225) which contains a mapping:
	-[delete _unpauseProposal[proxy]](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaMultiSig/Updates/StateUpdates.sol#L121)

https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaMultiSig/Updates/StateUpdates.sol#L118-L124


 - [ ] ID-15
[FactoryUpdates.cancelSignerUpdate(address)](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaMultiSig/Updates/FactoryUpdates.sol#L95-L101) deletes [MultiSigStorage.SignerUpdateProposal](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaMultiSig/MultiSigStorage.sol#L166-L175) which contains a mapping:
	-[delete _signerUpdateProposal[newSigner]](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaMultiSig/Updates/FactoryUpdates.sol#L98)

https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaMultiSig/Updates/FactoryUpdates.sol#L95-L101

 - ID-10 through ID-15 (mapping-deletion): Acknowledged. The protocol implements per-validator vote cancellation functions that allow individual validators to clear their hasValidated storage slot before re-participation. The residual mapping data from delete is unreachable and non-exploitable given the isProposed gate on all vote functions.


## unused-return
Impact: Medium
Confidence: Medium
 - [ ] ID-16
[ERC1967Utils.upgradeBeaconToAndCall(address,bytes)](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Utils.sol#L157-L166) ignores return value by [Address.functionDelegateCall(IBeacon(newBeacon).implementation(),data)](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Utils.sol#L162)

https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Utils.sol#L157-L166


 - [ ] ID-17
[ERC1967Utils.upgradeToAndCall(address,bytes)](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Utils.sol#L67-L76) ignores return value by [Address.functionDelegateCall(newImplementation,data)](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Utils.sol#L72)

https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Utils.sol#L67-L76


## missing-zero-check
Impact: Low
Confidence: Medium
 - [ ] ID-18
[RegistryFactory.updateSigner(address).newSigner](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaRegistry/RegistryFactory.sol#L117) lacks a zero-check on :
		- [_signer = newSigner](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaRegistry/RegistryFactory.sol#L118)

https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaRegistry/RegistryFactory.sol#L117


 - [ ] ID-19
[RegistryFactory.updateImplementation(address).newImpl](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaRegistry/RegistryFactory.sol#L123) lacks a zero-check on :
		- [_implementation = newImpl](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaRegistry/RegistryFactory.sol#L124)

https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaRegistry/RegistryFactory.sol#L123


 - [ ] ID-20
[RegistryFactory.initialize(address,address,address,address).multiSig](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaRegistry/RegistryFactory.sol#L88) lacks a zero-check on :
		- [_multiSig = multiSig](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaRegistry/RegistryFactory.sol#L93)

https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaRegistry/RegistryFactory.sol#L88


 - [ ] ID-21
[RegistryFactory.initialize(address,address,address,address).impl](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaRegistry/RegistryFactory.sol#L88) lacks a zero-check on :
		- [_implementation = impl](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaRegistry/RegistryFactory.sol#L92)

https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaRegistry/RegistryFactory.sol#L88


 - [ ] ID-22
[Singleton.initialize(address).multiSig](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaSingleton/Singleton.sol#L67) lacks a zero-check on :
		- [_multiSig = multiSig](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaSingleton/Singleton.sol#L68)

https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaSingleton/Singleton.sol#L67


 - [ ] ID-23
[RegistryFactory.initialize(address,address,address,address).ngns](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaRegistry/RegistryFactory.sol#L88) lacks a zero-check on :
		- [_ngns = ngns](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaRegistry/RegistryFactory.sol#L95)

https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaRegistry/RegistryFactory.sol#L88


 - [ ] ID-24
[BaseRegistry.initialize(address,address,string).singleton](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaRegistry/BaseRegistry.sol#L70) lacks a zero-check on :
		- [_singleton = singleton](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaRegistry/BaseRegistry.sol#L74)

https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaRegistry/BaseRegistry.sol#L70


 - [ ] ID-25
[RegistryFactory.initialize(address,address,address,address).signer](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaRegistry/RegistryFactory.sol#L88) lacks a zero-check on :
		- [_signer = signer](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaRegistry/RegistryFactory.sol#L94)

https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaRegistry/RegistryFactory.sol#L88


 - [ ] ID-26
[BaseRegistry.initialize(address,address,string).factory](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaRegistry/BaseRegistry.sol#L70) lacks a zero-check on :
		- [_factory = factory](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaRegistry/BaseRegistry.sol#L75)

https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaRegistry/BaseRegistry.sol#L70


## reentrancy-benign
Impact: Low
Confidence: Medium
 - [ ] ID-27
Reentrancy in [MultiSig.proposeInitRegistry(string,address,address)](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaMultiSig/MultiSig.sol#L74-L95):
	External calls:
	- [clone = _deployClone(singleton,factory,namespace_)](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaMultiSig/MultiSig.sol#L78)
		- [(success,returnData) = factory.call(data)](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaMultiSig/MultiSigHelper.sol#L189)
	State variables written after the call(s):
	- [r.clone = clone](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaMultiSig/MultiSig.sol#L87)
	- [r.namespace_ = packed](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaMultiSig/MultiSig.sol#L88)
	- [r.namespaceLen = _toBytes1(bytes(namespace_).length)](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaMultiSig/MultiSig.sol#L89)
	- [r.singleton = singleton](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaMultiSig/MultiSig.sol#L90)
	- [r.remaining = required](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaMultiSig/MultiSig.sol#L91)
	- [r.isProposed = true](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaMultiSig/MultiSig.sol#L92)

https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaMultiSig/MultiSig.sol#L74-L95


## reentrancy-events
Impact: Low
Confidence: Medium
 - [ ] ID-28
Reentrancy in [BaseRegistry.link(bytes,address,bytes)](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaRegistry/BaseRegistry.sol#L84-L119):
	External calls:
	- [isLinked = ISalvaSingleton(_singleton).linkNameAlias(name,wallet,caller)](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaRegistry/BaseRegistry.sol#L114)
	Event emitted after the call(s):
	- [LinkSuccess(name,wallet)](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaRegistry/BaseRegistry.sol#L117)

https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaRegistry/BaseRegistry.sol#L84-L119


 - [ ] ID-29
Reentrancy in [BaseRegistry.unlink(bytes)](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaRegistry/BaseRegistry.sol#L122-L127):
	External calls:
	- [isSuccess = ISalvaSingleton(_singleton).unlink(name,_msgSender())](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaRegistry/BaseRegistry.sol#L123)
	Event emitted after the call(s):
	- [UnlinkSuccess(name)](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaRegistry/BaseRegistry.sol#L125)

https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaRegistry/BaseRegistry.sol#L122-L127


 - [ ] ID-30
Reentrancy in [MultiSig.proposeInitRegistry(string,address,address)](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaMultiSig/MultiSig.sol#L74-L95):
	External calls:
	- [clone = _deployClone(singleton,factory,namespace_)](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaMultiSig/MultiSig.sol#L78)
		- [(success,returnData) = factory.call(data)](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaMultiSig/MultiSigHelper.sol#L189)
	Event emitted after the call(s):
	- [RegistryInitProposed(clone,namespace_,required)](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaMultiSig/MultiSig.sol#L94)

https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaMultiSig/MultiSig.sol#L74-L95


## timestamp
Impact: Low
Confidence: Medium
 - [ ] ID-31
[MultiSig.executeInitRegistry(address)](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaMultiSig/MultiSig.sol#L138-L156) uses timestamp for comparisons
	Dangerous comparisons:
	- [! r.isValidated || block.timestamp < r.timeLock](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaMultiSig/MultiSig.sol#L147)

https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaMultiSig/MultiSig.sol#L138-L156


 - [ ] ID-32
[StateUpdates.executeUnpause(address)](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaMultiSig/Updates/StateUpdates.sol#L137-L156) uses timestamp for comparisons
	Dangerous comparisons:
	- [! u.isValidated || block.timestamp < u.timeLock](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaMultiSig/Updates/StateUpdates.sol#L141)

https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaMultiSig/Updates/StateUpdates.sol#L137-L156


 - [ ] ID-33
[FactoryUpdates.executeSignerUpdate(address)](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaMultiSig/Updates/FactoryUpdates.sol#L115-L132) uses timestamp for comparisons
	Dangerous comparisons:
	- [! s.isValidated || block.timestamp < s.timeLock](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaMultiSig/Updates/FactoryUpdates.sol#L124)

https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaMultiSig/Updates/FactoryUpdates.sol#L115-L132


 - [ ] ID-34
[Upgrades.executeUpgrade(address)](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaMultiSig/Upgrades/Upgrades.sol#L122-L144) uses timestamp for comparisons
	Dangerous comparisons:
	- [! p.isValidated || block.timestamp < p.timeLock](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaMultiSig/Upgrades/Upgrades.sol#L131)

https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaMultiSig/Upgrades/Upgrades.sol#L122-L144


 - [ ] ID-35
[FactoryUpdates.executeBaseRegistryImplUpdate(address)](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaMultiSig/Updates/FactoryUpdates.sol#L232-L249) uses timestamp for comparisons
	Dangerous comparisons:
	- [! b.isValidated || block.timestamp < b.timeLock](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaMultiSig/Updates/FactoryUpdates.sol#L241)

https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaMultiSig/Updates/FactoryUpdates.sol#L232-L249


 - [ ] ID-36
[MultiSig.executeValidatorUpdate(address)](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaMultiSig/MultiSig.sol#L242-L259) uses timestamp for comparisons
	Dangerous comparisons:
	- [! v.isValidated || block.timestamp < v.timeLock](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaMultiSig/MultiSig.sol#L251)

https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaMultiSig/MultiSig.sol#L242-L259


## assembly
Impact: Informational
Confidence: High
 - [ ] ID-37
[Create2.deploy(uint256,bytes32,bytes)](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/Create2.sol#L38-L55) uses assembly
	- [INLINE ASM](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/Create2.sol#L45-L47)

https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/Create2.sol#L38-L55


 - [ ] ID-38
[NameLib._performLinkToWallet(bytes32,address,address)](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaModules/Library/NameLib.sol#L299-L311) uses assembly
	- [INLINE ASM](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaModules/Library/NameLib.sol#L303-L309)

https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaModules/Library/NameLib.sol#L299-L311


 - [ ] ID-39
[Strings.toChecksumHexString(address)](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/Strings.sol#L108-L126) uses assembly
	- [INLINE ASM](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/Strings.sol#L113-L115)

https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/Strings.sol#L108-L126


 - [ ] ID-40
[UnlinkName.unlink(bytes,address)](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaModules/Aliases/NameAlias/UnlinkName.sol#L56-L80) uses assembly
	- [INLINE ASM](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaModules/Aliases/NameAlias/UnlinkName.sol#L64-L67)

https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaModules/Aliases/NameAlias/UnlinkName.sol#L56-L80


 - [ ] ID-41
[Math.tryMul(uint256,uint256)](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L73-L84) uses assembly
	- [INLINE ASM](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L76-L80)

https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L73-L84


 - [ ] ID-42
[Math._zeroBytes(bytes)](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L478-L490) uses assembly
	- [INLINE ASM](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L482-L484)

https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L478-L490


 - [ ] ID-43
[LowLevelCall.callReturn64Bytes(address,uint256,bytes)](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/LowLevelCall.sol#L38-L48) uses assembly
	- [INLINE ASM](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/LowLevelCall.sol#L43-L47)

https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/LowLevelCall.sol#L38-L48


 - [ ] ID-44
[StorageSlot.getAddressSlot(bytes32)](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#L66-L70) uses assembly
	- [INLINE ASM](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#L67-L69)

https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#L66-L70


 - [ ] ID-45
[ECDSA.parse(bytes)](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol#L217-L240) uses assembly
	- [INLINE ASM](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol#L218-L239)

https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol#L217-L240


 - [ ] ID-46
[MessageHashUtils.toDomainTypeHash(bytes1)](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol#L182-L227) uses assembly
	- [INLINE ASM](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol#L185-L226)

https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol#L182-L227


 - [ ] ID-47
[Math.mul512(uint256,uint256)](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L37-L46) uses assembly
	- [INLINE ASM](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L41-L45)

https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L37-L46


 - [ ] ID-48
[NameLib._checkCollision(bytes32)](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaModules/Library/NameLib.sol#L257-L263) uses assembly
	- [INLINE ASM](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaModules/Library/NameLib.sol#L259-L261)

https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaModules/Library/NameLib.sol#L257-L263


 - [ ] ID-49
[LowLevelCall.callNoReturn(address,uint256,bytes)](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/LowLevelCall.sol#L19-L23) uses assembly
	- [INLINE ASM](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/LowLevelCall.sol#L20-L22)

https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/LowLevelCall.sol#L19-L23


 - [ ] ID-50
[Math.mulDiv(uint256,uint256,uint256)](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L206-L277) uses assembly
	- [INLINE ASM](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L229-L236)
	- [INLINE ASM](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L242-L251)

https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L206-L277


 - [ ] ID-51
[Math.add512(uint256,uint256)](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L25-L30) uses assembly
	- [INLINE ASM](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L26-L29)

https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L25-L30


 - [ ] ID-52
[LowLevelCall.bubbleRevert()](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/LowLevelCall.sol#L114-L120) uses assembly
	- [INLINE ASM](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/LowLevelCall.sol#L115-L119)

https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/LowLevelCall.sol#L114-L120


 - [ ] ID-53
[ECDSA.tryRecoverCalldata(bytes32,bytes)](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol#L85-L104) uses assembly
	- [INLINE ASM](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol#L95-L99)

https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol#L85-L104


 - [ ] ID-54
[BaseRegistry.link(bytes,address,bytes)](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaRegistry/BaseRegistry.sol#L84-L119) uses assembly
	- [INLINE ASM](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaRegistry/BaseRegistry.sol#L93-L97)

https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaRegistry/BaseRegistry.sol#L84-L119


 - [ ] ID-55
[SafeCast.toUint(bool)](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/math/SafeCast.sol#L1157-L1161) uses assembly
	- [INLINE ASM](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/math/SafeCast.sol#L1158-L1160)

https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/math/SafeCast.sol#L1157-L1161


 - [ ] ID-56
[ECDSA.tryRecover(bytes32,bytes)](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol#L61-L80) uses assembly
	- [INLINE ASM](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol#L71-L75)

https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol#L61-L80


 - [ ] ID-57
[StorageSlot.getInt256Slot(bytes32)](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#L102-L106) uses assembly
	- [INLINE ASM](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#L103-L105)

https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#L102-L106


 - [ ] ID-58
[NameLib._normalizeSegments(bytes32,uint256,bytes32,uint256)](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaModules/Library/NameLib.sol#L222-L246) uses assembly
	- [INLINE ASM](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaModules/Library/NameLib.sol#L237-L243)

https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaModules/Library/NameLib.sol#L222-L246


 - [ ] ID-59
[LinkName.linkNameAlias(bytes,address,address)](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaModules/Aliases/NameAlias/LinkName.sol#L64-L91) uses assembly
	- [INLINE ASM](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaModules/Aliases/NameAlias/LinkName.sol#L77-L80)

https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaModules/Aliases/NameAlias/LinkName.sol#L64-L91


 - [ ] ID-60
[Math.tryModExp(bytes,bytes,bytes)](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L451-L473) uses assembly
	- [INLINE ASM](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L463-L472)

https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L451-L473


 - [ ] ID-61
[Bytes.concat(bytes[])](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/Bytes.sol#L183-L203) uses assembly
	- [INLINE ASM](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/Bytes.sol#L194-L196)

https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/Bytes.sol#L183-L203


 - [ ] ID-62
[NameLib._computeNameHash(bytes31,uint256,uint256,uint256)](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaModules/Library/NameLib.sol#L45-L63) uses assembly
	- [INLINE ASM](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaModules/Library/NameLib.sol#L51-L58)

https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaModules/Library/NameLib.sol#L45-L63


 - [ ] ID-63
[Math.tryModExp(uint256,uint256,uint256)](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L411-L435) uses assembly
	- [INLINE ASM](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L413-L434)

https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L411-L435


 - [ ] ID-64
[LowLevelCall.returnData()](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/LowLevelCall.sol#L104-L111) uses assembly
	- [INLINE ASM](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/LowLevelCall.sol#L105-L110)

https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/LowLevelCall.sol#L104-L111


 - [ ] ID-65
[Panic.panic(uint256)](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/Panic.sol#L50-L56) uses assembly
	- [INLINE ASM](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/Panic.sol#L51-L55)

https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/Panic.sol#L50-L56


 - [ ] ID-66
[SafeERC20._safeTransfer(IERC20,address,uint256,bool)](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol#L176-L200) uses assembly
	- [INLINE ASM](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol#L179-L199)

https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol#L176-L200


 - [ ] ID-67
[StorageSlot.getBytesSlot(bytes32)](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#L129-L133) uses assembly
	- [INLINE ASM](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#L130-L132)

https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#L129-L133


 - [ ] ID-68
[Resolve.resolveAddress(bytes)](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaModules/Resolve.sol#L53-L93) uses assembly
	- [INLINE ASM](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaModules/Resolve.sol#L61-L64)
	- [INLINE ASM](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaModules/Resolve.sol#L77-L85)
	- [INLINE ASM](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaModules/Resolve.sol#L90-L92)

https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaModules/Resolve.sol#L53-L93


 - [ ] ID-69
[MessageHashUtils.toDataWithIntendedValidatorHash(address,bytes32)](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol#L71-L81) uses assembly
	- [INLINE ASM](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol#L75-L80)

https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol#L71-L81


 - [ ] ID-70
[LowLevelCall.delegatecallReturn64Bytes(address,bytes)](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/LowLevelCall.sol#L85-L94) uses assembly
	- [INLINE ASM](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/LowLevelCall.sol#L89-L93)

https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/LowLevelCall.sol#L85-L94


 - [ ] ID-71
[Math.log2(uint256)](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L619-L658) uses assembly
	- [INLINE ASM](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L655-L657)

https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L619-L658


 - [ ] ID-72
[NameLib._normalizeAndValidate(uint256,bytes32,uint8)](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaModules/Library/NameLib.sol#L98-L208) uses assembly
	- [INLINE ASM](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaModules/Library/NameLib.sol#L135-L144)
	- [INLINE ASM](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaModules/Library/NameLib.sol#L148-L152)
	- [INLINE ASM](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaModules/Library/NameLib.sol#L162-L171)
	- [INLINE ASM](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaModules/Library/NameLib.sol#L176-L179)

https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaModules/Library/NameLib.sol#L98-L208


 - [ ] ID-73
[LowLevelCall.staticcallReturn64Bytes(address,bytes)](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/LowLevelCall.sol#L62-L71) uses assembly
	- [INLINE ASM](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/LowLevelCall.sol#L66-L70)

https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/LowLevelCall.sol#L62-L71


 - [ ] ID-74
[StorageSlot.getStringSlot(string)](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#L120-L124) uses assembly
	- [INLINE ASM](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#L121-L123)

https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#L120-L124


 - [ ] ID-75
[Bytes.slice(bytes,uint256,uint256)](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/Bytes.sol#L86-L98) uses assembly
	- [INLINE ASM](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/Bytes.sol#L93-L95)

https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/Bytes.sol#L86-L98


 - [ ] ID-76
[Strings.toString(uint256)](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/Strings.sol#L42-L60) uses assembly
	- [INLINE ASM](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/Strings.sol#L47-L49)
	- [INLINE ASM](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/Strings.sol#L52-L54)

https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/Strings.sol#L42-L60


 - [ ] ID-77
[StorageSlot.getBytes32Slot(bytes32)](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#L84-L88) uses assembly
	- [INLINE ASM](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#L85-L87)

https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#L84-L88


 - [ ] ID-78
[Math.tryMod(uint256,uint256)](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L102-L110) uses assembly
	- [INLINE ASM](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L105-L108)

https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L102-L110


 - [ ] ID-79
[StorageSlot.getBytesSlot(bytes)](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#L138-L142) uses assembly
	- [INLINE ASM](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#L139-L141)

https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#L138-L142


 - [ ] ID-80
[Clones.clone(address,uint256)](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/proxy/Clones.sol#L47-L62) uses assembly
	- [INLINE ASM](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/proxy/Clones.sol#L51-L58)

https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/proxy/Clones.sol#L47-L62


 - [ ] ID-81
[Strings._unsafeWriteBytesOffset(bytes,uint256,bytes1)](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/Strings.sol#L526-L531) uses assembly
	- [INLINE ASM](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/Strings.sol#L528-L530)

https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/Strings.sol#L526-L531


 - [ ] ID-82
[Clones.cloneWithImmutableArgs(address,bytes,uint256)](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/proxy/Clones.sol#L167-L182) uses assembly
	- [INLINE ASM](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/proxy/Clones.sol#L176-L178)

https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/proxy/Clones.sol#L167-L182


 - [ ] ID-83
[Math.tryDiv(uint256,uint256)](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L89-L97) uses assembly
	- [INLINE ASM](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L92-L95)

https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L89-L97


 - [ ] ID-84
[Clones.predictDeterministicAddress(address,bytes32,address)](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/proxy/Clones.sol#L114-L129) uses assembly
	- [INLINE ASM](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/proxy/Clones.sol#L119-L128)

https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/proxy/Clones.sol#L114-L129


 - [ ] ID-85
[Create2.computeAddress(bytes32,bytes32,address)](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/Create2.sol#L69-L90) uses assembly
	- [INLINE ASM](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/Create2.sol#L70-L89)

https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/Create2.sol#L69-L90


 - [ ] ID-86
[LowLevelCall.staticcallNoReturn(address,bytes)](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/LowLevelCall.sol#L51-L55) uses assembly
	- [INLINE ASM](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/LowLevelCall.sol#L52-L54)

https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/LowLevelCall.sol#L51-L55


 - [ ] ID-87
[LowLevelCall.delegatecallNoReturn(address,bytes)](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/LowLevelCall.sol#L74-L78) uses assembly
	- [INLINE ASM](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/LowLevelCall.sol#L75-L77)

https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/LowLevelCall.sol#L74-L78


 - [ ] ID-88
[Bytes.splice(bytes,uint256,uint256)](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/Bytes.sol#L117-L129) uses assembly
	- [INLINE ASM](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/Bytes.sol#L123-L126)

https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/Bytes.sol#L117-L129


 - [ ] ID-89
[StorageSlot.getBooleanSlot(bytes32)](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#L75-L79) uses assembly
	- [INLINE ASM](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#L76-L78)

https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#L75-L79


 - [ ] ID-90
[SafeERC20._safeApprove(IERC20,address,uint256,bool)](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol#L255-L279) uses assembly
	- [INLINE ASM](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol#L258-L278)

https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol#L255-L279


 - [ ] ID-91
[StorageSlot.getStringSlot(bytes32)](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#L111-L115) uses assembly
	- [INLINE ASM](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#L112-L114)

https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#L111-L115


 - [ ] ID-92
[Bytes.toNibbles(bytes)](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/Bytes.sol#L210-L245) uses assembly
	- [INLINE ASM](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/Bytes.sol#L211-L244)

https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/Bytes.sol#L210-L245


 - [ ] ID-93
[LowLevelCall.bubbleRevert(bytes)](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/LowLevelCall.sol#L122-L126) uses assembly
	- [INLINE ASM](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/LowLevelCall.sol#L123-L125)

https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/LowLevelCall.sol#L122-L126


 - [ ] ID-94
[Bytes.replace(bytes,uint256,bytes,uint256,uint256)](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/Bytes.sol#L154-L172) uses assembly
	- [INLINE ASM](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/Bytes.sol#L167-L169)

https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/Bytes.sol#L154-L172


 - [ ] ID-95
[Bytes._unsafeReadBytesOffset(bytes,uint256)](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/Bytes.sol#L326-L331) uses assembly
	- [INLINE ASM](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/Bytes.sol#L328-L330)

https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/Bytes.sol#L326-L331


 - [ ] ID-96
[Strings._unsafeReadBytesOffset(bytes,uint256)](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/Strings.sol#L513-L518) uses assembly
	- [INLINE ASM](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/Strings.sol#L515-L517)

https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/Strings.sol#L513-L518


 - [ ] ID-97
[NameLib._performUnlink(bytes32,bytes32)](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaModules/Library/NameLib.sol#L321-L330) uses assembly
	- [INLINE ASM](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaModules/Library/NameLib.sol#L325-L328)

https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaModules/Library/NameLib.sol#L321-L330


 - [ ] ID-98
[Initializable._getInitializableStorage()](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/proxy/utils/Initializable.sol#L232-L237) uses assembly
	- [INLINE ASM](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/proxy/utils/Initializable.sol#L234-L236)

https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/proxy/utils/Initializable.sol#L232-L237


 - [ ] ID-99
[MessageHashUtils.toTypedDataHash(bytes32,bytes32)](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol#L92-L100) uses assembly
	- [INLINE ASM](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol#L93-L99)

https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol#L92-L100


 - [ ] ID-100
[NameLib._checkCaller(address,bytes32)](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaModules/Library/NameLib.sol#L275-L286) uses assembly
	- [INLINE ASM](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaModules/Library/NameLib.sol#L280-L284)

https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaModules/Library/NameLib.sol#L275-L286


 - [ ] ID-101
[MessageHashUtils.toDomainSeparator(bytes1,bytes32,bytes32,uint256,address,bytes32)](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol#L137-L179) uses assembly
	- [INLINE ASM](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol#L147-L178)

https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol#L137-L179


 - [ ] ID-102
[SafeERC20._safeTransferFrom(IERC20,address,address,uint256,bool)](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol#L212-L244) uses assembly
	- [INLINE ASM](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol#L221-L243)

https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol#L212-L244


 - [ ] ID-103
[Strings.escapeJSON(string)](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/Strings.sol#L461-L505) uses assembly
	- [INLINE ASM](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/Strings.sol#L468-L470)
	- [INLINE ASM](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/Strings.sol#L499-L502)

https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/Strings.sol#L461-L505


 - [ ] ID-104
[LowLevelCall.returnDataSize()](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/LowLevelCall.sol#L97-L101) uses assembly
	- [INLINE ASM](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/LowLevelCall.sol#L98-L100)

https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/LowLevelCall.sol#L97-L101


 - [ ] ID-105
[StorageSlot.getUint256Slot(bytes32)](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#L93-L97) uses assembly
	- [INLINE ASM](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#L94-L96)

https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#L93-L97


 - [ ] ID-106
[ECDSA.parseCalldata(bytes)](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol#L245-L268) uses assembly
	- [INLINE ASM](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol#L246-L267)

https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol#L245-L268


 - [ ] ID-107
[Clones.cloneDeterministic(address,bytes32,uint256)](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/proxy/Clones.sol#L90-L109) uses assembly
	- [INLINE ASM](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/proxy/Clones.sol#L98-L105)

https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/proxy/Clones.sol#L90-L109


 - [ ] ID-108
[MessageHashUtils.toEthSignedMessageHash(bytes32)](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol#L32-L38) uses assembly
	- [INLINE ASM](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol#L33-L37)

https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol#L32-L38


 - [ ] ID-109
[Clones.fetchCloneArgs(address)](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/proxy/Clones.sol#L261-L267) uses assembly
	- [INLINE ASM](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/proxy/Clones.sol#L263-L265)

https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/proxy/Clones.sol#L261-L267


## pragma
Impact: Informational
Confidence: High
 - [ ] ID-110
8 different versions of Solidity are used:
	- Version constraint >=0.6.2 is used by:
		-[>=0.6.2](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/interfaces/IERC1363.sol#L4)
	- Version constraint >=0.4.16 is used by:
		-[>=0.4.16](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/interfaces/IERC165.sol#L4)
		-[>=0.4.16](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol#L4)
		-[>=0.4.16](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/interfaces/draft-IERC1822.sol#L4)
		-[>=0.4.16](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/proxy/beacon/IBeacon.sol#L4)
		-[>=0.4.16](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol#L4)
		-[>=0.4.16](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/introspection/IERC165.sol#L4)
	- Version constraint >=0.4.11 is used by:
		-[>=0.4.11](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/interfaces/IERC1967.sol#L4)
	- Version constraint ^0.8.20 is used by:
		-[^0.8.20](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/proxy/Clones.sol#L4)
		-[^0.8.20](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/proxy/utils/Initializable.sol#L4)
		-[^0.8.20](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol#L4)
		-[^0.8.20](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/Address.sol#L4)
		-[^0.8.20](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/Create2.sol#L4)
		-[^0.8.20](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/Errors.sol#L4)
		-[^0.8.20](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/LowLevelCall.sol#L4)
		-[^0.8.20](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/Panic.sol#L4)
		-[^0.8.20](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#L5)
		-[^0.8.20](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol#L4)
		-[^0.8.20](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L4)
		-[^0.8.20](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/math/SafeCast.sol#L5)
		-[^0.8.20](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/math/SignedMath.sol#L4)
	- Version constraint ^0.8.21 is used by:
		-[^0.8.21](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Utils.sol#L4)
	- Version constraint ^0.8.22 is used by:
		-[^0.8.22](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/proxy/utils/UUPSUpgradeable.sol#L4)
	- Version constraint ^0.8.24 is used by:
		-[^0.8.24](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/Bytes.sol#L4)
		-[^0.8.24](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/Strings.sol#L4)
		-[^0.8.24](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol#L4)
	- Version constraint ^0.8.30 is used by:
		-[^0.8.30](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/Interface/IBaseRegistry.sol#L2)
		-[^0.8.30](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/Interface/IRegistryFactory.sol#L2)
		-[^0.8.30](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/Interface/ISalvaSingleton.sol#L2)
		-[^0.8.30](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaModules/Aliases/NameAlias/LinkName.sol#L2)
		-[^0.8.30](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaModules/Aliases/NameAlias/UnlinkName.sol#L2)
		-[^0.8.30](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaModules/Initialize.sol#L2)
		-[^0.8.30](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaModules/Library/Context.sol#L2)
		-[^0.8.30](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaModules/Library/Errors.sol#L2)
		-[^0.8.30](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaModules/Library/Modifier.sol#L2)
		-[^0.8.30](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaModules/Library/NameLib.sol#L2)
		-[^0.8.30](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaModules/Library/Storage.sol#L2)
		-[^0.8.30](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaModules/Resolve.sol#L2)
		-[^0.8.30](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaMultiSig/Events.sol#L2)
		-[^0.8.30](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaMultiSig/MultiSig.sol#L2)
		-[^0.8.30](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaMultiSig/MultiSigErrors.sol#L2)
		-[^0.8.30](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaMultiSig/MultiSigHelper.sol#L2)
		-[^0.8.30](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaMultiSig/MultiSigModifier.sol#L2)
		-[^0.8.30](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaMultiSig/MultiSigStorage.sol#L2)
		-[^0.8.30](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaMultiSig/Updates/FactoryUpdates.sol#L2)
		-[^0.8.30](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaMultiSig/Updates/StateUpdates.sol#L2)
		-[^0.8.30](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaMultiSig/Upgrades/Upgrades.sol#L2)
		-[^0.8.30](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaRegistry/BaseRegistry.sol#L2)
		-[^0.8.30](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaRegistry/RegistryErrors.sol#L2)
		-[^0.8.30](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaRegistry/RegistryFactory.sol#L2)
		-[^0.8.30](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaSingleton/Singleton.sol#L2)

https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/interfaces/IERC1363.sol#L4


## cyclomatic-complexity
Impact: Informational
Confidence: High
 - [ ] ID-111
[NameLib._normalizeAndValidate(uint256,bytes32,uint8)](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaModules/Library/NameLib.sol#L98-L208) has a high cyclomatic complexity (19).

https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaModules/Library/NameLib.sol#L98-L208


## solc-version
Impact: Informational
Confidence: High
 - [ ] ID-112
Version constraint >=0.6.2 contains known severe issues (https://solidity.readthedocs.io/en/latest/bugs.html)
	- MissingSideEffectsOnSelectorAccess
	- AbiReencodingHeadOverflowWithStaticArrayCleanup
	- DirtyBytesArrayToStorage
	- NestedCalldataArrayAbiReencodingSizeValidation
	- ABIDecodeTwoDimensionalArrayMemory
	- KeccakCaching
	- EmptyByteArrayCopy
	- DynamicArrayCleanup
	- MissingEscapingInFormatting
	- ArraySliceDynamicallyEncodedBaseType
	- ImplicitConstructorCallvalueCheck
	- TupleAssignmentMultiStackSlotComponents
	- MemoryArrayCreationOverflow.
It is used by:
	- [>=0.6.2](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/interfaces/IERC1363.sol#L4)

https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/interfaces/IERC1363.sol#L4


 - [ ] ID-113
Version constraint ^0.8.20 contains known severe issues (https://solidity.readthedocs.io/en/latest/bugs.html)
	- VerbatimInvalidDeduplication
	- FullInlinerNonExpressionSplitArgumentEvaluationOrder
	- MissingSideEffectsOnSelectorAccess.
It is used by:
	- [^0.8.20](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/proxy/Clones.sol#L4)
	- [^0.8.20](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/proxy/utils/Initializable.sol#L4)
	- [^0.8.20](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol#L4)
	- [^0.8.20](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/Address.sol#L4)
	- [^0.8.20](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/Create2.sol#L4)
	- [^0.8.20](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/Errors.sol#L4)
	- [^0.8.20](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/LowLevelCall.sol#L4)
	- [^0.8.20](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/Panic.sol#L4)
	- [^0.8.20](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#L5)
	- [^0.8.20](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol#L4)
	- [^0.8.20](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L4)
	- [^0.8.20](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/math/SafeCast.sol#L5)
	- [^0.8.20](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/math/SignedMath.sol#L4)

https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/proxy/Clones.sol#L4


 - [ ] ID-114
Version constraint >=0.4.11 contains known severe issues (https://solidity.readthedocs.io/en/latest/bugs.html)
	- DirtyBytesArrayToStorage
	- KeccakCaching
	- EmptyByteArrayCopy
	- DynamicArrayCleanup
	- ImplicitConstructorCallvalueCheck
	- TupleAssignmentMultiStackSlotComponents
	- MemoryArrayCreationOverflow
	- privateCanBeOverridden
	- SignedArrayStorageCopy
	- UninitializedFunctionPointerInConstructor_0.4.x
	- IncorrectEventSignatureInLibraries_0.4.x
	- ExpExponentCleanup
	- NestedArrayFunctionCallDecoder
	- ZeroFunctionSelector
	- DelegateCallReturnValue
	- ECRecoverMalformedInput
	- SkipEmptyStringLiteral.
It is used by:
	- [>=0.4.11](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/interfaces/IERC1967.sol#L4)

https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/interfaces/IERC1967.sol#L4


 - [ ] ID-115
Version constraint >=0.4.16 contains known severe issues (https://solidity.readthedocs.io/en/latest/bugs.html)
	- DirtyBytesArrayToStorage
	- ABIDecodeTwoDimensionalArrayMemory
	- KeccakCaching
	- EmptyByteArrayCopy
	- DynamicArrayCleanup
	- ImplicitConstructorCallvalueCheck
	- TupleAssignmentMultiStackSlotComponents
	- MemoryArrayCreationOverflow
	- privateCanBeOverridden
	- SignedArrayStorageCopy
	- ABIEncoderV2StorageArrayWithMultiSlotElement
	- DynamicConstructorArgumentsClippedABIV2
	- UninitializedFunctionPointerInConstructor_0.4.x
	- IncorrectEventSignatureInLibraries_0.4.x
	- ExpExponentCleanup
	- NestedArrayFunctionCallDecoder
	- ZeroFunctionSelector.
It is used by:
	- [>=0.4.16](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/interfaces/IERC165.sol#L4)
	- [>=0.4.16](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol#L4)
	- [>=0.4.16](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/interfaces/draft-IERC1822.sol#L4)
	- [>=0.4.16](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/proxy/beacon/IBeacon.sol#L4)
	- [>=0.4.16](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol#L4)
	- [>=0.4.16](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/introspection/IERC165.sol#L4)

https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/interfaces/IERC165.sol#L4


 - [ ] ID-116
Version constraint ^0.8.21 contains known severe issues (https://solidity.readthedocs.io/en/latest/bugs.html)
	- VerbatimInvalidDeduplication.
It is used by:
	- [^0.8.21](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Utils.sol#L4)

https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Utils.sol#L4


 - [ ] ID-117
Version constraint ^0.8.22 contains known severe issues (https://solidity.readthedocs.io/en/latest/bugs.html)
	- VerbatimInvalidDeduplication.
It is used by:
	- [^0.8.22](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/proxy/utils/UUPSUpgradeable.sol#L4)

https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/proxy/utils/UUPSUpgradeable.sol#L4


## low-level-calls
Impact: Informational
Confidence: High
 - [ ] ID-118
Low level call in [StateUpdates._unpauseExternalState(address)](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaMultiSig/Updates/StateUpdates.sol#L175-L178):
	- [(success,None) = proxy.call(_encodeUnpause())](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaMultiSig/Updates/StateUpdates.sol#L176)

https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaMultiSig/Updates/StateUpdates.sol#L175-L178


 - [ ] ID-119
Low level call in [StateUpdates._pauseExternalState(address)](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaMultiSig/Updates/StateUpdates.sol#L166-L169):
	- [(success,None) = proxy.call(_encodePause())](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaMultiSig/Updates/StateUpdates.sol#L167)

https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaMultiSig/Updates/StateUpdates.sol#L166-L169


 - [ ] ID-120
Low level call in [MultiSigHelper._deployClone(address,address,string)](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaMultiSig/MultiSigHelper.sol#L182-L192):
	- [(success,returnData) = factory.call(data)](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaMultiSig/MultiSigHelper.sol#L189)

https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaMultiSig/MultiSigHelper.sol#L182-L192


 - [ ] ID-121
Low level call in [Upgrades._executeExternalUpgrade(address,address)](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaMultiSig/Upgrades/Upgrades.sol#L166-L172):
	- [(success,None) = proxy.call(_encodeUpgrade(newImpl))](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaMultiSig/Upgrades/Upgrades.sol#L170)

https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaMultiSig/Upgrades/Upgrades.sol#L166-L172


## missing-inheritance
Impact: Informational
Confidence: High
 - [ ] ID-122
[Singleton](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaSingleton/Singleton.sol#L28-L147) should inherit from [ISalvaSingleton](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/Interface/ISalvaSingleton.sol#L19-L127)

https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaSingleton/Singleton.sol#L28-L147


 - [ ] ID-123
[RegistryFactory](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaRegistry/RegistryFactory.sol#L27-L204) should inherit from [IRegistryFactory](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/Interface/IRegistryFactory.sol#L13-L86)

https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaRegistry/RegistryFactory.sol#L27-L204


 - [ ] ID-124
[BaseRegistry](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaRegistry/BaseRegistry.sol#L27-L171) should inherit from [IBaseRegistry](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/Interface/IBaseRegistry.sol#L18-L108)

https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaRegistry/BaseRegistry.sol#L27-L171


## naming-convention
Impact: Informational
Confidence: High
 - [ ] ID-125
Variable [Storage._nameToWallet](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaModules/Library/Storage.sol#L86) is not in mixedCase

https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaModules/Library/Storage.sol#L86


 - [ ] ID-126
Variable [MultiSigStorage.__gap](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaMultiSig/MultiSigStorage.sol#L238) is not in mixedCase

https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaMultiSig/MultiSigStorage.sol#L238


 - [ ] ID-127
Variable [MultiSigStorage._numOfValidators](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaMultiSig/MultiSigStorage.sol#L34) is not in mixedCase

https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaMultiSig/MultiSigStorage.sol#L34


 - [ ] ID-128
Variable [RegistryFactory.__gap](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaRegistry/RegistryFactory.sol#L64) is not in mixedCase

https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaRegistry/RegistryFactory.sol#L64


 - [ ] ID-129
Variable [UUPSUpgradeable.__self](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/proxy/utils/UUPSUpgradeable.sol#L23) is not in mixedCase

https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/proxy/utils/UUPSUpgradeable.sol#L23


 - [ ] ID-130
Parameter [Singleton.nameToByte(string)._name](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaSingleton/Singleton.sol#L119) is not in mixedCase

https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaSingleton/Singleton.sol#L119


 - [ ] ID-131
Variable [Storage.__gap](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaModules/Library/Storage.sol#L96) is not in mixedCase

https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaModules/Library/Storage.sol#L96


## too-many-digits
Impact: Informational
Confidence: Medium
 - [ ] ID-132
[Bytes.reverseBytes16(bytes16)](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/Bytes.sol#L275-L286) uses literals with too many digits:
	- [value = ((value & 0xFFFFFFFF00000000FFFFFFFF00000000) >> 32) | ((value & 0x00000000FFFFFFFF00000000FFFFFFFF) << 32)](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/Bytes.sol#L282-L284)

https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/Bytes.sol#L275-L286


 - [ ] ID-133
[Math.log2(uint256)](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L619-L658) uses literals with too many digits:
	- [r = r | byte(uint256,uint256)(x >> r,0x0000010102020202030303030303030300000000000000000000000000000000)](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L656)

https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L619-L658


 - [ ] ID-134
[Clones.cloneDeterministic(address,bytes32,uint256)](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/proxy/Clones.sol#L90-L109) uses literals with too many digits:
	- [mstore(uint256,uint256)(0x00,implementation << 96 >> 232 | 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000)](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/proxy/Clones.sol#L101)

https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/proxy/Clones.sol#L90-L109


 - [ ] ID-135
[Bytes.reverseBytes32(bytes32)](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/Bytes.sol#L258-L272) uses literals with too many digits:
	- [value = ((value >> 32) & 0x00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF) | ((value & 0x00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF) << 32)](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/Bytes.sol#L265-L267)

https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/Bytes.sol#L258-L272


 - [ ] ID-136
[Bytes.toNibbles(bytes)](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/Bytes.sol#L210-L245) uses literals with too many digits:
	- [chunk_toNibbles_asm_0 = 0x0000000000000000ffffffffffffffff0000000000000000ffffffffffffffff & chunk_toNibbles_asm_0 << 64 | chunk_toNibbles_asm_0](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/Bytes.sol#L222-L225)

https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/Bytes.sol#L210-L245


 - [ ] ID-137
[Bytes.toNibbles(bytes)](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/Bytes.sol#L210-L245) uses literals with too many digits:
	- [chunk_toNibbles_asm_0 = 0x00000000ffffffff00000000ffffffff00000000ffffffff00000000ffffffff & chunk_toNibbles_asm_0 << 32 | chunk_toNibbles_asm_0](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/Bytes.sol#L226-L229)

https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/Bytes.sol#L210-L245


 - [ ] ID-138
[Clones.clone(address,uint256)](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/proxy/Clones.sol#L47-L62) uses literals with too many digits:
	- [mstore(uint256,uint256)(0x00,implementation << 96 >> 232 | 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000)](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/proxy/Clones.sol#L54)

https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/proxy/Clones.sol#L47-L62


 - [ ] ID-139
[Bytes.reverseBytes32(bytes32)](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/Bytes.sol#L258-L272) uses literals with too many digits:
	- [value = ((value >> 64) & 0x0000000000000000FFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF) | ((value & 0x0000000000000000FFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF) << 64)](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/Bytes.sol#L268-L270)

https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/utils/Bytes.sol#L258-L272


## unindexed-event-address
Impact: Informational
Confidence: High
 - [ ] ID-140
Event [IERC1967.AdminChanged(address,address)](https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/interfaces/IERC1967.sol#L18) has address parameters but no indexed parameters

https://github.com/cboi019/SALVA-NEXUS/blob/main/lib/openzeppelin-contracts/contracts/interfaces/IERC1967.sol#L18


## unused-state
Impact: Informational
Confidence: High
 - [ ] ID-141
[RegistryFactory.__gap](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaRegistry/RegistryFactory.sol#L64) is never used in [RegistryFactory](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaRegistry/RegistryFactory.sol#L27-L204)
INFO:Slither:. analyzed (49 contracts with 101 detectors), 143 result(s) found

https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaRegistry/RegistryFactory.sol#L64


 - [ ] ID-142
[Storage._ownershipIndex](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaModules/Library/Storage.sol#L76) is never used in [Singleton](https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaSingleton/Singleton.sol#L28-L147)

https://github.com/cboi019/SALVA-NEXUS/blob/main/src/SalvaModules/Library/Storage.sol#L76



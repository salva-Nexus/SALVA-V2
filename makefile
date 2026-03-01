# Load environment variables from .env
include .env

# --- TESTING ---
FORGE_TEST_SEPOLIA: 
	forge test --fork-url ${SEPOLIA_RPC_URL} -vvvv

FORGE_TEST_MAINNET: 
	forge test --fork-url ${ETH_MAINNET_RPC_URL} -vvvv

# --- WALLET MANAGEMENT ---
ADD-KEY:
	cast wallet import salva_admin --interactive

# --- DEPLOYMENT ---
DEPLOY-TO-BASE_MAINNET:
	forge script script/DeploySingleton.s.sol:DeploySingleton --rpc-url ${BASE_MAINNET_RPC_URL} --account mainKey --broadcast --verify --etherscan-api-key ${ETHERSCAN_API_KEY}

DEPLOY-TO-BASE_TESTNET:
	forge script script/DeploySingleton.s.sol:DeploySingleton --rpc-url ${BASE_SEPOLIA_RPC_URL} --account mainKey --broadcast --verify --etherscan-api-key ${ETHERSCAN_API_KEY}

# --- ACCESS CONTROL (ROLES) ---
# Fixed length mismatch by ensuring keccak result is captured correctly
GRANT-ROLE-TESTNET:
	cast send ${REGISTRY_CONTRACT_ADDRESS} "grantRole(bytes32,address)" $$(cast keccak "REGISTRAR_ROLE") ${BACKEND_MANAGER_ADDRESS} --rpc-url ${BASE_SEPOLIA_RPC_URL} --account mainKey

GRANT-ROLE-MAINNET:
	cast send ${REGISTRY_CONTRACT_ADDRESS} "grantRole(bytes32,address)" $$(cast keccak "REGISTRAR_ROLE") ${BACKEND_MANAGER_ADDRESS} --rpc-url ${BASE_SEPOLIA_RPC_URL} --account mainKey

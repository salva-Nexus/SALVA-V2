// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {AggregatorV3Interface} from "@chainlink/contracts/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {Errors} from "@Errors/Errors.sol";

/**
 * @title Price
 * @notice Converts the fixed $1 USD registration fee into its ETH equivalent
 *         using a Chainlink ETH/USD price feed.
 * @dev The fee is computed as `1e26 / latestAnswer` where `latestAnswer` is
 *      the Chainlink answer in 8-decimal USD format.
 *
 *      Staleness guard: reverts if the feed answer is non-positive or if the
 *      `updatedAt` timestamp is more than 2 hours old, protecting against
 *      depegged or unresponsive oracle scenarios.
 */
abstract contract Price is Errors {
    /**
     * @notice Returns the current $1 USD registration fee denominated in wei.
     * @dev Formula: `feeInEth = 1e26 / ethUsdPrice`
     *      where `ethUsdPrice` carries 8 decimals (Chainlink standard).
     *      Reverts with `Errors__Invalid_price` if the answer is stale or ≤ 0.
     * @param _dataFeed Address of the Chainlink ETH/USD `AggregatorV3Interface`.
     * @return _feeInEth Registration fee in wei.
     */
    function getFeeInEth(address _dataFeed) external view returns (uint256 _feeInEth) {
        (, int256 answer,, uint256 updatedAt,) = AggregatorV3Interface(_dataFeed).latestRoundData();
        if (answer <= 0 || block.timestamp - updatedAt > 2 hours) {
            revert Errors__Invalid_price();
        }
        // forge-lint: disable-next-line(unsafe-typecast)
        return 1e26 / uint256(answer);
    }
}

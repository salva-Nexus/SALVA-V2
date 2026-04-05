// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

// A Simple MockAggregator
contract MockV3Aggregator {
    int256 public latestAnswer;
    uint8 public decimals;

    constructor(uint8 _decimals, int256 _initialAnswer) {
        decimals = _decimals;
        latestAnswer = _initialAnswer;
    }

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return (0, latestAnswer, 0, block.timestamp, 0);
    }

    // This is the "God Mode" function to change the price in your tests
    function updateAnswer(int256 _answer) public {
        latestAnswer = _answer;
    }
}

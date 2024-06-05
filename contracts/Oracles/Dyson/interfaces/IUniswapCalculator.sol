// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IUniswapCalculator {
    function amountsForLiquidity(
        uint160 sqrtRatioX96,
        uint128 liquidity,
        int24 _tickLower,
        int24 _tickUpper
    ) external view returns (uint256, uint256);

    function determineTicksCalc(
        int56[] memory _cumulativeTicks,
        int24 _tickSpacing,
        int24 _tickRangeMultiplier,
        uint24 _twapTime
    ) external view returns (int24, int24);

    function getAmountsForLiquidity(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) external pure returns (uint256 amount0, uint256 amount1);

    function getLiquidity(
        address _dysonStrategy
    ) external view returns (uint256 _a0Expect, uint256 _a1Expect);

    function getLiquidityForAmount0(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0
    ) external pure returns (uint128);

    function getLiquidityForAmount1(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount1
    ) external pure returns (uint128);

    function getLiquidityForAmounts(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0,
        uint256 amount1
    ) external pure returns (uint128);

    function getSqrtRatio(int24 tick) external pure returns (uint160);

    function getSqrtRatioAtTick(int24 _tick) external view returns (uint160);

    function getTickFromPrice(uint160 price) external pure returns (int24);

    function liquidityForAmounts(
        uint160 sqrtRatioX96,
        uint256 amount0,
        uint256 amount1,
        int24 _tickLower,
        int24 _tickUpper
    ) external view returns (uint128);
}

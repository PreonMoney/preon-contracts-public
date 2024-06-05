// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IUniV2Pair {
    function decimals() external view returns (uint8);

    function getReserves()
        external
        view
        returns (
            uint256 _reserve0,
            uint256 _reserve1,
            uint256 _blockTimestampLast
        );

    function token0() external view returns (address);

    function token1() external view returns (address);

    function tokens() external view returns (address, address);

    function totalSupply() external view returns (uint256);
}

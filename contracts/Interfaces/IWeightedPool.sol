// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IWeightedPool {
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function getPoolId() external view returns (bytes32);

    function getRate() external view returns (uint256);

    function getVault() external view returns (address);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function totalSupply() external view returns (uint256);
}

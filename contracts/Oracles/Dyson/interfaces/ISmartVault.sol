// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface ISmartVault {
    function getPricePerFullShare() external view returns (uint256);

    function underlying() external view returns (address);
}

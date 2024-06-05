// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IDysonLpPool {
    function getPricePerFullShare() external view returns (uint256);

    function want() external view returns (address);
}

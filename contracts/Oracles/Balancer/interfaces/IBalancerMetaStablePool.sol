// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {IBalancerVault} from "./IBalancerVault.sol";
import {IRateProvider} from "./IRateProvider.sol";

interface IBalancerMetaStablePool {
    function getPoolId() external view returns (bytes32);

    function getRate() external view returns (uint256);

    function getLastInvariant() external view returns (uint256);

    function getLatest(uint8 x) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function getVault() external view returns (IBalancerVault);

    function getSwapFeePercentage() external view returns (uint256);

    function getRateProviders() external view returns (IRateProvider[] memory);
}

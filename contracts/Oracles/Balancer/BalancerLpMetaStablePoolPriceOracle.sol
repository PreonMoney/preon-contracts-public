// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import {IBalancerVault} from "./interfaces/IBalancerVault.sol";
import {IRateProvider, IBalancerMetaStablePool} from "./interfaces/IBalancerMetaStablePool.sol";

import "../BasePriceOracle.sol";

/**
 * @title BalancerLpMetaStablePoolPriceOracle
 * @author Bitbaby
 * @notice BalancerLpMetaStablePoolPriceOracle is a price oracle for Balancer LP Metastable pool tokens.
 */

contract BalancerLpMetaStablePoolPriceOracle is BasePriceOracle {
    bytes32 internal constant REENTRANCY_ERROR_HASH =
        keccak256(abi.encodeWithSignature("Error(string)", "BAL#400"));

    function initialize(address _chainlinkManager) public initializer {
        __BasePriceOracle_init(_chainlinkManager);
    }

    /**
     * @notice Get the LP token price price for an underlying token address.
     * @param underlying The underlying token address for which to get the price (set to zero address for ETH).
     * @return Price denominated in ETH (scaled by 1e18).
     */

    function getPrice(address underlying) external override returns (uint256) {
        return _price(underlying);
    }

    /**
     * @dev Fetches the fair LP token/ETH price from Balancer, with 18 decimals of precision.
     * Source: https://github.com/AlphaFinanceLab/homora-v2/blob/master/contracts/oracle/BalancerPairOracle.sol
     */
    function _price(address underlying) internal virtual returns (uint256) {
        IBalancerMetaStablePool pool = IBalancerMetaStablePool(underlying);
        IBalancerVault vault = pool.getVault();

        // read-only re-entrancy protection - this call is always unsuccessful but we need to make sure
        // it didn't fail due to a re-entrancy attack
        (, bytes memory revertData) = address(vault).staticcall{gas: 50000}(
            abi.encodeWithSelector(
                vault.manageUserBalance.selector,
                new address[](0)
            )
        );
        require(
            keccak256(revertData) != REENTRANCY_ERROR_HASH,
            "Balancer vault view reentrancy"
        );

        bytes32 poolId = pool.getPoolId();
        (IERC20Upgradeable[] memory tokens, , ) = vault.getPoolTokens(poolId);

        require(tokens.length == 2, "Token length mismatch");

        uint256 px0 = baseOracle.getPrice(address(tokens[0]));
        uint256 px1 = baseOracle.getPrice(address(tokens[1]));

        IRateProvider[] memory rateProviders = pool.getRateProviders();

        px0 =
            (px0 * 1e18) /
            (
                address(rateProviders[0]) != address(0)
                    ? rateProviders[0].getRate()
                    : 1e18
            );
        px1 =
            (px1 * 1e18) /
            (
                address(rateProviders[1]) != address(0)
                    ? rateProviders[1].getRate()
                    : 1e18
            );

        return ((px0 > px1 ? px1 : px0) * pool.getRate()) / 1e18;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import {IBalancerStablePool} from "./interfaces/IBalancerStablePool.sol";
import {IBalancerVault} from "./interfaces/IBalancerVault.sol";
import {IBalancerLinearPool} from "./interfaces/IBalancerLinearPool.sol";

import "../BasePriceOracle.sol";

/**
 * @title BalancerLpStablePoolPriceOracle
 * @author Sim & Bitbaby
 * @notice BalancerLpStablePoolPriceOracle is a price oracle for Balancer LP Stable tokens.
 */
contract BalancerLpStablePoolPriceOracle is BasePriceOracle {
    bytes32 internal constant REENTRANCY_ERROR_HASH =
        keccak256(abi.encodeWithSignature("Error(string)", "BAL#400"));

    mapping(address => bool) public isBoostedToken;

    function initialize(address _chainlinkManager) public initializer {
        __BasePriceOracle_init(_chainlinkManager);
    }

    function setBoostedToken(address _token, bool _bool) external onlyOwner {
        isBoostedToken[_token] = _bool;
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
     */
    function _price(address underlying) internal virtual returns (uint256) {
        IBalancerStablePool pool = IBalancerStablePool(underlying);
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
        uint256 bptIndex = pool.getBptIndex();

        uint256 minPrice = type(uint256).max;

        for (uint256 i = 0; i < tokens.length; i++) {
            if (i == bptIndex) {
                continue;
            }

            // Get the price of each of the base tokens in ETH
            // This also includes the price of the nested LP tokens, if they are e.g. LinearPools
            // The only requirement is that the nested LP tokens have a price oracle registered
            // See BalancerLpLinearPoolPriceOracle.sol for an example, as well as the relevant tests

            uint256 marketTokenPrice = _getUsdPrice(address(tokens[i]));

            uint256 depositTokenPrice = pool.getTokenRate(address(tokens[i]));

            uint256 finalPrice = (marketTokenPrice * 1e18) / depositTokenPrice;

            if (finalPrice < minPrice) {
                minPrice = finalPrice;
            }
        }
        // Multiply the value of each of the base tokens' share in ETH by the rate of the pool
        // pool.getRate() is the rate of the pool, scaled by 1e18
        return (minPrice * pool.getRate()) / 1e18;
    }

    function _getUsdPrice(address _token) internal returns (uint256) {
        if (isBoostedToken[_token] == true) {
            return
                (baseOracle.getPrice(
                    IBalancerLinearPool(_token).getMainToken()
                ) * IBalancerLinearPool(_token).getRate()) / 1e18;
        }

        return baseOracle.getPrice(_token);
    }
}

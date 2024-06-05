// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import {IBalancerVault} from "./interfaces/IBalancerVault.sol";
import {IBalancerLinearPool} from "./interfaces/IBalancerLinearPool.sol";

import "../BasePriceOracle.sol";

/**
 * @title BalancerLpLinearPoolPriceOracle
 * @author Bitbaby
 * @notice BalancerLpLinearPoolPriceOracle is a price oracle for Balancer LP tokens.
 * @dev Implements the `PriceOracle` interface used by Midas pools (and Compound v2).
 */

contract BalancerLpLinearPoolPriceOracle is BasePriceOracle {
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
        IBalancerLinearPool pool = IBalancerLinearPool(underlying);
        IBalancerVault vault = pool.getVault();
        address mainToken = pool.getMainToken();

        // read-only re-entracy protection - this call is always unsuccessful
        (, bytes memory revertData) = address(vault).staticcall{gas: 5000}(
            abi.encodeWithSelector(
                vault.manageUserBalance.selector,
                new address[](0)
            )
        );
        require(
            keccak256(revertData) != REENTRANCY_ERROR_HASH,
            "Balancer vault view reentrancy"
        );

        // Returns the BLP Token / Main Token rate (1e18)
        uint256 rate = pool.getRate();

        uint256 baseTokenPrice = baseOracle.getPrice(mainToken);

        return (rate * baseTokenPrice) / 1e18;
    }
}

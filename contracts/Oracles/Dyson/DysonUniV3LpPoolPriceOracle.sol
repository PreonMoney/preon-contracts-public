// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {IERC20MetadataUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

import "../BasePriceOracle.sol";

import "./interfaces/IDysonUniV3Vault.sol";
import "./interfaces/IUniswapCalculator.sol";
import "./interfaces/IStrategyRebalanceStakerUniV3.sol";

/**
 * @title DysonUniV3LpPoolPriceOracle
 * @author Simsala & bitbaby
 * @notice DysonUniV3LpPoolPriceOracle is a price oracle for Dyson LP tokens.
 */
contract DysonUniV3LpPoolPriceOracle is
    BasePriceOracle,
    ReentrancyGuardUpgradeable
{
    function initialize(address _chainlinkManager) public initializer {
        __ReentrancyGuard_init();
        __BasePriceOracle_init(_chainlinkManager);
    }

    /**
     * @notice Get the LP token price price for an underlying token address.
     * @param underlying The underlying token address for which to get the price (set to zero address for ETH).
     * @return Price denominated in ETH (scaled by 1e18).
     */
    function getPrice(
        address underlying
    ) external override nonReentrant returns (uint256) {
        return _price(underlying);
    }

    function _price(address underlying) internal virtual returns (uint256) {
        IDysonUniV3Vault _dysonVault = IDysonUniV3Vault(underlying);
        IStrategyRebalanceStakerUniV3 _strategy = IStrategyRebalanceStakerUniV3(
            _dysonVault.strategy()
        );
        IERC20Upgradeable _token0 = IERC20Upgradeable(_dysonVault.token0());
        IERC20Upgradeable _token1 = IERC20Upgradeable(_dysonVault.token1());

        uint256 _amount0Held = _token0.balanceOf(address(_strategy));
        uint256 _amount1Held = _token1.balanceOf(address(_strategy));

        IUniswapCalculator _uniswapCalculator = IUniswapCalculator(
            _dysonVault.uniswapCalculator()
        );
        (uint256 _amount0, uint256 _amount1) = _getCollateralAmount(
            _dysonVault.strategy(),
            _uniswapCalculator
        );

        uint256 _token0Tvl = ((_amount0 + _amount0Held) *
            _getWantPrice(address(_token0))) /
            (10 ** IERC20MetadataUpgradeable(address(_token0)).decimals());
        uint256 _token1Tvl = ((_amount1 + _amount1Held) *
            _getWantPrice(address(_token1))) /
            (10 ** IERC20MetadataUpgradeable(address(_token1)).decimals());
        uint256 _tokenTvl = _token0Tvl + _token1Tvl;

        return _tokenTvl;
    }

    function _getCollateralAmount(
        address _strategy,
        IUniswapCalculator _uniswapCalculator
    ) internal view returns (uint256, uint256) {
        (uint256 _amount0, uint256 _amount1) = _uniswapCalculator.getLiquidity(
            _strategy
        );
        return (_amount0, _amount1);
    }

    function _getWantPrice(address want) internal returns (uint256) {
        return baseOracle.getPrice(want);
    }
}

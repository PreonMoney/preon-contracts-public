// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {IDysonLpPool} from "./interfaces/IDysonLpPool.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {IERC20MetadataUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

import "../BasePriceOracle.sol";

/**
 * @title DysonLpOracle
 * @author Bitbaby
 * @notice DysonLpOracle is a price oracle for Dyson LP tokens.
 */
contract DysonLpOracle is BasePriceOracle, ReentrancyGuardUpgradeable {
    string internal name;

    function initialize(
        string memory _name,
        address _baseOracle
    ) public initializer {
        __ReentrancyGuard_init();
        __BasePriceOracle_init(_baseOracle);
        name = _name;
    }

    function getName() public view returns (string memory) {
        return name;
    }

    /**
     * @notice Get the LP token price for an underlying token address.
     * @param underlying The underlying token address for which to get the price (set to zero address for ETH).
     * @return Price denominated in ETH (scaled by 1e18).
     */

    function getPrice(
        address underlying
    ) external override nonReentrant returns (uint256) {
        return _price(underlying);
    }

    function _price(address underlying) internal virtual returns (uint256) {
        uint256 _sharePrice = IDysonLpPool(underlying).getPricePerFullShare();

        address _want = IDysonLpPool(underlying).want();
        uint8 _decimal = IERC20MetadataUpgradeable(_want).decimals();
        uint256 _scaledSharePrice = (_sharePrice * 1e18) / (10 ** _decimal);

        return (_scaledSharePrice * _getWantPrice(_want)) / 1e18;
    }

    function _getWantPrice(address want) internal returns (uint256) {
        return baseOracle.getPrice(want);
    }
}

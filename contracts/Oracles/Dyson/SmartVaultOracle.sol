// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {ISmartVault} from "./interfaces/ISmartVault.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {IERC20MetadataUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

import "../BasePriceOracle.sol";

/**
 * @title SmartVaultOracle
 * @author Bitbaby
 * @notice SmartVaultOracle is a price oracle for SmartVault LP tokens
 */
contract SmartVaultOracle is BasePriceOracle, ReentrancyGuardUpgradeable {
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
     * @notice Get the LP token price for an underlying token address
     * @dev This is not view function to pretect from the flashloan attack
     * @param underlying The underlying token address
     * @return Price denominated in ETH (scaled by 1e18)
     */

    function getPrice(
        address underlying
    ) external override nonReentrant returns (uint256) {
        return _price(underlying);
    }

    function _price(address underlying) internal virtual returns (uint256) {
        uint256 _sharePrice = ISmartVault(underlying).getPricePerFullShare();

        address _underlying = ISmartVault(underlying).underlying();
        uint8 _decimal = IERC20MetadataUpgradeable(_underlying).decimals();
        uint256 _scaledSharePrice = (_sharePrice * 1e18) / (10 ** _decimal);

        return (_scaledSharePrice * _getWantPrice(_underlying)) / 1e18;
    }

    function _getWantPrice(address _underlying) internal returns (uint256) {
        return baseOracle.getPrice(_underlying);
    }
}

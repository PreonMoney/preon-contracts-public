// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {IERC20MetadataUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {FixedPointMathLib} from "solmate/src/utils/FixedPointMathLib.sol";

import "./interfaces/IUniV2Pair.sol";
import "../BasePriceOracle.sol";

/// @title UniV2LPOracle
/// @author Bitbaby
/// @notice Oracle used for getting the price of an UniV2Like LP token (ref https://blog.alphaventuredao.io/fair-lp-token-pricing)
contract UniV2LPOracle is BasePriceOracle, ReentrancyGuardUpgradeable {
    using FixedPointMathLib for uint256;

    uint8 public constant WAD = 18;

    function initialize(address baseOracle_) public initializer {
        __ReentrancyGuard_init();
        __BasePriceOracle_init(baseOracle_);
    }

    function getPrice(
        address lpToken
    ) external override nonReentrant returns (uint256) {
        return _price(lpToken);
    }

    function _price(address lpToken) internal virtual returns (uint256) {
        (uint256 reserve0, uint256 reserve1, ) = IUniV2Pair(lpToken)
            .getReserves();

        uint256 totalSupply = IUniV2Pair(lpToken).totalSupply();
        uint256 price0 = _getWantPrice(IUniV2Pair(lpToken).token0());
        uint256 price1 = _getWantPrice(IUniV2Pair(lpToken).token1());

        uint8 token0Decimals = IERC20MetadataUpgradeable(
            IUniV2Pair(lpToken).token0()
        ).decimals();
        uint8 token1Decimals = IERC20MetadataUpgradeable(
            IUniV2Pair(lpToken).token1()
        ).decimals();

        uint256 normalizedReserve0 = reserve0 * (10 ** (WAD - token0Decimals));
        uint256 normalizedReserve1 = reserve1 * (10 ** (WAD - token1Decimals));

        return
            FixedPointMathLib
                .sqrt(
                    normalizedReserve0
                        .mulWadDown(normalizedReserve1)
                        .mulWadDown(price0)
                        .mulWadDown(price1)
                )
                .mulDivDown(2e27, totalSupply);
    }

    function _getWantPrice(address want) internal returns (uint256) {
        return baseOracle.getPrice(want);
    }
}

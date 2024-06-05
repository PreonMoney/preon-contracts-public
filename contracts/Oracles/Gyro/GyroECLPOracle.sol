// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "../BasePriceOracle.sol";
import "./lib/BalancerLPSharePricing.sol";
import "./lib/TypeConversion.sol";
import "../../Interfaces/IBalancerVault.sol";

/**
 * @title GyroECLPOracle
 * @author Bitbaby
 * @notice GyroECLPOracle is a price oracle for GyroECLP tokens.
 */

contract GyroECLPOracle is BasePriceOracle, ReentrancyGuardUpgradeable {
    using FixedPoint for uint256;
    using TypeConversion for IECLP.DerivedParams;

    address public balancerVault;

    function initialize(
        address _vault,
        address _baseOracle
    ) public initializer {
        __ReentrancyGuard_init();
        __BasePriceOracle_init(_baseOracle);
        balancerVault = _vault;
    }

    function getInvariantDivSupply(
        IMinimalPoolView pool
    ) internal view returns (uint256) {
        uint256 invariant = pool.getLastInvariant();
        uint256 totalSupply = pool.totalSupply();
        return invariant.divDown(totalSupply);
    }

    function getPrice(
        address pool
    ) external override nonReentrant returns (uint256) {
        return _price(pool);
    }

    function _price(address pool) internal virtual returns (uint256) {
        bytes32 poolId = IMinimalPoolView(pool).getPoolId();

        (address[] memory tokens, , ) = IBalancerVault(balancerVault)
            .getPoolTokens(poolId);

        uint256[] memory prices = new uint256[](tokens.length);
        for (uint8 i; i < tokens.length; ++i) {
            prices[i] = _getWantPrice(tokens[i]);
        }

        (
            IECLP.Params memory params,
            IECLP.DerivedParams memory derivedParams
        ) = IECLP(pool).getECLPParams();

        return
            BalancerLPSharePricing.priceBptECLP(
                params,
                derivedParams.downscaleDerivedParams(),
                getInvariantDivSupply(IMinimalPoolView(pool)),
                prices
            );
    }

    function _getWantPrice(address want) internal returns (uint256) {
        return baseOracle.getPrice(want);
    }
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity 0.8.19;

import "./DataTypes.sol";
import "../interfaces/IECLP.sol";

library TypeConversion {
    function pluckPrices(
        DataTypes.PricedToken[] memory pricedTokens
    ) internal pure returns (uint256[] memory) {
        uint256[] memory prices = new uint256[](pricedTokens.length);
        for (uint256 i = 0; i < pricedTokens.length; i++) {
            prices[i] = pricedTokens[i].price;
        }
        return prices;
    }

    function downscaleVector(
        IECLP.Vector2 memory v
    ) internal pure returns (IECLP.Vector2 memory) {
        return IECLP.Vector2(v.x / 1e20, v.y / 1e20);
    }

    function downscaleDerivedParams(
        IECLP.DerivedParams memory params
    ) internal pure returns (IECLP.DerivedParams memory) {
        return
            IECLP.DerivedParams(
                downscaleVector(params.tauAlpha),
                downscaleVector(params.tauBeta),
                // the following variables are not used in the price calculation
                params.u,
                params.v,
                params.w,
                params.z,
                params.dSq
            );
    }
}

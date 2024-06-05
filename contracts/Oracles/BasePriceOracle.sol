// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./interfaces/IBasePriceOracle.sol";

abstract contract BasePriceOracle is OwnableUpgradeable, IBasePriceOracle {
    IBasePriceOracle public baseOracle;

    event BaseOracleUpdated(address oracle);

    function __BasePriceOracle_init(
        address _baseOracle
    ) internal onlyInitializing {
        __Ownable_init();

        baseOracle = IBasePriceOracle(_baseOracle);

        emit BaseOracleUpdated(_baseOracle);
    }

    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    function setBaseOracle(address _baseOracle) external onlyOwner {
        baseOracle = IBasePriceOracle(_baseOracle);

        emit BaseOracleUpdated(_baseOracle);
    }

    function getPrice(address underlying) external virtual returns (uint256);
}

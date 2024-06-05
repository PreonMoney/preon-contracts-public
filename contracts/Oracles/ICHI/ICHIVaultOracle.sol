// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {IERC20MetadataUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "../BasePriceOracle.sol";
import "./UniV3/UniV3WrappedLib.sol";
import "./interfaces/IICHIVault.sol";

/// @title Ichi Vault Oracle from Blueberry
/// @author Bitbaby
/// @notice Oracle contract provides price feeds of Ichi Vault tokens
/// @dev The logic of this oracle is using legacy & traditional mathematics of Uniswap V2 Lp Oracle.
///      Base token prices are fetched from Chainlink or Band Protocol.
///      To prevent flashloan price manipulations, it compares spot & twap prices from Uni V3 Pool.
contract IchiVaultOracle is BasePriceOracle, ReentrancyGuardUpgradeable {
    /// @dev Common denominator for percentage-based calculations.
    uint256 constant DENOMINATOR = 10000;
    /// @dev Precision factor to maintain price accuracy.
    uint256 constant PRICE_PRECISION = 1e18;
    /// @dev Maximum allowed price deviation, represented as a fraction of the DENOMINATOR.
    uint256 constant MAX_PRICE_DEVIATION = 1000; // represent 10%

    /// @dev Mapping to minimum time interval for specific time-dependent operations for each vault.
    mapping(address => uint32) public minTimeGap;
    /// @dev Mapping to maximum time interval for specific time-dependent operations for each vault.
    mapping(address => uint32) public maxTimeGap;

    /// Mapping to keep track of the maximum price deviation allowed for each token
    mapping(address => uint256) public maxPriceDeviations;

    /// @notice Thrown when the address provided is the zero address.
    error ZERO_ADDRESS();
    /// @notice Thrown when the price deviation exceeds allowed limits.
    error OUT_OF_DEVIATION_CAP(uint256 deviation);
    /// @notice Thrown when the delay time exceeds allowed limits.
    error TOO_LONG_DELAY(uint256 delayTime);
    /// @notice Thrown when the mean price is below the acceptable threshold.
    error TOO_LOW_MEAN(uint256 mean);
    /// @notice Thrown when the deviation value exceeds the threshold.
    error EXCEED_DEVIATION();

    /// @notice Event emitted when the maximum price deviation for a token is set or updated.
    /// @param token The address of the token.
    /// @param maxPriceDeviation The new maximum price deviation (in 1e18 format).
    event SetPriceDeviation(address indexed token, uint256 maxPriceDeviation);
    event SetMinTimeGap(address indexed vault, uint32 minTimeGap);
    event SetMaxTimeGap(address indexed vault, uint32 maxTimeGap);

    function initialize(address _chainlinkManager) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        __BasePriceOracle_init(_chainlinkManager);
    }

    /// @notice Set price deviations for given token
    /// @dev Input token is the underlying token of ICHI Vaults which is token0 or token1 of Uni V3 Pool
    /// @param token Token to price deviation
    /// @param maxPriceDeviation Max price deviation (in 1e18) of price feeds
    function setPriceDeviation(
        address token,
        uint256 maxPriceDeviation
    ) external onlyOwner {
        /// Validate inputs
        if (token == address(0)) revert ZERO_ADDRESS();
        if (maxPriceDeviation > MAX_PRICE_DEVIATION)
            revert OUT_OF_DEVIATION_CAP(maxPriceDeviation);

        maxPriceDeviations[token] = maxPriceDeviation;
        emit SetPriceDeviation(token, maxPriceDeviation);
    }

    /// @notice Set min token gap
    /// @param _vault Vault address
    /// @param _minTimeGap Min time gap
    function setMinTimeGap(
        address _vault,
        uint32 _minTimeGap
    ) external onlyOwner {
        minTimeGap[_vault] = _minTimeGap;

        emit SetMinTimeGap(_vault, _minTimeGap);
    }

    /// @notice Set max token gap
    /// @param _vault Vault address
    /// @param _maxTimeGap Max time gap
    function setMaxTimeGap(
        address _vault,
        uint32 _maxTimeGap
    ) external onlyOwner {
        maxTimeGap[_vault] = _maxTimeGap;

        emit SetMaxTimeGap(_vault, _maxTimeGap);
    }

    /// @notice Get token0 spot price quoted in token1
    /// @dev Returns token0 price of 1e18 amount
    /// @param vault ICHI Vault address
    /// @return price spot price of token0 quoted in token1
    function spotPrice0InToken1(
        IICHIVault vault
    ) public view returns (uint256) {
        return
            UniV3WrappedLib.getQuoteAtTick(
                vault.currentTick(), // current tick
                uint128(PRICE_PRECISION), // amountIn
                vault.token0(), // tokenIn
                vault.token1() // tokenOut
            );
    }

    /// @notice Get token0 twap price quoted in token1
    /// @dev Returns token0 price of 1e18 amount
    /// @param vault ICHI Vault address
    /// @return price spot price of token0 quoted in token1
    function twapPrice0InToken1(
        IICHIVault vault
    ) public view returns (uint256) {
        uint32 twapPeriod = vault.twapPeriod();

        if (twapPeriod > maxTimeGap[address(vault)])
            revert TOO_LONG_DELAY(twapPeriod);

        if (twapPeriod < minTimeGap[address(vault)])
            revert TOO_LOW_MEAN(twapPeriod);

        (int24 twapTick, ) = UniV3WrappedLib.consult(vault.pool(), twapPeriod);
        return
            UniV3WrappedLib.getQuoteAtTick(
                twapTick,
                uint128(PRICE_PRECISION), /// amountIn
                vault.token0(), /// tokenIn
                vault.token1() /// tokenOut
            );
    }

    /// @notice Return vault token price in USD, with 18 decimals of precision.
    /// @param token The vault token to get the price of.
    /// @return price USD price of token in 18 decimal
    function getPrice(
        address token
    ) external override nonReentrant returns (uint256) {
        IICHIVault vault = IICHIVault(token);
        uint256 totalSupply = vault.totalSupply();
        if (totalSupply == 0) return 0;

        address token0 = vault.token0();
        address token1 = vault.token1();

        /// Check price manipulations on Uni V3 pool by flashloan attack
        uint256 spotPrice = spotPrice0InToken1(vault);
        uint256 twapPrice = twapPrice0InToken1(vault);
        uint256 maxPriceDeviation = maxPriceDeviations[token0];
        if (!_isValidPrices(spotPrice, twapPrice, maxPriceDeviation))
            revert EXCEED_DEVIATION();

        /// Total reserve / total supply
        (uint256 r0, uint256 r1) = vault.getTotalAmounts();
        uint256 px0 = baseOracle.getPrice(address(token0));
        uint256 px1 = baseOracle.getPrice(address(token1));
        uint256 t0Decimal = IERC20MetadataUpgradeable(token0).decimals();
        uint256 t1Decimal = IERC20MetadataUpgradeable(token1).decimals();

        uint256 totalReserve = (r0 * px0) /
            10 ** t0Decimal +
            (r1 * px1) /
            10 ** t1Decimal;

        return (totalReserve * 10 ** vault.decimals()) / totalSupply;
    }

    /// @notice Internal function to validate deviations of 2 given prices
    /// @param price0 First price to validate, base 1e18
    /// @param price1 Second price to validate, base 1e18
    /// @param maxPriceDeviation Max price deviation of 2 prices, base 10000
    function _isValidPrices(
        uint256 price0,
        uint256 price1,
        uint256 maxPriceDeviation
    ) internal pure returns (bool) {
        uint256 maxPrice = price0 > price1 ? price0 : price1;
        uint256 minPrice = price0 > price1 ? price1 : price0;
        return
            (((maxPrice - minPrice) * DENOMINATOR) / maxPrice) <=
            maxPriceDeviation;
    }
}

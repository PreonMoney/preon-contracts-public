// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract ChainlinkManager is OwnableUpgradeable {
    struct OracleRecord {
        address aggregator;
        bool isEthIndexed;
        bool exists;
    }

    uint256 public chainlinkTimeout;

    // Asset Mappings
    mapping(address => uint16) public assetTypes;
    mapping(address => OracleRecord) public oracleRecords;

    event SetChainlinkTimeout(uint256 _chainlinkTimeout);

    event AddedAsset(address asset, address aggregator, bool isEthIndexed);
    event RemovedAsset(address asset);

    function initialize() external initializer {
        __Ownable_init();

        chainlinkTimeout = 25 hours;
    }

    /* ========== VIEWS ========== */

    /**
     * @notice Currenly only use chainlink price feed.
     * @dev Calculate the USD price of a given asset.
     * @param asset the asset address
     * @return price Returns the latest price of a given asset (decimal: 18)
     */
    function getPrice(address asset) public view returns (uint256 price) {
        OracleRecord memory record = oracleRecords[asset];

        require(record.exists, "Aggregator not found");

        try AggregatorV3Interface(record.aggregator).latestRoundData() returns (
            uint80,
            int256 _price,
            uint256,
            uint256 updatedAt,
            uint80
        ) {
            // check chainlink price updated within 25 hours
            require(
                updatedAt + (chainlinkTimeout) >= block.timestamp,
                "Chainlink price expired"
            );
            uint8 decimals = AggregatorV3Interface(record.aggregator)
                .decimals();

            if (_price > 0) {
                if (record.isEthIndexed) {
                    uint256 _scaledPrice = (uint256(_price) * 1 ether) /
                        (10 ** decimals);
                    price = _calcEthPrice(_scaledPrice);
                } else {
                    price = (uint256(_price) * 1 ether) / (10 ** decimals); // convert Chainlink decimals 8 -> 18
                }
            }
        } catch {
            revert("Price get failed");
        }

        require(price > 0, "Price not available");
    }

    function _calcEthPrice(uint256 ethAmount) internal view returns (uint256) {
        uint256 ethPrice = getPrice(address(0));

        return (ethPrice * ethAmount) / 1 ether;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /* ---------- From Owner ---------- */

    /// @dev Setting the timeout for the Chainlink price feed
    /// @param newTimeoutPeriod A new time in seconds for the timeout
    function setChainlinkTimeout(uint256 newTimeoutPeriod) external onlyOwner {
        chainlinkTimeout = newTimeoutPeriod;
        emit SetChainlinkTimeout(newTimeoutPeriod);
    }

    /// @dev Add valid asset with price aggregator
    /// @param asset Address of the asset to add
    /// @param aggregator Address of the aggregator
    function addAsset(
        address asset,
        address aggregator,
        bool isEthIndexed
    ) public onlyOwner {
        require(aggregator != address(0), "aggregator address cannot be 0");

        oracleRecords[asset] = OracleRecord({
            aggregator: aggregator,
            isEthIndexed: isEthIndexed,
            exists: true
        });

        emit AddedAsset(asset, aggregator, isEthIndexed);
    }

    /// @dev Add valid assets with price aggregator
    /// @param assets An array of assets to add
    function addAssets(
        address[] calldata assets,
        OracleRecord[] calldata records
    ) external onlyOwner {
        for (uint8 i = 0; i < assets.length; i++) {
            addAsset(assets[i], records[i].aggregator, records[i].isEthIndexed);
        }
    }

    /// @dev Remove valid asset
    /// @param asset Address of the asset to remove
    function removeAsset(address asset) external onlyOwner {
        oracleRecords[asset] = OracleRecord({
            aggregator: address(0),
            isEthIndexed: false,
            exists: false
        });

        emit RemovedAsset(asset);
    }
}

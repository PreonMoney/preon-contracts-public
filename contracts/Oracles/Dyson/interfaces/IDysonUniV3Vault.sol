// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IDysonUniV3Vault {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Initialized(uint8 version);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event Transfer(address indexed from, address indexed to, uint256 value);
    event VaultPaused(uint256 block, uint256 timestamp);

    function __UniswapVault_init(
        string memory _name,
        string memory _symbol,
        address _pool,
        address _governance,
        address _timelock,
        address _controller,
        address _iUniswapCalculator,
        address _wNative
    ) external;

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function controller() external view returns (address);

    function controllerType() external view returns (int8);

    function decimals() external view returns (uint8);

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) external returns (bool);

    function deposit(uint256 token0Amount, uint256 token1Amount) external;

    function earn() external;

    function getLowerTick() external view returns (int24);

    function getProportion() external view returns (uint256);

    function getRatio() external view returns (uint256);

    function getUpperTick() external view returns (int24);

    function governance() external view returns (address);

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) external returns (bool);

    function liquidityOfThis() external view returns (uint256);

    function name() external view returns (string memory);

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external pure returns (bytes4);

    function owner() external view returns (address);

    function paused() external view returns (bool);

    function pool() external view returns (address);

    function renounceOwnership() external;

    function setController(address _controller) external;

    function setControllerType(int8 _controlType) external;

    function setGovernance(address _governance) external;

    function setPaused(bool _paused) external;

    function setTimelock(address _timelock) external;

    function strategy() external view returns (address);

    function symbol() external view returns (string memory);

    function timelock() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function totalLiquidity() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function transferOwnership(address newOwner) external;

    function uniswapCalculator() external view returns (address);

    function univ3Router() external view returns (address);

    function wNative() external view returns (address);

    function withdraw(uint256 _shares) external;

    function withdrawAll() external;
}

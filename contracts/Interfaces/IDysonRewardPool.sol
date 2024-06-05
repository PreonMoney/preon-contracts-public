// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IDysonRewardPool {
    function stake(uint256 amount, address _address) external;

    function withdraw(uint256 amount, address _address) external;

    function getReward(address _address) external;

    function earned(address account) external view returns (uint256);

    function rewardPerToken() external view returns (uint256);

    function rewardToken() external view returns (address);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function notifyRewardAmount(uint256 reward) external;
}

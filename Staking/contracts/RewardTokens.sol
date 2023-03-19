// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract RewardTokens is ERC20 {
    constructor() ERC20("Reward Tokens", "RWT") {
        _mint(msg.sender, 100000000 * 10**18);
        // 8600000
    }

    // function mint(uint amount) public {
    //     _mint(msg.sender, amount);
    // }
}
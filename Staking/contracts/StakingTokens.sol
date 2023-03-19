// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract StakingTokens is ERC20 {
    constructor() ERC20("Staking Tokens", "SKT") {
        _mint(msg.sender, 1000000 * 10**18);
    }
}
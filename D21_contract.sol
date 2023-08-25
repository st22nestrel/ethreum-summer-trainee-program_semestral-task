// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IVoteD21.sol";

contract D21 is IVoteD21 {
    constructor () {
        _name = "HelloToken";
        _symbol = "HELLO";
        _decimals = 18;
        _mint(msg.sender, 1000 * 10 ** _decimals);
    }
}
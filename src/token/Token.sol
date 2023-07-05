// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { ERC20 } from "@openzeppelin/token/ERC20/ERC20.sol";
import { Ownable } from "@openzeppelin/access/Ownable.sol";
import { Mintable } from "../utils/Mintable.sol";

contract Token is ERC20, Ownable, Mintable {
    mapping(address => bool) private authorized;

    constructor() ERC20("Test Token", "TSTK") Ownable(_msgSender()) {}

    /**
     * @dev Transfer Tokens from A to B.
     *
     * Remove the use of allowances, the authorized contracts can allways move the tokens.
     *
     * Requirements:
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must be an authorized address.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Internal Update the balance of `from` and `to`.
     *
     * Add the authorization check.
     */
    function _update(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(authorized[_msgSender()], "transfer not allowed");

        super._update(from, to, amount);
    }

    /**
     * @dev Mint new tokens
     *
     * Requirements:
     * - `to` cannot be the zero address.
     * - the caller must be an authorized minter.
     */
    function mint(address to, uint256 amount) external onlyMinter {
        _mint(to, amount);
    }

    /**
     * @dev Add address to authorized list
     */
    function addAuthorized(address _addr) external onlyOwner {
        authorized[_addr] = true;
    }

    /**
     * @dev Remove address from authorized list
     */
    function removeAuthorized(address _addr) external onlyOwner {
        authorized[_addr] = false;
    }
}

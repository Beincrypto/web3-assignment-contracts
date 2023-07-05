// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";

/**
 * @dev Interface of the Test token.
 */
interface TestToken is IERC20 {
    /**
     * @dev Add new minter address.
     */
    function addMinter(address newMinter) external;

    /**
     * @dev Remove the address as minter.
     */
    function removeMinter(address minter) external;

    /**
     * @dev Mint `amount` tokens to `to` address.
     */
    function mint(address to, uint256 amount) external;

    /**
     * @dev Add new authorized address to manage token transfers.
     */
    function addAuthorized(address addr) external;

    /**
     * @dev Remove an authorized address to manage token transfers.
     */
    function removeAuthorized(address addr) external;
}

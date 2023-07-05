// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { Ownable } from "@openzeppelin/access/Ownable.sol";

abstract contract Mintable is Ownable {
    mapping(address => bool) internal minters;

    function addMinter(address _newMinter) public onlyOwner {
        minters[_newMinter] = true;
    }

    function removeMinter(address _minter) public onlyOwner {
        minters[_minter] = false;
    }

    modifier onlyMinter() {
        require(minters[msg.sender], "Mintable: Account cannot mint");
        _;
    }
}

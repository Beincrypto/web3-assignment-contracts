// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { console } from "@std/console.sol";
import { stdStorage, StdStorage, Test } from "@std/Test.sol";
import { IERC20Errors } from "@openzeppelin/interfaces/draft-IERC6093.sol";

import { Utils } from "./utils/Utils.sol";
import { Token } from "../src/token/Token.sol";

contract BaseSetup is Test, IERC20Errors {
    Utils internal utils;
    address payable[] internal users;

    address internal alice;
    address internal bob;

    Token internal token;

    function setUp() public virtual {
        utils = new Utils();
        users = utils.createUsers(2);

        alice = users[0];
        vm.label(alice, "Alice");
        bob = users[1];
        vm.label(bob, "Bob");

        token = new Token();
        token.addMinter(address(this));
        token.addAuthorized(address(this));
        token.addAuthorized(alice);
        token.addAuthorized(bob);
    }
}

contract WhenTransferringTokens is BaseSetup {
    uint256 internal maxTransferAmount = 12e18;

    function setUp() public virtual override {
        BaseSetup.setUp();
        console.log("When transferring tokens");
    }

    function transferToken(
        address from,
        address to,
        uint256 transferAmount
    ) public returns (bool) {
        vm.prank(from);
        return token.transfer(to, transferAmount);
    }
}

contract WhenAliceHasSufficientFunds is WhenTransferringTokens {
    using stdStorage for StdStorage;
    uint256 internal mintAmount = maxTransferAmount;

    function setUp() public override {
        WhenTransferringTokens.setUp();
        console.log("When Alice has sufficient funds");
        token.mint(alice, mintAmount);
    }

    function itTransfersAmountCorrectly(
        address from,
        address to,
        uint256 transferAmount
    ) public {
        uint256 fromBalanceBefore = token.balanceOf(from);
        bool success = transferToken(from, to, transferAmount);

        assertTrue(success);
        assertEqDecimal(
            token.balanceOf(from),
            fromBalanceBefore - transferAmount,
            token.decimals()
        );
        assertEqDecimal(token.balanceOf(to), transferAmount, token.decimals());
    }

    function testTransferAllTokens() public {
        itTransfersAmountCorrectly(alice, bob, maxTransferAmount);
    }

    function testTransferHalfTokens() public {
        itTransfersAmountCorrectly(alice, bob, maxTransferAmount / 2);
    }

    function testTransferOneToken() public {
        itTransfersAmountCorrectly(alice, bob, 1);
    }

    function testTransferWithFuzzing(uint64 transferAmount) public {
        vm.assume(transferAmount != 0);
        itTransfersAmountCorrectly(
            alice,
            bob,
            transferAmount % maxTransferAmount
        );
    }

    function testTransferWithMockedCall() public {
        vm.prank(alice);
        vm.mockCall(
            address(token),
            abi.encodeWithSelector(
                token.transfer.selector,
                bob,
                maxTransferAmount
            ),
            abi.encode(false)
        );
        bool success = token.transfer(bob, maxTransferAmount);
        assertTrue(!success);
        vm.clearMockedCalls();
    }

    // example how to use https://github.com/foundry-rs/forge-std stdStorage
    function testFindMapping() public {
        uint256 slot = stdstore
            .target(address(token))
            .sig(token.balanceOf.selector)
            .with_key(alice)
            .find();
        bytes32 data = vm.load(address(token), bytes32(slot));
        assertEqDecimal(uint256(data), mintAmount, token.decimals());
    }
}

contract WhenAliceHasInsufficientFunds is WhenTransferringTokens {
    uint256 internal mintAmount = maxTransferAmount - 1e18;

    function setUp() public override {
        WhenTransferringTokens.setUp();
        console.log("When Alice has insufficient funds");
        token.mint(alice, mintAmount);
    }

    function itRevertsTransfer(
        address from,
        address to,
        uint256 transferAmount,
        bytes memory expectedRevertData
    ) public {
        vm.expectRevert(expectedRevertData);
        transferToken(from, to, transferAmount);
    }

    function testCannotTransferMoreThanAvailable() public {
        itRevertsTransfer({
            from: alice,
            to: bob,
            transferAmount: maxTransferAmount,
            expectedRevertData: abi.encodeWithSelector(ERC20InsufficientBalance.selector, alice, mintAmount, maxTransferAmount)
        });
    }

    function testCannotTransferToZero() public {
        itRevertsTransfer({
            from: alice,
            to: address(0),
            transferAmount: mintAmount,
            expectedRevertData: abi.encodeWithSelector(ERC20InvalidReceiver.selector, address(0))
        });
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { console } from "@std/console.sol";
import { stdStorage, StdStorage, Test } from "@std/Test.sol";
import { IERC20Errors } from "@openzeppelin/interfaces/draft-IERC6093.sol";

import { Utils } from "./utils/Utils.sol";
import { Token } from "../src/token/Token.sol";
import { Presale } from "../src/presale/Presale.sol";

contract BaseSetup is Test, IERC20Errors {
    Utils internal utils;
    address payable[] internal users;

    address internal alice;
    address internal bob;

    Token internal token;
    Presale internal presale;

    function setUp() public virtual {
        utils = new Utils();
        users = utils.createUsers(2);

        alice = users[0];
        vm.label(alice, "Alice");
        bob = users[1];
        vm.label(bob, "Bob");

        token = new Token();
        presale = new Presale(address(token));
        token.addMinter(address(presale));
        token.addAuthorized(address(presale));
    }
}

contract WhenSellingTokens is BaseSetup {
    uint256 internal maxSellAmount = 10000e18;

    function setUp() public virtual override {
        BaseSetup.setUp();
        console.log("When selling tokens");
    }

    function sellTokens(
        address from,
        uint256 amount,
        uint256 payment
    ) public returns (bool) {
        vm.prank(from);
        return presale.tokenSale{value: payment}(amount);
    }
}

contract WhenPresaleHasNotStarted is WhenSellingTokens {

    function setUp() public override {
        WhenSellingTokens.setUp();
        console.log("When presale has not started");
        vm.roll(100);
    }

    function itRevertsSell(
        address from,
        uint256 amount,
        uint256 payment,
        string memory expectedRevertMsg
    ) public {
        vm.expectRevert(abi.encodePacked(expectedRevertMsg));
        sellTokens(from, amount, payment);
    }

    function testCannotBuyIfPresaleNotStarted() public {
        itRevertsSell({
            from: alice,
            amount: maxSellAmount,
            payment: 0 ether,
            expectedRevertMsg: "presale not open yet"
        });
    }
}

contract WhenFirstStagePresale is WhenSellingTokens {

    function setUp() public override {
        WhenSellingTokens.setUp();
        console.log("When presale has not started");
        vm.roll(100);
        presale.startSale(0);
        vm.roll(150);
    }

    function itRevertsSell(
        address from,
        uint256 amount,
        uint256 payment,
        string memory expectedRevertMsg
    ) public {
        vm.expectRevert(abi.encodePacked(expectedRevertMsg));
        sellTokens(from, amount, payment);
    }

    function itCompletesSellCorrectly(
        address from,
        uint256 amount
    ) public {
        uint256 fromEthBalanceBefore = address(from).balance;
        uint256 fromTokenBalanceBefore = token.balanceOf(from);
        // 1 token = 0.0001 ether on first stage
        uint256 payment = amount * 0.0001 ether / 1e18;

        bool success = sellTokens(from, amount, payment);

        assertTrue(success);
        assertEq(fromEthBalanceBefore - payment, address(from).balance);
        assertEqDecimal(
            token.balanceOf(from),
            fromTokenBalanceBefore + amount,
            token.decimals()
        );
    }

    function testSellHalfAmount() public {
        itCompletesSellCorrectly({
            from: alice,
            amount: maxSellAmount / 2
        });
        assertEq(presale.currentStageAvailableAmount(), presale.currentStageMaxAmount() - maxSellAmount / 2);
    }

    function testSellMaxAmount() public {
        itCompletesSellCorrectly({
            from: alice,
            amount: maxSellAmount
        });
        assertEq(presale.currentStageAvailableAmount(), presale.currentStageMaxAmount() - maxSellAmount);
    }

    function testSellInvalidPayment() public {
        itRevertsSell({
            from: alice,
            amount: maxSellAmount,
            payment: 0 ether,
            expectedRevertMsg: "invalid sent amount"
        });
    }

    function testSellMoreThanMaxAmount() public {
        itRevertsSell({
            from: alice,
            amount: maxSellAmount + 1,
            payment: 0 ether,
            expectedRevertMsg: "max stage wallet qty"
        });
    }
}
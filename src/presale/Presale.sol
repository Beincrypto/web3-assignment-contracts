// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { Ownable } from "@openzeppelin/access/Ownable.sol";
import { Pausable } from "@openzeppelin/security/Pausable.sol";
import { ReentrancyGuard } from "@openzeppelin/security/ReentrancyGuard.sol";
import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/token/ERC20/utils/SafeERC20.sol";
import { TestToken } from "../interfaces/TestToken.sol";

contract Presale is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // for each address, the amount of tokens bought in each stage
    mapping(address => mapping(uint128 => uint128)) private _stageBalances;
    mapping(uint128 => uint128) private _stageSales;

    uint64 public constant STAGE_BLOCKS_DURATION = 43200;
    uint64 public constant STAGE_PRICE_INCREMENT = 10000000000000;
    uint128 public constant UNIT_PRICE = 100000000000000;
    uint128 public constant STAGE_MAX_TOKENS = 1000000000000000000000000;
    uint128 public constant STAGE_MAX_WALLET_BUY = 10000000000000000000000;

    uint128 public saleStage = 0;
    uint128 public blockStart = 0;

    address public saleToken;

    event Sale(
        address indexed user,
        uint256 stage,
        uint256 qty,
        uint256 amount
    );

    /**
     * @dev Presale constructor
     *   _saleToken: addres of Test Token
     */
    constructor(
        address _saleToken
    ) Ownable(_msgSender()) {
        require(_saleToken != address(0), "!sale token");

        saleToken = _saleToken;
    }

    /**
     * @dev Start Sale
     * Starts the sale by setting the start block number and stage to 1 (stage 0 is not used)
     */
    function startSale(uint256 start) external onlyOwner {
        require(blockStart == 0, "sale already started");
        if (start == 0) {
            blockStart = uint128(block.number);
            saleStage = 1;
        } else {
            require(start > block.number, "invalid start block");
            blockStart = uint128(start);
        }
    }

    /**
     * @dev Current Stage
     * Calculates the current effective stage.
     */
    function currentStage() public view returns (uint128) {
        if (blockStart == 0) {
            // sale not started
            return 0;
        }
        if (block.number < blockStart) {
            // sale not started
            return 0;
        }
        uint256 blocksPassed = block.number - blockStart;
        return uint128(blocksPassed / STAGE_BLOCKS_DURATION + 1);
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     * - The contract must not be paused.
     */
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     * - The contract must be paused.
     */
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    /**
     * @dev Modifier checkStage
     * This modifier checks if the stage should be advanced by block number
     */
    modifier checkStage() {
        uint128 current = currentStage();
        if (current > saleStage) {
            saleStage = current;
        }
        _;
    }

    /**
     * @dev Token sale
     */
    function tokenSale(uint256 _qty) external payable whenNotPaused checkStage nonReentrant {
        uint128 current = currentStage();

        require(current > 0, "presale not open yet");
        require(_qty > 0, "zero qty");
        require(_stageSales[current] + _qty <= STAGE_MAX_TOKENS, "max stage qty");
        require(_stageBalances[_msgSender()][current] + _qty <= STAGE_MAX_WALLET_BUY, "max stage wallet qty");

        // calculate MATIC amount to pay
        uint256 amount = (UNIT_PRICE + (STAGE_PRICE_INCREMENT * (current - 1))) * _qty;
        require(amount == msg.value, "invalid sent amount");

        // update state
        _stageSales[current] += uint128(_qty);
        _stageBalances[_msgSender()][current] += uint128(_qty);

        // send tokens
        TestToken(saleToken).mint(_msgSender(), _qty);
        emit Sale(_msgSender(), current, _qty, amount);
    }
}

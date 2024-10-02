// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ERC20PermitUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {IIndexToken} from "./interfaces/IIndexToken.sol";
import {IERC20} from "../src/interfaces/IERC20.sol";

/**
 * @title IndexToken Contract
 * @dev ERC20 token representing an Index token.
 */
contract IndexToken is
    Initializable,
    ERC20Upgradeable,
    OwnableUpgradeable,
    ERC20PermitUpgradeable,
    IIndexToken
{
    AggregatorV3Interface private constant ETH_PRICE_FEED =
        AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
    AggregatorV3Interface private constant BTC_PRICE_FEED =
        AggregatorV3Interface(0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c);
    AggregatorV3Interface private constant USDC_PRICE_FEED =
        AggregatorV3Interface(0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6);

    IERC20 private constant USDC =
        IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20 private constant BTC =
        IERC20(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);

    uint256 constant VAULT_VALUE_DECIMAL = 8;

    uint256 private immutable ETH_PRICE_DEVISOR;
    uint256 private immutable BTC_PRICE_DEVISOR;
    uint256 private immutable USDC_PRICE_DEVISOR;

    error InsufficientBalance();

    /**
     * @dev Emitted when a user deposits tokens into the contract.
     * @param user The address of the user who deposited the tokens.
     * @param token The address of the token deposited.
     * @param amount The amount of tokens deposited.
     */
    event Deposit(address indexed user, address indexed token, uint256 amount);

    /**
     * @dev Emitted when a user withdraws tokens from the contract.
     * @param user The address of the user who withdrew the tokens.
     * @param indexAmount The amount of Index tokens withdrawn.
     * @param ethAmount The amount of ETH withdrawn.
     * @param usdcAmount The amount of USDC withdrawn.
     * @param btcAmount The amount of BTC withdrawn.
     */
    event Withdraw(
        address indexed user,
        uint256 indexAmount,
        uint256 ethAmount,
        uint256 usdcAmount,
        uint256 btcAmount
    );

    event AdminDepositedBTC(uint256 amount);
    event AdminDepositedUSDC(uint256 amount);
    event AdminDepositedETH(uint256 amount);

    constructor() {
        ETH_PRICE_DEVISOR = 10 ** (ETH_PRICE_FEED.decimals() + 18 - 8);
        BTC_PRICE_DEVISOR = 10 ** (BTC_PRICE_FEED.decimals() + BTC.decimals() - 8);
        USDC_PRICE_DEVISOR = 10 ** (USDC_PRICE_FEED.decimals() + USDC.decimals() - 8);
        _disableInitializers();
    }

    /**
     * @dev Initializes the contract.
     * @param initialOwner The address of the initial owner of the contract.
     */
    function initialize(address initialOwner) public payable initializer {
        require(msg.value > 0, "IndexToken: ETH deposit required");
        __ERC20_init("Index", "IND");
        __Ownable_init(initialOwner);
        __ERC20Permit_init("Index");

        // Mint Index tokens to the initial owner
        _mint(initialOwner, msg.value);
    }

    /**
     * @dev Deposits ETH into the contract.
     * Emits a `Deposit` event with the sender's address, zero address for ETH, and the amount of ETH deposited.
     */
    function depositETH() external payable {
        (
            uint256 ethUsdPrice,
            ,
            ,
            uint256 vaultUsdcValue
        ) = getPricesAndVaultValue();

        //                msg.value             ethUsdPrice              10**VAULT_VALUE_DECIMAL
        // indexAmount = ----------- x ------------------------------ x ------------------------- x totalSupply()
        //                  10**18      10**ETH_PRICE_FEED.decimals()         vaultUsdcValue
        uint256 indexAmount = 
            (msg.value * ethUsdPrice * totalSupply()) /
            (vaultUsdcValue * 10**(18 + ETH_PRICE_FEED.decimals() - VAULT_VALUE_DECIMAL));
        
        _mint(msg.sender, indexAmount);
        emit Deposit(msg.sender, address(0), msg.value);
    }

    /**
     * @dev Deposits USDC into the contract.
     * Requires the sender to have approved the contract to spend the USDC amount being deposited.
     * @param _amount The amount of USDC to deposit.
     */
    function depositUSDC(uint256 _amount) external {
        (
            ,
            uint256 usdcUsdPrice,
            ,
            uint256 vaultUsdcValue
        ) = getPricesAndVaultValue();

        //                    _amount                      usdcUsdPrice           10**VAULT_VALUE_DECIMAL
        // indexAmount = --------------------- x ------------------------------ x ------------------------ x totalSupply()
        //                10**USDC.decimals()     10**USDC_PRICE_FEED.decimals()       vaultUsdcValue
        uint256 indexAmount = (_amount * usdcUsdPrice * totalSupply()) /
            (vaultUsdcValue * 10**(USDC.decimals() + USDC_PRICE_FEED.decimals() - VAULT_VALUE_DECIMAL));

        USDC.transferFrom(msg.sender, address(this), _amount);
        _mint(msg.sender, indexAmount);
        emit Deposit(msg.sender, address(USDC), _amount);
    }

    /**
     * @dev Deposits BTC into the contract.
     * Requires the sender to have approved the contract to spend the BTC amount being deposited.
     * @param _amount The amount of BTC to deposit.
     */
    function depositBTC(uint256 _amount) external {
        (
            ,
            ,
            uint256 btcUsdPrice,
            uint256 vaultUsdcValue
        ) = getPricesAndVaultValue();

        //                    msg.value                 btcUsdPrice              10**VAULT_VALUE_DECIMAL
        // indexAmount = ------------------- x ------------------------------ x ------------------------- x totalSupply()
        //                10**BTC.decimals()    10**BTC_PRICE_FEED.decimals()         vaultUsdcValue
        uint256 indexAmount = (_amount * btcUsdPrice * totalSupply()) /
            (vaultUsdcValue * 10**(BTC.decimals() + BTC_PRICE_FEED.decimals() - VAULT_VALUE_DECIMAL));

        BTC.transferFrom(msg.sender, address(this), _amount);
        _mint(msg.sender, indexAmount);
        emit Deposit(msg.sender, address(BTC), _amount);
    }

    /**
     * @dev Withdraws an amount of Index tokens and burns them.
     * The caller receives a proportionate amount of the underlying assets.
     * @param indexAmount The amount of Index tokens to withdraw.
     */
    function withdraw(uint256 indexAmount) external {
        if (balanceOf(msg.sender) < indexAmount) {
            revert InsufficientBalance();
        }

        uint256 supply = totalSupply();

        _burn(msg.sender, indexAmount);

        uint256 ethAmount = (indexAmount * address(this).balance) / supply;
        uint256 usdcAmount = (indexAmount * USDC.balanceOf(address(this))) /
            supply;
        uint256 btcAmount = (indexAmount * BTC.balanceOf(address(this))) /
            supply;

        payable(msg.sender).transfer(ethAmount);
        USDC.transfer(msg.sender, usdcAmount);
        BTC.transfer(msg.sender, btcAmount);

        emit Withdraw(msg.sender, indexAmount, ethAmount, usdcAmount, btcAmount);
    }

    function getETHPrice() private view returns (uint256) {
        (, int price, , , ) = ETH_PRICE_FEED.latestRoundData();
        return uint256(price);
    }

    function getUSDCPrice() private view returns (uint256) {
        (, int price, , , ) = USDC_PRICE_FEED.latestRoundData();
        return uint256(price);
    }

    function getBTCPrice() private view returns (uint256) {
        (, int price, , , ) = BTC_PRICE_FEED.latestRoundData();
        return uint256(price);
    }

    /**
     * @dev Returns the prices of ETH, USDC, and BTC, and the total value of the vault in USDC.
     * @return ethPrice The price of ETH in USD.
     * @return usdcPrice The price of USDC in USD.
     * @return btcPrice The price of BTC in USD.
     * @return vaultUsdcValue The total value of the vault in USD.
     */
    function getPricesAndVaultValue()
        private
        view
        returns (
            uint256 ethPrice,
            uint256 usdcPrice,
            uint256 btcPrice,
            uint256 vaultUsdcValue
        )
    {
        ethPrice = getETHPrice();
        usdcPrice = getUSDCPrice();
        btcPrice = getBTCPrice();

        address vault = address(this);

        // vault total asset sum in USD with 8 decimals;
        vaultUsdcValue =
            (((vault.balance - msg.value) * ethPrice) / ETH_PRICE_DEVISOR) +
            ((USDC.balanceOf(vault) * usdcPrice) / USDC_PRICE_DEVISOR) +
            ((BTC.balanceOf(vault) * btcPrice) / BTC_PRICE_DEVISOR);
    }

    function adminDepositBTC(uint256 _amount) external onlyOwner {
        BTC.transferFrom(msg.sender, address(this), _amount);
        emit AdminDepositedBTC(_amount);
    }

    function adminDepositUSDC(uint256 _amount) external onlyOwner {
        USDC.transferFrom(msg.sender, address(this), _amount);
        emit AdminDepositedUSDC(_amount);
    }

    function adminDepositETH() external payable onlyOwner {
        emit AdminDepositedETH(msg.value);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import { ERC20Upgradeable, IERC20 } from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { ERC20PermitUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract IndexToken is Initializable, ERC20Upgradeable, OwnableUpgradeable, ERC20PermitUpgradeable {
    AggregatorV3Interface constant private ETH_PRICE_FEED = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
    AggregatorV3Interface constant private BTC_PRICE_FEED = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
    AggregatorV3Interface constant private USDC_PRICE_FEED = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);

    IERC20 constant private USDC = IERC20(0x9326BFA02ADD2366b30bacB125260Af641031331);
    IERC20 constant private BTC = IERC20(0x9326BFA02ADD2366b30bacB125260Af641031331);

    error InsufficientBalance();

    constructor() {
        _disableInitializers();
    }

    function initialize(address initialOwner)  public initializer{
        __ERC20_init("Index", "IND");
        __Ownable_init(initialOwner);
        __ERC20Permit_init("Index");
    }

    function depositETH() public payable {
        (uint256 ethUsdPrice, , ,uint256 vaultUsdcValue) = getPricesAndVaultValue();
        uint256 usdValue = msg.value * ethUsdPrice;
        uint256 indexAmount = usdValue * totalSupply() / (vaultUsdcValue * ETH_PRICE_FEED.decimals());
        _mint(msg.sender, indexAmount);
    }

    function depositUSDC(uint256 _amount) public {
        USDC.transferFrom(msg.sender, address(this), _amount);

        (, uint256 usdcUsdPrice, ,uint256 vaultUsdcValue) = getPricesAndVaultValue();
        uint256 usdValue = _amount * usdcUsdPrice;
        uint256 indexAmount = usdValue * totalSupply() / (vaultUsdcValue * USDC_PRICE_FEED.decimals());
        _mint(msg.sender, indexAmount);
    }

    function depositBTC(uint256 _amount) public {
        BTC.transferFrom(msg.sender, address(this), _amount);

        (, , uint256 btcUsdPrice,uint256 vaultUsdcValue) = getPricesAndVaultValue();
        uint256 usdValue = _amount * btcUsdPrice;
        uint256 indexAmount = usdValue * totalSupply() / (vaultUsdcValue * USDC_PRICE_FEED.decimals());
        _mint(msg.sender, indexAmount);
    }

    function withdraw(uint256 amount) public {
        if (balanceOf(msg.sender) < amount) {
            revert InsufficientBalance();
        }
        _burn(msg.sender, amount);

        uint256 ethAmount = amount * address(this).balance / totalSupply();
        payable(msg.sender).transfer(ethAmount);
    }

    receive() external payable {
        depositETH();
    }

    function getETHPrice() public view returns (uint256) {
        (, int price, , ,) = ETH_PRICE_FEED.latestRoundData();
        return uint256(price);
    }

    function getBTCPrice() public view returns (uint256) {
        (, int price, , ,) = BTC_PRICE_FEED.latestRoundData();
        return uint256(price);
    }

    function getUSDCPrice() public view returns (uint256) {
        (, int price, , ,) = USDC_PRICE_FEED.latestRoundData();
        return uint256(price);
    }

    function getVaultBalance() public view returns (uint256) {
        address vault = address(this);
        return vault.balance * getETHPrice() / ETH_PRICE_FEED.decimals() + USDC.balanceOf(vault) * getUSDCPrice() / USDC_PRICE_FEED.decimals() + BTC.balanceOf(vault) * getBTCPrice() / BTC_PRICE_FEED.decimals();
    }

    function getPricesAndVaultValue() public view returns (uint256 ethPrice, uint256 usdcPrice, uint256 btcPrice, uint256 vaultUsdcValue) {
        ethPrice = getETHPrice();
        usdcPrice = getUSDCPrice();
        btcPrice = getBTCPrice();

        address vault = address(this);
        vaultUsdcValue = vault.balance * getETHPrice() / ETH_PRICE_FEED.decimals() + USDC.balanceOf(vault) * getUSDCPrice() / USDC_PRICE_FEED.decimals() + BTC.balanceOf(vault) * getBTCPrice() / BTC_PRICE_FEED.decimals();
    }
}

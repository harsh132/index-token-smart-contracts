// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {IndexToken} from "../src/IndexToken.sol";
import {IERC20} from "../src/interfaces/IERC20.sol";


contract IndexTokenTest is Test {
    ProxyAdmin admin;
    IndexToken implementationV1;
    TransparentUpgradeableProxy proxy;
    IndexToken index;

    address public owner;
    address public alice;

    IERC20 private constant USDC =
        IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20 private constant BTC =
        IERC20(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);

    address BTC_WHALE = 0x971e5b5D4baa5607863f3748FeBf287C7bf82618;
    address USDC_WHALE = 0x37305B1cD40574E4C5Ce33f8e8306Be057fD7341;

    function setUp() public {
        owner = vm.addr(1);
        alice = vm.addr(2);

        admin = new ProxyAdmin(address(owner));

        implementationV1 = new IndexToken();
        proxy = new TransparentUpgradeableProxy(address(implementationV1),address(admin),"");
        index = IndexToken(address(proxy));

        index.initialize{value: 0.01 ether}(owner);
        console.log("setup: index supply:", index.totalSupply());
        console.log("setup: owner's index balance:", index.balanceOf(owner));
    }

    function test_Initialize() public view {
        assertEq(index.owner(), owner, "owner mismatch");
        assertEq(address(index).balance, 0.01 ether,"eth balance of index contract");
        assertEq(index.totalSupply(), 0.01 ether, "Total supply of Index ERC20 token");
        assertEq(index.balanceOf(owner), 0.01 ether, "Checking ERC20 Balance of owner");
    }

    function userDeposits() public {
        vm.startPrank(alice);
        vm.deal(alice, 1e16);
        index.depositETH{value: 1e16}();
        assertEq(address(index).balance, 2e16, "Unexpected IndexToken's Eth balance");
        console.log("Alice Index balnce:", index.balanceOf(alice));

        vm.startPrank(USDC_WHALE);
        USDC.approve(address(index), 1e7);
        index.depositUSDC(1e7);
        assertEq(USDC.balanceOf(address(index)), 1e7);
        console.log("Alice Index balnce:", index.balanceOf(alice));
        console.log("USDC_WHALE Index balnce:", index.balanceOf(USDC_WHALE));



        vm.startPrank(BTC_WHALE);
        BTC.approve(address(index), 1e5);
        index.depositBTC(1e5);
        assertEq(BTC.balanceOf(address(index)), 1e5);
        console.log("Alice Index balnce:", index.balanceOf(alice));
        console.log("USDC_WHALE Index balnce:", index.balanceOf(USDC_WHALE));
        console.log("BTC_WHALE Index balnce:", index.balanceOf(BTC_WHALE));
    }

    function test_UserWithdraw() public {
        userDeposits();

        vm.startPrank(alice);
        uint initialEthBal = alice.balance;
        uint indexBal = index.balanceOf(alice);
        console.log("Alice's balances:", initialEthBal, indexBal);
        console.log("index token supply:", index.totalSupply());
        console.log("index contract balnces:", address(index).balance, USDC.balanceOf(address(index)), BTC.balanceOf(address(index)));
        index.withdraw(indexBal);
        assertEq(index.balanceOf(alice), 0, "Alice's index balance should be 0");
        assertGt(alice.balance, 0, "Alice's eth balance should be greater than 0");
        assertGt(USDC.balanceOf(alice), 0, "Alice's USDC balance should be greater than 0");
        assertGt(BTC.balanceOf(alice), 0, "Alice's BTC balance should be greater than 0");
    }



    // function testFuzz_SetNumber(uint256 x) public {
    //     counter.setNumber(x);
    //     assertEq(counter.number(), x);
    // }
    // 10000000000000000
    // 5000000000000000
}
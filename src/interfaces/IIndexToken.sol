// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IIndexToken Interface
 * @dev Interface for the IndexToken contract.
 */
interface IIndexToken {
    /**
     * @dev Deposits ETH into the contract.
     * Emits a `Deposit` event with the sender's address, zero address for ETH, and the amount of ETH deposited.
     */
    function depositETH() external payable;

    /**
     * @dev Deposits USDC into the contract.
     * Requires the sender to have approved the contract to spend the USDC amount being deposited.
     * @param _amount The amount of USDC to deposit.
     */
    function depositUSDC(uint256 _amount) external;

    /**
     * @dev Deposits BTC into the contract.
     * Requires the sender to have approved the contract to spend the BTC amount being deposited.
     * @param _amount The amount of BTC to deposit.
     */
    function depositBTC(uint256 _amount) external;

    /**
     * @dev Withdraws an amount of Index tokens and burns them.
     * The caller receives a proportionate amount of the underlying assets.
     * @param indexAmount The amount of Index tokens to withdraw.
     */
    function withdraw(uint256 indexAmount) external;

    /**
     * @dev Allows an admin to deposit BTC into the contract.
     * This function is likely to be called by a backend service or a multisig wallet.
     * @param _amount The amount of BTC to deposit.
     */
    function adminDepositBTC(uint256 _amount) external;

    /**
     * @dev Allows an admin to deposit USDC into the contract.
     * This function is intended for administrative purposes.
     * @param _amount The amount of USDC to deposit.
     */
    function adminDepositUSDC(uint256 _amount) external;

    /**
     * @dev Allows an admin to deposit ETH into the contract.
     * This function is intended for administrative purposes.
     */
    function adminDepositETH() external payable;
}

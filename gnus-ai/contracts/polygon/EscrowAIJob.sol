// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/utils/escrow/ConditionalEscrow.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract EscrowAIJob is ConditionalEscrow {
    PaymentSplitter _payees;
    uint256 private escrowAmount;

    // reserve some space for future upgrades
    uint256 private _reserved1;
    uint256 private _reserved2;
    uint256 private _reserved3;

    string private _reserved4;
    string private _reserved5;
    string private _reserved6;

    constructor(uint256 amount) {
        // save total escrowAmount for later
        escrowAmount = amount;
    }

    function withdrawalAllowed(address payee) public view virtual override returns (bool) {
        // TODO: zkSnark check based on some random seed and macro job index and hashes.
        //require(_payees.)
        // logic here for allowing withdrawals to a payee
    }

    function _addPayees(address[] memory payees) internal {
    }

}

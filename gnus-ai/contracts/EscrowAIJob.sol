// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/escrow/ConditionalEscrow.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract EscrowAIJob is ConditionalEscrow {
    PaymentSplitter _payees;

    constructor() public {
    }

    function withdrawalAllowed(address payee) public view virtual returns (bool) {
        // logic here for allowing withdrawals to all payees
    };

    function setPayees() public {}

}

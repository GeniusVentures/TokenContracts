// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/escrow/ConditionalEscrow.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract EscrowAIJob is ConditionalEscrow {
    PaymentSplitter _payees;
    uint256 private escrowAmount;
    bytes32 public constant VERIFIER_ROLE = keccak256("VERIFIER_ROLE");

    constructor(uint256 amount) public {
        // save total escrowAmount for later
        escrowAmount = amount;
    }

    modifier onlyVerifier()
    {
        require(hasRole(VERIFIER_ROLE, msg.sender), "Restricted to verifiers.");
        _;
    }

    function withdrawalAllowed(address payee) public view virtual returns (bool) {
        require(_payees.)
        // logic here for allowing withdrawals to a payee
    }

    function addPayees(address payees[]) public external {
    }

}

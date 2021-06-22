// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "EscrowAIJob.sol";


contract GeniusAI is AccessControl {

  struct AIProcessingJob {
    EscrowAIJob escrow;
    byte32 cid;   // ipfs cid minus first 2 bytes (Qm)
  };

  mapping(address => uint) public numEscrows;
  mapping(address => mapping(uint => AIProces+singJob));

  constructor() public {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

  modifier onlyAdmin(
  {
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Restricted to admins.");
    _;
  }

  function OpenEscrow(uint256 amount, byte32 cid) {

  }
}

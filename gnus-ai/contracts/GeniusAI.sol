// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "EscrowAIJob.sol";


contract GeniusAI is AccessControl {

  struct AIProcessingJob {
    EscrowAIJob escrow;
    byte32 cid;   // ipfs cid minus first 2 bytes (Qm)
    byte32 verifierIDsHash; // up to 32 verifier IDS hashed
  };

  mapping(address => uint256) public numEscrows;
  /// AIProcessingJob[address][numEscrows]
  mapping(address => mapping(uint256 => AIProcessingJob)) aiProcessingJobs;

  constructor() public {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

  modifier onlyAdmin(
  {
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Restricted to admins.");
    _;
  }

  /// OpenEscrow
  /// msg.value = amount un WEI to deposit in escrow
  /// cid - ipfs CID minus the starting Qm prefix so it fits into 32 bytes
  /// verifierIDS - verfier ids hash built in dapp
  function OpenEscrow(byte32 cid, byte32 verifierIDsHash) public payable {
    uint256 escrowID = numEscrows[msg.sender];
    escrowID += 1;
    AIProcessingJob aiJob = new AIProcessingJob();
    aiJob.escrow = new EscrowAIJob(msg.value);
    aiJob.cid = cid;
    aiJob.verifierIDsHash = verifierIDsHash;
    AIProcessingJob[msg.sender][escrowID] = aiJob;
  }

  function
}

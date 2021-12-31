// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./EscrowAIJob.sol";
import "./PolyGNUSToken.sol";

contract GeniusAI is Initializable, UUPSUpgradeable, PolyGNUSToken {

  // section for GNUSAI contract, version 1.0
  struct AIProcessingJob {
    uint256 escrowID;
    bytes32 uuid;   // ipfs cid minus first 2 bytes (Qm)
    EscrowAIJob escrow;
  }

  mapping(address => uint256) public numEscrows;
  // AIProcessingJob[address][numEscrows]
  mapping(address => mapping(uint256 => AIProcessingJob)) AIProcessingJobs;

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() initializer {}

  function initialize() initializer public {
    __AccessControl_init();

    // need to grant roles before init of UUPS ERC1967Proxy
    address creator = _msgSender();

    _grantRole(DEFAULT_ADMIN_ROLE, creator);
    _grantRole(URI_SETTER_ROLE, creator);
    _grantRole(PAUSER_ROLE, creator);
    _grantRole(MINTER_ROLE, creator);
    _grantRole(UPGRADER_ROLE, creator);
    _grantRole(PROXY_ROLE, creator);

    __UUPSUpgradeable_init();

    __PolyGNUSToken_init();


  }

  function addMinter(address minter) external virtual onlyRole(DEFAULT_ADMIN_ROLE) {

    grantRole(MINTER_ROLE, minter);
  }

  function removeMinter(address account) external virtual onlyRole(DEFAULT_ADMIN_ROLE) {

    revokeRole(MINTER_ROLE, account);
  }

  function renounceRole(bytes32 role, address account) public virtual override(AccessControlUpgradeable) {

    require(!(hasRole(DEFAULT_ADMIN_ROLE, account) && (superAdmin == account)), "Cannot renounce superAdmin from Admin Role");
    super.renounceRole(role, account);
  }

  function revokeRole(bytes32 role, address account) public virtual override(AccessControlUpgradeable)
    onlyRole(DEFAULT_ADMIN_ROLE) {

    require(!(hasRole(DEFAULT_ADMIN_ROLE, account) && (superAdmin == account)), "Cannot revoke superAdmin from Admin Role");
    super.revokeRole(role, account);
  }

  function _authorizeUpgrade(address newImplementation) internal onlyRole(UPGRADER_ROLE) override(UUPSUpgradeable) {
  }

  /// OpenEscrow
  /// msg.value = amount OF GNUS to deposit in escrow
  /// UUID - 128 bit/32 byte UUID (no dashes) of unique ID for Job structure in database
  function OpenEscrow(bytes32 UUID) public payable {
    uint256 escrowID = numEscrows[msg.sender]++;
    AIProcessingJobs[msg.sender][escrowID] = AIProcessingJob({ escrowID: escrowID, escrow: new EscrowAIJob(msg.value), uuid: UUID });
  }

}

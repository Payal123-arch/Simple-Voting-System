// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title SimpleVotingSystem
 * @dev Basic governance voting system based on ERC20 token holdings
 */
contract SimpleVotingSystem is Ownable {
    IERC20 public votingToken;
    uint256 public proposalCount;
    uint256 public votingPeriod;  // in blocks

    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 deadline;
        bool executed;
        mapping(address => bool) hasVoted;
    }

    mapping(uint256 => Proposal) public proposals;

    // Events
    event ProposalCreated(uint256 proposalId, address proposer, string description, uint256 deadline);
    event Voted(uint256 proposalId, address voter, bool support, uint256 weight);
    event ProposalFinalized(uint256 proposalId, bool passed);

    constructor(IERC20 _votingToken, uint256 _votingPeriod) {
        votingToken = _votingToken;
        votingPeriod = _votingPeriod;  // e.g., 100 blocks
        proposalCount = 0;
    }

    /**
     * @dev Creates a new proposal.
     */
    function createProposal(string calldata description) external returns (uint256) {
        proposalCount++;
        Proposal storage p = proposals[proposalCount];
        p.id = proposalCount;
        p.proposer = msg.sender;
        p.description = description;
        p.deadline = block.number + votingPeriod;
        p.executed = false;

        emit ProposalCreated(proposalCount, msg.sender, description, p.deadline);
        return proposalCount;
    }

    /**
     * @dev Execute a proposal after the deadline, if passed.
     */
    function executeProposal(uint256 proposalId) external {
        Proposal storage p = proposals[proposalId];
        require(block.number > p.deadline, "Voting still active");
        require(!p.executed, "Already executed");

        bool passed = (p.votesFor > p.votesAgainst);

        // Here, add the logic to execute the proposal's decision
        // For example, change protocol parameters, upgrade a contract, etc.

        p.executed = true;
        emit ProposalFinalized(proposalId, passed);
    }

    /**
     * @dev Vote support or against a proposal.
     */
    function vote(uint256 proposalId, bool support) external {
        Proposal storage p = proposals[proposalId];

        require(block.number <= p.deadline, "Voting period over");
        require(!p.hasVoted[msg.sender], "Already voted");
        uint256 weight = votingToken.balanceOf(msg.sender);
        require(weight > 0, "No voting power");

        p.hasVoted[msg.sender] = true;
        if (support) {
            p.votesFor += weight;
        } else {
            p.votesAgainst += weight;
        }

        emit Voted(proposalId, msg.sender, support, weight);
    }

    /**
     * @dev Get voting results: supports, against, and total votes.
     */
    function getProposalResults(uint256 proposalId) external view returns (uint256 votesFor, uint256 votesAgainst) {
        Proposal storage p = proposals[proposalId];
        return (p.votesFor, p.votesAgainst);
    }
}

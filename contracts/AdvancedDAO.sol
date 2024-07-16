// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract AdvancedDAO {
    using SafeERC20 for IERC20;

    IERC20 public governanceToken;
    uint256 public proposalCount;
    uint256 public votingPeriod;
    uint256 public quorumPercentage;
    address public owner;

    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        uint256 voteCount;
        uint256 endTime;
        bool executed;
        mapping(address => bool) voters;
    }

    mapping(uint256 => Proposal) public proposals;

    event ProposalCreated(uint256 id, address proposer, string description);
    event Voted(uint256 proposalId, address voter, bool support);
    event ProposalExecuted(uint256 proposalId);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    modifier onlyTokenHolders() {
        require(
            governanceToken.balanceOf(msg.sender) > 0,
            "Only token holders can perform this action"
        );
        _;
    }

    constructor(
        IERC20 _governanceToken,
        uint256 _votingPeriod,
        uint256 _quorumPercentage
    ) {
        require(
            _quorumPercentage <= 100,
            "Quorum percentage cannot exceed 100"
        );

        governanceToken = _governanceToken;
        votingPeriod = _votingPeriod;
        quorumPercentage = _quorumPercentage;
        owner = msg.sender;
    }

    function createProposal(
        string memory _description
    ) external onlyTokenHolders {
        proposalCount++;
        Proposal storage newProposal = proposals[proposalCount];
        newProposal.id = proposalCount;
        newProposal.proposer = msg.sender;
        newProposal.description = _description;
        newProposal.endTime = block.timestamp + votingPeriod;
        newProposal.executed = false;

        emit ProposalCreated(proposalCount, msg.sender, _description);
    }

    function vote(
        uint256 _proposalId,
        bool _support
    ) external onlyTokenHolders {
        Proposal storage proposal = proposals[_proposalId];
        require(block.timestamp < proposal.endTime, "Voting period has ended");
        require(!proposal.voters[msg.sender], "You have already voted");

        uint256 voterBalance = governanceToken.balanceOf(msg.sender);
        if (_support) {
            proposal.voteCount += voterBalance;
        }

        proposal.voters[msg.sender] = true;

        emit Voted(_proposalId, msg.sender, _support);
    }

    function executeProposal(uint256 _proposalId) external onlyOwner {
        Proposal storage proposal = proposals[_proposalId];
        require(
            block.timestamp >= proposal.endTime,
            "Voting period has not ended"
        );
        require(!proposal.executed, "Proposal already executed");

        uint256 totalSupply = governanceToken.totalSupply();
        uint256 quorumVotes = (totalSupply * quorumPercentage) / 100;

        require(proposal.voteCount >= quorumVotes, "Quorum not reached");

        proposal.executed = true;

        emit ProposalExecuted(_proposalId);
    }

    function updateVotingPeriod(uint256 _votingPeriod) external onlyOwner {
        votingPeriod = _votingPeriod;
    }

    function updateQuorumPercentage(
        uint256 _quorumPercentage
    ) external onlyOwner {
        require(
            _quorumPercentage <= 100,
            "Quorum percentage cannot exceed 100"
        );
        quorumPercentage = _quorumPercentage;
    }
}

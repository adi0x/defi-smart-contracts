// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleDAO {
    
    struct Proposal {
        uint256 id;
        string description;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 deadline;
        bool executed;
        mapping(address => bool) hasVoted;
    }
    
    mapping(uint256 => Proposal) public proposals;
    mapping(address => bool) public members;
    mapping(address => uint256) public votingPower;
    
    uint256 public proposalCount;
    uint256 public totalMembers;
    uint256 public constant VOTING_PERIOD = 3 days;
    uint256 public constant QUORUM_PERCENTAGE = 30;
    
    address public admin;
    uint256 public totalVotingPower;
    
    event MemberAdded(address indexed member, uint256 votingPower);
    event ProposalCreated(uint256 indexed proposalId, string description, uint256 deadline);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support, uint256 weight);
    event ProposalExecuted(uint256 indexed proposalId, bool passed);
    
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this");
        _;
    }
    
    modifier onlyMember() {
        require(members[msg.sender], "Only members can call this");
        _;
    }
    
    constructor() {
        admin = msg.sender;
        members[msg.sender] = true;
        votingPower[msg.sender] = 1;
        totalMembers = 1;
        totalVotingPower = 1;
    }
    
    function addMember(address _member, uint256 _votingPower) external onlyAdmin {
        require(!members[_member], "Already a member");
        require(_votingPower > 0, "Voting power must be > 0");
        
        members[_member] = true;
        votingPower[_member] = _votingPower;
        totalMembers++;
        totalVotingPower += _votingPower;
        
        emit MemberAdded(_member, _votingPower);
    }
    
    function createProposal(string memory _description) external onlyMember returns (uint256) {
        proposalCount++;
        uint256 proposalId = proposalCount;
        
        Proposal storage newProposal = proposals[proposalId];
        newProposal.id = proposalId;
        newProposal.description = _description;
        newProposal.deadline = block.timestamp + VOTING_PERIOD;
        newProposal.executed = false;
        
        emit ProposalCreated(proposalId, _description, newProposal.deadline);
        
        return proposalId;
    }
    
    function vote(uint256 _proposalId, bool _support) external onlyMember {
        Proposal storage proposal = proposals[_proposalId];
        
        require(block.timestamp < proposal.deadline, "Voting period ended");
        require(!proposal.hasVoted[msg.sender], "Already voted");
        require(!proposal.executed, "Proposal already executed");
        
        proposal.hasVoted[msg.sender] = true;
        uint256 weight = votingPower[msg.sender];
        
        if (_support) {
            proposal.forVotes += weight;
        } else {
            proposal.againstVotes += weight;
        }
        
        emit Voted(_proposalId, msg.sender, _support, weight);
    }
    
    function executeProposal(uint256 _proposalId) external {
        Proposal storage proposal = proposals[_proposalId];
        
        require(block.timestamp >= proposal.deadline, "Voting still ongoing");
        require(!proposal.executed, "Already executed");
        
        uint256 totalVotes = proposal.forVotes + proposal.againstVotes;
        uint256 quorumRequired = (totalVotingPower * QUORUM_PERCENTAGE) / 100;
        
        require(totalVotes >= quorumRequired, "Quorum not reached");
        
        proposal.executed = true;
        bool passed = proposal.forVotes > proposal.againstVotes;
        
        emit ProposalExecuted(_proposalId, passed);
    }
    
    function getProposal(uint256 _proposalId) external view returns (
        uint256 id,
        string memory description,
        uint256 forVotes,
        uint256 againstVotes,
        uint256 deadline,
        bool executed
    ) {
        Proposal storage proposal = proposals[_proposalId];
        return (
            proposal.id,
            proposal.description,
            proposal.forVotes,
            proposal.againstVotes,
            proposal.deadline,
            proposal.executed
        );
    }
    
    function hasVoted(uint256 _proposalId, address _voter) external view returns (bool) {
        return proposals[_proposalId].hasVoted[_voter];
    }
}

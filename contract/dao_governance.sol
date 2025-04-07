
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract DAOGovernance {
    address public admin;
    uint256 public proposalCount = 0;

    struct Proposal {
        uint256 id;
        string description;
        uint256 voteCountYes;
        uint256 voteCountNo;
        uint256 deadline;
        bool executed;
        mapping(address => bool) voted;
    }

    mapping(uint256 => Proposal) public proposals;
    mapping(address => bool) public members;

    event ProposalCreated(uint256 id, string description, uint256 deadline);
    event Voted(uint256 proposalId, address voter, bool vote);
    event ProposalExecuted(uint256 id, bool passed);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin");
        _;
    }

    modifier onlyMembers() {
        require(members[msg.sender], "Only members can vote");
        _;
    }

    constructor() {
        admin = msg.sender;
        members[msg.sender] = true;
    }

    function addMember(address _member) external onlyAdmin {
        members[_member] = true;
    }

    function createProposal(string calldata _description, uint256 _durationInMinutes) external onlyMembers {
        require(_durationInMinutes > 0, "Duration must be greater than 0");

        proposalCount++;
        Proposal storage newProposal = proposals[proposalCount];
        newProposal.id = proposalCount;
        newProposal.description = _description;
        newProposal.deadline = block.timestamp + (_durationInMinutes * 1 minutes);
        newProposal.executed = false;

        emit ProposalCreated(proposalCount, _description, newProposal.deadline);
    }

    function voteOnProposal(uint256 _id, bool _support) external onlyMembers {
        Proposal storage proposal = proposals[_id];

        require(block.timestamp < proposal.deadline, "Voting ended");
        require(!proposal.voted[msg.sender], "Already voted");

        proposal.voted[msg.sender] = true;

        if (_support) {
            proposal.voteCountYes++;
        } else {
            proposal.voteCountNo++;
        }

        emit Voted(_id, msg.sender, _support);
    }

    function executeProposal(uint256 _id) external onlyMembers {
        Proposal storage proposal = proposals[_id];

        require(block.timestamp >= proposal.deadline, "Voting not ended");
        require(!proposal.executed, "Already executed");

        proposal.executed = true;
        bool passed = proposal.voteCountYes > proposal.voteCountNo;

        emit ProposalExecuted(_id, passed);
    }

    function getProposal(uint256 _id) external view returns (
        string memory description,
        uint256 voteCountYes,
        uint256 voteCountNo,
        uint256 deadline,
        bool executed
    ) {
        Proposal storage p = proposals[_id];
        return (p.description, p.voteCountYes, p.voteCountNo, p.deadline, p.executed);
    }

    function isMember(address _addr) external view returns (bool) {
        return members[_addr];
    }

    function hasVoted(uint256 _id, address _voter) external view returns (bool) {
        return proposals[_id].voted[_voter];
    }
}

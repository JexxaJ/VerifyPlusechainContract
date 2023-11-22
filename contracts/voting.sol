// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Voting contract
/// @notice This contract allows for voting using an ERC20 token.
contract Voting is Ownable {
    IERC20 public token; // The ERC20 token used for voting
    mapping(uint256 => Candidate) public candidates;
    uint256 public totalCandidates;
    address[] public voterAddresses;
    mapping(uint256 => address[]) public candidateVoters;

    /// @notice Represents a voter with their total votes and votes per candidate
    struct Voter {
        uint256 totalVotes;
        mapping(uint256 => uint256) votes;
    }

    /// @notice Represents a candidate with their ID and vote balance
    struct Candidate {
        uint256 id;
        uint256 voteBalance;
    }

    mapping(address => Voter) public voters;

    event CandidateAdded(uint256 candidateId);
    event VoteCast(address voter, uint256 candidateId, uint256 amount);
    event VoteChanged(address voter, uint256 candidateId, uint256 amount);
    event VoteWithdrawn(address voter, uint256 candidateId, uint256 amount);

    /// @notice Sets the ERC20 token used for voting
    constructor(address _token) Ownable(msg.sender) {
        token = IERC20(_token);
    }

    /// @notice Adds a new candidate for voting
    function addCandidate() public onlyOwner {
        totalCandidates++;
        candidates[totalCandidates] = Candidate(totalCandidates, 0);
        emit CandidateAdded(totalCandidates);
    }

    /// @notice Adds multiple candidates at once
    function addCandidatesInBulk(uint256 amount) external onlyOwner {
        for (uint256 i = 0; i < amount; i++) {
            addCandidate();
        }
    }

    /// @notice Allows a user to vote for a candidate
    function vote(uint256 candidateId, uint256 amount) external {
        require(candidates[candidateId].id != 0, "Candidate does not exist");
        require(
            token.balanceOf(msg.sender) >=
                voters[msg.sender].totalVotes + amount,
            "Not enough tokens to vote"
        );

        // Check if the voter has approved enough tokens
        require(
            token.allowance(msg.sender, address(this)) >= amount,
            "Token allowance too low"
        );

        if (voters[msg.sender].votes[candidateId] > 0) {
            emit VoteChanged(msg.sender, candidateId, amount);
        } else {
            emit VoteCast(msg.sender, candidateId, amount);
            voterAddresses.push(msg.sender);
            candidateVoters[candidateId].push(msg.sender);
        }

        voters[msg.sender].totalVotes += amount;
        voters[msg.sender].votes[candidateId] += amount;
        candidates[candidateId].voteBalance += amount;

        bool success = token.transferFrom(msg.sender, address(this), amount);
        require(success, "Token transfer failed");
    }

    /// @notice Allows a user to withdraw their vote for a candidate
    function withdrawVote(uint256 candidateId) external {
        require(candidates[candidateId].id != 0, "Candidate does not exist");
        uint256 voteAmount = voters[msg.sender].votes[candidateId];
        require(voteAmount > 0, "No votes to withdraw");
        require(
            voteAmount <= voters[msg.sender].totalVotes,
            "Vote withdrawal exceeds voter's balance"
        );

        voters[msg.sender].totalVotes -= voteAmount;
        candidates[candidateId].voteBalance -= voteAmount;
        emit VoteWithdrawn(msg.sender, candidateId, voteAmount);
        voters[msg.sender].votes[candidateId] = 0;

        for (uint256 i = 0; i < candidateVoters[candidateId].length; i++) {
            if (candidateVoters[candidateId][i] == msg.sender) {
                candidateVoters[candidateId][i] = candidateVoters[candidateId][
                    candidateVoters[candidateId].length - 1
                ];
                candidateVoters[candidateId].pop();
                break;
            }
        }

        bool success = token.transfer(msg.sender, voteAmount);
        require(success, "Token transfer failed");
    }

    /// @notice Allows a user to withdraw all their votes for all candidates
    function withdrawAllVotes() external {
        // Iterate over all candidates
        for (uint256 i = 1; i <= totalCandidates; i++) {
            // Check if the voter has voted for this candidate
            if (voters[msg.sender].votes[i] > 0) {
                // Withdraw the votes
                uint256 voteAmount = voters[msg.sender].votes[i];
                voters[msg.sender].totalVotes -= voteAmount;
                candidates[i].voteBalance -= voteAmount;
                emit VoteWithdrawn(msg.sender, i, voteAmount);
                voters[msg.sender].votes[i] = 0;

                // Transfer the tokens back to the voter
                bool success = token.transfer(msg.sender, voteAmount);
                require(success, "Token transfer failed");
            }
        }
    }

    /// @notice Ends the voting process and returns tokens to voters
    function endVoting() external onlyOwner {
        for (uint256 i = 0; i < voterAddresses.length; i++) {
            address voterAddress = voterAddresses[i];
            for (uint256 j = 1; j <= totalCandidates; j++) {
                if (voters[voterAddress].votes[j] > 0) {
                    uint256 voteAmount = voters[voterAddress].votes[j];
                    voters[voterAddress].totalVotes -= voteAmount;
                    candidates[j].voteBalance -= voteAmount;
                    voters[voterAddress].votes[j] = 0;

                    bool success = token.transfer(voterAddress, voteAmount);
                    require(success, "Token transfer failed");
                }
            }
        }
    }

    /// @notice Returns an array of all candidates
    function getCandidates() external view returns (Candidate[] memory) {
        Candidate[] memory candidateList = new Candidate[](totalCandidates);
        for (uint256 i = 1; i <= totalCandidates; i++) {
            candidateList[i - 1] = candidates[i];
        }
        return candidateList;
    }

    /// @notice Returns an array of all voter addresses and their total votes
    function getAllVoters()
        public
        view
        returns (address[] memory, uint256[] memory)
    {
        uint256 length = voterAddresses.length;

        uint256[] memory totalVotesArray = new uint256[](length);

        for (uint256 i = 0; i < length; i++) {
            address voterAddress = voterAddresses[i];
            totalVotesArray[i] = voters[voterAddress].totalVotes;
        }

        return (voterAddresses, totalVotesArray);
    }

    /// @notice Returns an array of all candidate IDs and the corresponding votes cast by a specific voter
    function getVotesForAllCandidates(
        address voterAddress
    ) public view returns (uint256[] memory, uint256[] memory) {
        uint256[] memory candidateIdsArray = new uint256[](totalCandidates);
        uint256[] memory votesArray = new uint256[](totalCandidates);

        for (uint256 i = 1; i <= totalCandidates; i++) {
            candidateIdsArray[i - 1] = i;
            votesArray[i - 1] = voters[voterAddress].votes[i];
        }

        return (candidateIdsArray, votesArray);
    }

    /// @notice Returns an array of all voters who have voted for a specific candidate
    function getVotersForCandidate(
        uint256 candidateId
    ) external view returns (address[] memory) {
        return candidateVoters[candidateId];
    }
}

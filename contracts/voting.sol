// SPDX-License-Identifier: MIT
pragma solidity 0.8.20; //shanghai EVM

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Voting contract
/// @notice This contract allows for voting using an ERC20 token.
contract Voting is Ownable {
    IERC20 public token; // The ERC20 token used for voting

    // Struct for Votes
    struct Votes {
        uint256 amount;
        bool locked;
    }

    // Mappings for Candidates and Voters
    mapping(uint256 => uint256) public candidateVotes;
    mapping(address => mapping(uint256 => Votes)) public voterVotesPerCandidate;
    mapping(address => mapping(uint256 => bool)) public voterVotedCandidate;

    // Variables
    uint256[] candidates;
    uint256 public totalCandidates;
    uint256 public endTime;
    bool public initialised;
    bool public votingEndedByAdmin;

    // Events
    event CandidateAdded(uint256 candidate);
    event VoteCasted(address voter, uint256 candidate, uint256 amount);
    event VoteChanged(address voter, uint256 candidate, uint256 amount);
    event VoteWithdrawn(address voter, uint256 candidate, uint256 amount);

    /// @notice Sets the ERC20 token used for voting
    constructor(address _token) Ownable(_msgSender()) {
        token = IERC20(_token);
    }

    /// @notice Initialises the voting setting: number of candidates, IDs and end timestamp
    //  @param _candidates: list of initial candidates
    //  @param _endTime: time from when votes are not valid anymore and withdrawals unlock only, won't affect final tally
    function initialise(
        uint256[] memory _candidates,
        uint256 _endTime
    ) external onlyOwner {
        require(_candidates.length > 0, "List of candidates is empty");
        require(_candidates.length <= 500, "Candidates can't be more than 500");

        if (_endTime > 0) {
            require(
                _endTime > block.timestamp,
                "endTime must be greater than current time"
            );
        }

        require(!initialised, "Voting already initialised");

        for (uint256 index = 0; index < _candidates.length; index++) {
            if (_candidates[index] == 0) {
                revert("No candidate can be id 0");
            }
        }

        totalCandidates = _candidates.length;
        endTime = _endTime;

        candidates.push(0); // disregard candidate ID = 0

        for (uint256 index = 0; index < _candidates.length; index++) {
            candidates.push(_candidates[index]);
            emit CandidateAdded(_candidates[index]);
        }

        initialised = true;
    }

    function checkVotingIsOver() public view returns (bool) {
        if (votingEndedByAdmin) {
            return true;
        }

        if (endTime > 0) {
            if (block.timestamp > endTime) {
                return true;
            }
        }
        return false;
    }

    /////////////////////
    // Voter Functions //
    /////////////////////

    /// @notice Allows a user to vote for a candidate
    function vote(uint256 _candidate, uint256 _amount) public {
        require(initialised, "Voting has not been initialised");

        if (endTime > 0) {
            require(block.timestamp < endTime, "The voting is over");
        }

        require(
            !votingEndedByAdmin,
            "Can't vote on a voting ended by the admin"
        );

        require(checkCandidateExists(_candidate), "Candidate does not exist");

        require(
            token.balanceOf(msg.sender) >= _amount,
            "Not enough tokens to vote"
        );

        // Update mappings
        voterVotesPerCandidate[msg.sender][_candidate].amount += _amount;
        voterVotesPerCandidate[msg.sender][_candidate].locked = true;
        candidateVotes[_candidate] += _amount;

        // Emit events
        if (voterVotedCandidate[msg.sender][_candidate]) {
            emit VoteChanged(msg.sender, _candidate, _amount);
        } else {
            emit VoteCasted(msg.sender, _candidate, _amount);
        }

        // Send tockens to Voting smart contract
        bool success = token.transferFrom(msg.sender, address(this), _amount);
        require(success, "Token transfer failed");

        voterVotedCandidate[msg.sender][_candidate] = true;
    }

    /// @notice Allows a user to vote for more than one candidate
    function multiVote(
        uint256[] memory _candidates,
        uint256[] memory _amounts
    ) external {
        require(initialised, "Voting has not been initialised");

        if (endTime > 0) {
            require(block.timestamp < endTime, "The voting is over");
        }

        require(
            !votingEndedByAdmin,
            "Can't vote on a voting ended by the admin"
        );

        require(_candidates.length > 0, "List of candidates is empty");
        require(_amounts.length > 0, "List of amounts is empty");
        require(
            _candidates.length == _amounts.length,
            "Length of both lists must be equal"
        );

        uint256 totalAmount = 0;

        for (uint256 index = 0; index < _amounts.length; index++) {
            totalAmount += _amounts[index];
        }

        require(
            token.balanceOf(msg.sender) >= totalAmount,
            "Not enough tokens to vote"
        );

        for (uint256 index = 0; index < _candidates.length; index++) {
            vote(_candidates[index], _amounts[index]);
        }

        // Send tockens to Voting smart contract
        bool success = token.transferFrom(
            msg.sender,
            address(this),
            totalAmount
        );
        require(success, "Token transfer failed");
    }

    /// @notice Allows a user to withdraw their vote for a candidate
    function withdrawVote(uint256 _candidate) external returns (uint256) {
        require(initialised, "Voting has not been initialised");

        bool votingIsOver = checkVotingIsOver();

        require(checkCandidateExists(_candidate), "Candidate does not exist");
        require(
            voterVotedCandidate[msg.sender][_candidate],
            "Voter did not vote for candidate"
        );
        require(
            voterVotesPerCandidate[msg.sender][_candidate].amount > 0,
            "Vote amount cannot be zero"
        );

        uint256 voteAmount = voterVotesPerCandidate[msg.sender][_candidate]
            .amount;
        voterVotesPerCandidate[msg.sender][_candidate].locked = false;

        // Withdraw the vote
        if (!votingIsOver) {
            candidateVotes[_candidate] -= voteAmount;
            voterVotesPerCandidate[msg.sender][_candidate].amount = 0;
            voterVotedCandidate[msg.sender][_candidate] = false;
            emit VoteWithdrawn(msg.sender, _candidate, voteAmount);
        }

        // Transfer the tokens back to the voter
        bool success = token.transfer(msg.sender, voteAmount);
        require(success, "Token transfer failed");

        return voteAmount;
    }

    /// @notice Allows a user to withdraw all their votes for all candidates
    function withdrawAllVotes() external returns (uint256) {
        require(initialised, "Voting has not been initialised");

        bool votingIsOver = checkVotingIsOver();

        require(hasVoted(), "No votes casted from this address");

        uint256 totalVoteAmount = getTotalVotingPower();

        // Iterate over all candidates
        for (
            uint256 candidate = 1;
            candidate < totalCandidates + 1;
            candidate++
        ) {
            // Check if the voter has voted for this candidate
            if (voterVotedCandidate[msg.sender][candidates[candidate]]) {
                // Withdraw the votes
                uint256 voteAmount = voterVotesPerCandidate[msg.sender][
                    candidates[candidate]
                ].amount;
                voterVotesPerCandidate[msg.sender][candidates[candidate]]
                    .locked = false;
                if (!votingIsOver) {
                    candidateVotes[candidates[candidate]] -= voteAmount;
                    voterVotesPerCandidate[msg.sender][candidates[candidate]]
                        .amount = 0;
                    voterVotedCandidate[msg.sender][
                        candidates[candidate]
                    ] = false;
                    emit VoteWithdrawn(
                        msg.sender,
                        candidates[candidate],
                        voteAmount
                    );
                }
            }
        }

        // Transfer the tokens back to the voter
        require(totalVoteAmount > 0, "No votes to withdraw");
        bool success = token.transfer(msg.sender, totalVoteAmount);
        require(success, "Token transfer failed");

        return totalVoteAmount;
    }

    /// @notice Returns an array of the number of votes a voter casted
    function getNumberOfVotes() external view returns (uint256) {
        uint256 votesCasted = 0;

        for (
            uint256 candidate = 1;
            candidate < totalCandidates + 1;
            candidate++
        ) {
            if (voterVotedCandidate[msg.sender][candidates[candidate]]) {
                if (
                    voterVotesPerCandidate[msg.sender][candidates[candidate]]
                        .amount > 0
                ) {
                    votesCasted += 1;
                }
            }
        }

        return votesCasted;
    }

    /// @notice Returns the voting power of a vote for a candidate
    function getVote(uint256 _candidate) external view returns (uint256) {
        return voterVotesPerCandidate[msg.sender][_candidate].amount;
    }

    /// @notice Returns an array of the number of votes a voter casted
    function getTotalVotingPower() public view returns (uint256) {
        uint256 votesCasted = 0;

        for (
            uint256 candidate = 1;
            candidate < totalCandidates + 1;
            candidate++
        ) {
            if (voterVotedCandidate[msg.sender][candidates[candidate]]) {
                if (
                    voterVotesPerCandidate[msg.sender][candidates[candidate]]
                        .amount > 0
                ) {
                    votesCasted += voterVotesPerCandidate[msg.sender][
                        candidates[candidate]
                    ].amount;
                }
            }
        }

        return votesCasted;
    }

    function hasVoted() public view returns (bool) {
        for (
            uint256 candidate = 1;
            candidate < totalCandidates + 1;
            candidate++
        ) {
            if (voterVotedCandidate[msg.sender][candidates[candidate]]) {
                return true;
            }
        }
        return false;
    }

    function isVoteLocked(
        address _voter,
        uint256 _candidate
    ) public view returns (bool) {
        return voterVotesPerCandidate[_voter][_candidate].locked;
    }

    /////////////////////////
    // Candidate Functions //
    /////////////////////////

    /// @notice Returns an array of all candidates
    function getCandidateList() external view returns (uint256[] memory) {
        return candidates;
    }

    /// @notice Returns the number of total candidates
    function getAmountOfCandidates() external view returns (uint256) {
        return totalCandidates;
    }

    /// @notice Returns the total amount of votes received by a candidate
    function getCandidateVotes(
        uint256 _candidateId
    ) external view returns (uint256) {
        return candidateVotes[_candidateId];
    }

    function checkCandidateExists(
        uint256 _candidateId
    ) public view returns (bool) {
        for (uint256 index = 1; index < totalCandidates + 1; index++) {
            if (candidates[index] == _candidateId) {
                return true;
            }
        }
        return false;
    }

    /////////////////////
    // Admin Functions //
    /////////////////////

    function addCandidates(
        uint256[] memory _newCandidatesList
    ) public onlyOwner returns (uint256[] memory) {
        require(initialised, "Voting has not been initialised");

        if (endTime > 0) {
            require(block.timestamp < endTime, "The voting is over");
        }

        require(
            !votingEndedByAdmin,
            "Can't add candidates on a voting ended by the admin"
        );

        require(
            _newCandidatesList.length > 0,
            "List of new candidates is empty"
        );

        require(
            totalCandidates + _newCandidatesList.length <= 500,
            "Candidates can't be more than 500"
        );

        for (uint256 index = 0; index < _newCandidatesList.length; index++) {
            if (_newCandidatesList[index] == 0) {
                revert("No candidate can be id 0");
            }
        }

        for (uint256 index = 0; index < _newCandidatesList.length; index++) {
            candidates.push(_newCandidatesList[index]);
        }

        totalCandidates = candidates.length;

        return candidates;
    }

    function setEndTime(uint256 _newEndTime) public onlyOwner {
        require(initialised, "Voting has not been initialised");

        if (endTime > 0) {
            require(
                endTime > block.timestamp,
                "Can't change the endTime of a voting that is over"
            );
        }

        require(
            !votingEndedByAdmin,
            "Can't change the endTime of a voting ended by the admin"
        );

        require(_newEndTime > 0, "newEndTime can't be zero");

        require(
            _newEndTime > endTime,
            "newEndTime must be greater than current endTime"
        );

        endTime = _newEndTime;
    }

    function endVoting() public onlyOwner {
        require(initialised, "Voting has not been initialised");

        require(endTime == 0, "Can't end a voting that is scheduled to finish");

        votingEndedByAdmin = true;
    }
}

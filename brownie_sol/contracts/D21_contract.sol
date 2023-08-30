// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../interfaces/IVoteD21.sol";

/// @title D21 - contract that implements d21 voting method,
///        see readme for details
/// @author Timotej Ponek
contract D21 is IVoteD21 {
    address payable immutable public owner;

    uint immutable public creationTime;
    uint constant public duration = 7 days;

    /// @title struct representing voter
    struct Voter{
        /// @notice stores addresses of subjects positively voted for, for further checking
        address[2] votedPositive;
        bool votedNegative;
        /// @notice used for checking if mapping of address to Voter structs truly exists
        bool registered;
    }

    mapping (address => Subject) public subjectsMap;
    mapping (string => bool) public subjectNamesRegistered;
    address[] public subjectsAddresses;

    mapping (address => Voter) public votersMap;

    constructor () {
        owner = payable(msg.sender);
        creationTime = block.timestamp;
    }

    /// @notice Creates new Subject and stores it in contract
    /// @dev Function allows for whitespace only name :(
    /// @param name name for subject, must be non empty string
    function addSubject(string memory name) external subjectNameNotUsed(name) {
        // disallows empty name, but still allows whitespace only name
        if(bytes(name).length == 0)
            revert("Name for subject cannot be empty");

        // Generate a new address for the subject
        address subjectAddress = address(bytes20(uint160(subjectsAddresses.length + 1)));

        Subject memory newSubject = Subject(name, 0);
        subjectNamesRegistered[name] = true;
        subjectsMap[subjectAddress] = newSubject;
        subjectsAddresses.push(subjectAddress);
    }

    /// @notice Adds new voter to voting contract, can only be called by owner
    /// @dev Creates new Voter object (which represents newly added voter)
    /// @param addr address of new voter
    function addVoter(address addr) external onlyOwner {
        votersMap[addr] = Voter([address(0), address(0)], false, true);
    }

    /// @notice Returns addresses of all added subjects 
    /// @return address[] array with subjects addresses
    function getSubjects() external view returns(address[] memory) {
        return subjectsAddresses;
    }

    /// @notice Returns subject given by address
    /// @param addr address of Subject to get
    /// @return Subject
    function getSubject(address addr) external view returns(Subject memory) {
        return subjectsMap[addr];
    }

    /// @notice Vote positive for Subject given by address
    /// @param addr address of Subject to vote for
    function votePositive(address addr) external canVote canVotePositive {
        Voter storage voter = votersMap[msg.sender];
        if (voter.votedPositive[0] == addr){
            revert("Caller cannot vote for same party twice");
        }
        if (voter.votedPositive[0] == address(0)) {
            voter.votedPositive[0] = addr;
        }
        else {
            voter.votedPositive[1] = addr;
        }
        subjectsMap[addr].votes += 1;
    }

    /// @notice Vote negative for Subject given by address
    /// @param addr address of Subject to vote for
    function voteNegative(address addr) external canVote canVoteNegative {
        Voter storage voter = votersMap[msg.sender];
        require(voter.votedPositive[0] != addr && voter.votedPositive[1] != addr,
            "Caller cannot vote negative for party that was already voted positive");
        votersMap[msg.sender].votedNegative = true;
        subjectsMap[addr].votes -= 1;
    }

    /// @notice Get time remaining to end of voting
    /// @return uint - represents seconds left to ending of voting
    function getRemainingTime() external view returns(uint) {
        return hasVotingEnded() ? 0 : (creationTime + duration) - block.timestamp;
    }

    /// @dev Converts mapping with subject to array
    /// @return Subject[] array with all subjects present in voting system
    function convertSubjectMapToArray() private view returns(Subject[] memory){
        uint160 l = uint160(subjectsAddresses.length);
        Subject[] memory votingResults = new Subject[](l);
        for(uint160 i = 0; i < l; i = unsafe_inc160(i)) {
            votingResults[i] = subjectsMap[address(bytes20(i+1))];
        }
        return votingResults;
    }

    /// @dev Sorts Subjects in descending order by number of votes they recieved
    /// @return Subject[] array with sorted subjects in descending order
    function getResultsIterativeSort() private view returns(Subject[] memory){
        uint160 l = uint160(subjectsAddresses.length);
        Subject[] memory votingResults = convertSubjectMapToArray();
        for(uint160 i = 0; i < l; i = unsafe_inc160(i)) {
            for(uint160 j = i+1; j < l; j = unsafe_inc160(j)) {
                if(votingResults[i].votes < 
                   votingResults[j].votes) {
                    Subject memory temp = votingResults[i];
                    votingResults[i] = votingResults[j];
                    votingResults[j] = temp;
                }
            }
        }
        return votingResults;
    }

    /// @notice Returns results of voting - array with subjects
    ///         sorted in descending order by number of votes they recieved
    /// @return Subject[] array with sorted subjects in descending order
    function getResults() external view returns(Subject[] memory) {
        require(hasVotingEnded(), "Voting not ended yet, cannot view results");

        return getResultsIterativeSort();
    }
    
    /// @notice Answers whether voting ended or not
    /// @return bool true if ended, false otherwise
    function hasVotingEnded() private view returns(bool) {
        return block.timestamp < creationTime + duration ? false : true;
    }

    /// Section: modifiers

    /// @notice Checks whether sender of message is the owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    /// @notice Checks whether sender of message can vote positive
    modifier canVotePositive() {
        require(!voted2xPositive(), "Exceeded limit for positive votes, cannot vote positive");
        _;
    }

    /// @notice Checks whether sender of message can vote negative
    modifier canVoteNegative() {
        require(voted2xPositive(), "Condition for negative vote not met - need to vote 2 positives first");
        require(!votersMap[msg.sender].votedNegative, "Exceeded limit for negative votes, cannot vote negative");
        _;
    }

    /// @notice Checks whether sender of message voted 2x positive already
    /// @return true if yes, false otherwise
    function voted2xPositive() private view returns(bool) {
        Voter storage voter = votersMap[msg.sender];
        return voter.votedPositive[0] != address(0) && voter.votedPositive[1] != address(0);
    }

    /// @notice Checks whether sender of message can vote
    modifier canVote() {
        require(!hasVotingEnded(), "Voting ended, cannot vote anymore");
        require(votersMap[msg.sender].registered, "Caller is not registered for voting");
        _;
    }

    /// @notice Checks whether given name is not already used for some registered subject
    modifier subjectNameNotUsed(string memory name) {
        require(!subjectNamesRegistered[name]);
        _;
    }

    /// Section: debug functions

    /// @notice Answers whether sender of the message can vote
    /// @return bool true if can vote, false otherwise
    function checkCanSenderVote() external view returns(bool) {
        return votersMap[msg.sender].registered;
    }

    /// @notice Returns array with parties addresses that sender of message has voted for
    /// @return address[2] with parties addresses that sender of message has voted for
    function getVotedParties() external view returns(address[2] memory) {
        require(votersMap[msg.sender].registered, "Caller is not registered for voting");
        return votersMap[msg.sender].votedPositive;
    }

    /// @dev unchecked increment, shoudl be faster then regular checked one
    /// @param x input number
    /// @return uint160 input number increased by one
    function unsafe_inc160(uint160 x) private pure returns (uint160) {
        unchecked { return x + 1; }
    }
    
}
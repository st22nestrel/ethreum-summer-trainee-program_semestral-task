// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../interfaces/IVoteD21.sol";

contract D21 is IVoteD21 {
    address payable immutable public owner;

    uint immutable public creationTime; // state variable to store the creation time
    uint public duration;

    struct Voter{
        address[2] votedPositive;
        bool votedNegative;
        bool registered; //for checking if mapping of address to Voter structs truly exists
    }

    mapping (address => Subject) public subjectsMap;
    address[] public subjectsAdressess;

    mapping (address => Voter) public votersMap;

    constructor (uint _duration) {
        owner = payable(msg.sender);
        creationTime = block.timestamp; // initialize the creation time to current time
        if (_duration == 0)
            duration = _duration;
        else {
            duration = 7 days;
        }
    }

    function addSubject(string memory name) public {
        // Generate a new address for the subject
        address subjectAddress = address(bytes20(uint160(subjectsAdressess.length + 1)));

        Subject memory newSubject = Subject(name, 0);
        subjectsMap[subjectAddress] = newSubject;
        subjectsAdressess.push(subjectAddress);
    }

    //if voter not in 
    function addVoter(address addr) public onlyOwner {
        // maybe payable(addr)
        votersMap[addr] = Voter([address(0), address(0)] ,false, true);
    }

    function getSubjects() public view returns(address[] memory) {
        return subjectsAdressess;
    }

    function getSubject(address addr) public view returns(Subject memory) {
        return subjectsMap[addr];
    }

    function votePositive(address addr) public canVote canVotePositive {
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

    function voteNegative(address addr) public canVote canVoteNegative {
        Voter storage voter = votersMap[msg.sender];
        require(voter.votedPositive[0] != addr && voter.votedPositive[1] != addr,
            "Caller cannot vote negative for party that was already voted positive");
        votersMap[msg.sender].votedNegative = true;
        subjectsMap[addr].votes -= 1;
    }

    function getRemainingTime() public view returns(uint) {
        return creationTime + block.timestamp - duration;
    }



    function getResults() public view returns(Subject[] memory) {
        require(hasVotingEnded(), "Voting not ended yet, cannot view results");

        uint l = subjectsAdressess.length;
        Subject[] memory votingResults = new Subject[](l);
        for(uint i = 0; i < l; i++) {
            for(uint j = i+1; j < l ;j++) {
                if(votingResults[i].votes > 
                   votingResults[j].votes) {
                    Subject memory temp = votingResults[i];
                    votingResults[i] = votingResults[j];
                    votingResults[j] = temp;
                }
            }
        }
        return votingResults;
    }

    function hasVotingEnded() private view returns(bool) {
        return block.timestamp < creationTime + duration ? false : true;
    }

    /// Section: modifiers

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    modifier canVotePositive() {
        require(voted2xPositive() == false, "Exceeded limit for positive votes, cannot vote positive");
        _;
    }

    modifier canVoteNegative() {
        require(voted2xPositive() == true, "Condition for negative vote not met - need to vote 2 positives first");
        require(votersMap[msg.sender].votedNegative == false, "Exceeded limit for negative votes, cannot vote negative");
        _;
    }

    function voted2xPositive() private view returns(bool) {
        Voter storage voter = votersMap[msg.sender];
        return voter.votedPositive[0] != address(0) && voter.votedPositive[1] != address(0);
    }

    modifier canVote() {
        require(hasVotingEnded() == false, "Voting ended, cannot vote anymore");
        require(votersMap[msg.sender].registered == true, "Caller is not registered for voting");
        _;
    }

    /// Section: debug functions
    function checkCanSenderVote() public view returns(bool) {
        return votersMap[msg.sender].registered == true;
    }

    function getVotedParties() public view returns(address[2] memory) {
        return votersMap[msg.sender].votedPositive;
    }
}
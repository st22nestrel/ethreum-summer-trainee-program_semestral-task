// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../interfaces/IVoteD21.sol";

contract D21 is IVoteD21 {
    address payable public owner;
    uint private D21_id;

    uint public creationTime; // state variable to store the creation time

    struct Voter{
        uint positiveVotes;
        uint negativeVotes;
        bool registered; //for checking if mapping of address to Voter structs truly exists
    }

    mapping (address => Subject) private subjectsMap;
    address[] private subjectsAdressess;

    bool private resultsCalculated;
    Subject[] public votingResults;

    //address payable[] private voters;
    mapping (address => Voter) votersMap;
    //Voter[] private voters;

    constructor () {
        owner = payable(msg.sender);
        creationTime = block.timestamp; // initialize the creation time to current time
        D21_id = 1;
    }

    function addSubject(string memory name) public {
        // Generate a new address for the subject
        address subjectAddress = address(bytes20(sha256(abi.encodePacked(name, block.timestamp))));

        Subject memory newSubject = Subject(name, 0);
        subjectsMap[subjectAddress] = newSubject;
        subjectsAdressess.push(subjectAddress);
        votingResults.push(newSubject);
    }

    //if voter not in 
    function addVoter(address addr) public onlyOwner {
        // maybe payable(addr)
        votersMap[addr] = Voter(0, 0, true);
    }

    function getSubjects() public view returns(address[] memory) {
        return subjectsAdressess;
    }

    function getSubject(address addr) public view returns(Subject memory) {
        return subjectsMap[addr];
    }

    function votePositive(address addr) public canVote canVotePositive {
        votersMap[msg.sender].negativeVotes += 1;
        subjectsMap[addr].votes += 1;
    }

    function voteNegative(address addr) public canVote canVoteNegative {
        votersMap[msg.sender].negativeVotes = 1;
        subjectsMap[addr].votes -= 1;
    }

    function getRemainingTime() public view returns(uint) {
        return creationTime + 7 days - block.timestamp;
    }

    function calculateResults() private {
        //uint[subjects.length] memory ordering;

        // algorithm adopted from https://gist.github.com/sdelvalle57/f5f65a31150ea9321f081630b416ed99
        uint l = subjectsAdressess.length;
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
        resultsCalculated = true;
    }

    function getResults() public returns(Subject[] memory) {
        require(hasVotingEnded(), "Voting not ended yet, cannot view results");
        if (!resultsCalculated){
                calculateResults();
            }
        return votingResults;
        /* if (hasVotingEnded()) {
            if (!resultsCalculated){
                calculateResults();
            }
            return votingResults;
        } */
    }

    function hasVotingEnded() private view returns(bool) {
        return block.timestamp < creationTime + 7 days ? false : true;
    }

    // Modifiers

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    modifier canVotePositive() {
        require(votersMap[msg.sender].positiveVotes < 2, "Exceeded limit for positive votes, cannot vote positive");
        _;
    }

    modifier canVoteNegative() {
        require(votersMap[msg.sender].positiveVotes == 2, "Condition for negative vote not met - need to vote 2 positives first");
        require(votersMap[msg.sender].negativeVotes < 1, "Exceeded limit for negative votes, cannot vote negative");
        _;
    }


    // TODO find how to check for null in javascript
    modifier canVote() {
        require(hasVotingEnded() == false, "Voting ended, cannot vote anymore");
        require(votersMap[msg.sender].registered == false, "Caller is not registered for voting");
        _;
    }
}
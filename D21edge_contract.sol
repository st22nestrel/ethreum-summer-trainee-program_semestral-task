// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IVoteD21.sol";

contract D21_edge is IVoteD21 {

    // Define the state variables
    address public owner; // the owner of the contract
    uint public votingDuration; // the voting duration in seconds
    uint public votingEnd; // the voting end time in seconds
    mapping(address => Subject) public subjects; // a mapping from subject address to subject details
    address[] public subjectList; // a list of subject addresses
    mapping(address => bool) public voters; // a mapping from voter address to voter eligibility
    mapping(address => uint) public positiveVotes; // a mapping from voter address to positive votes left
    mapping(address => uint) public negativeVotes; // a mapping from voter address to negative votes left
    mapping(address => mapping(address => bool)) public voted; // a mapping from voter address to subject address to voting status

    // Define the constructor
    constructor(uint _votingDuration) {
        owner = msg.sender;
        votingDuration = _votingDuration;
        votingEnd = block.timestamp + votingDuration;
    }

    // Define the modifier for checking the owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    // Define the modifier for checking the voting time
    modifier withinTime() {
        require(block.timestamp < votingEnd, "Voting time is over");
        _;
    }

    // Define the modifier for checking the voter eligibility
    modifier onlyVoter() {
        require(voters[msg.sender], "You are not an eligible voter");
        _;
    }

    // Define the function for adding a new subject
    function addSubject(string memory name) external withinTime {
        // create a new subject with the given name and zero votes
        Subject memory newSubject = Subject(name, 0);
        // generate a unique address for the subject using keccak256 hash
        address subjectAddress = address(uint160(uint(keccak256(abi.encodePacked(msg.sender, name)))));
        // store the subject in the mapping and the list
        subjects[subjectAddress] = newSubject;
        subjectList.push(subjectAddress);
    }

    // Define the function for adding a new voter
    function addVoter(address addr) external onlyOwner withinTime {
        // mark the address as an eligible voter
        voters[addr] = true;
        // assign 2 positive votes and 1 negative vote to the voter
        positiveVotes[addr] = 2;
        negativeVotes[addr] = 1;
    }

    // Define the function for getting all registered subjects
    function getSubjects() external view returns (address[] memory) {
        return subjectList;
    }

    // Define the function for getting the subject details
    function getSubject(address addr) external view returns (Subject memory) {
        return subjects[addr];
    }

    // Define the function for voting positive for a subject
    function votePositive(address addr) external onlyVoter withinTime {
        // check that the voter has positive votes left
        require(positiveVotes[msg.sender] > 0, "You have no positive votes left");
        // check that the voter has not voted for this subject before
        require(!voted[msg.sender][addr], "You have already voted for this subject");
        // increment the subject's votes by 1
        subjects[addr].votes += 1;
        // decrement the voter's positive votes by 1
        positiveVotes[msg.sender] -= 1;
        // mark that the voter has voted for this subject
        voted[msg.sender][addr] = true;
    }

     // Define the function for voting negative for a subject
     function voteNegative(address addr) external onlyVoter withinTime {
         // check that the voter has negative votes left
         require(negativeVotes[msg.sender] > 0, "You have no negative votes left");
         // check that the voter has not voted for this subject before
         require(!voted[msg.sender][addr], "You have already voted for this subject");
         // check that the voter has used both positive votes before using negative vote
         require(positiveVotes[msg.sender] == 0, "You must use your positive votes first");
         // decrement the subject's votes by 1
         subjects[addr].votes -= 1;
                  // decrement the voter's negative votes by 1
         negativeVotes[msg.sender] -= 1;
         // mark that the voter has voted for this subject
         voted[msg.sender][addr] = true;
     }

     // Define the function for getting the remaining time to the voting end in seconds
     function getRemainingTime() external view returns (uint) {
         // check if the voting is still ongoing
         if (block.timestamp < votingEnd) {
             // return the difference between the voting end and the current time
             return votingEnd - block.timestamp;
         } else {
             // return zero if the voting is over
             return 0;
         }
     }

     // Define the function for getting the voting results, sorted descending by votes
     function getResults() external view returns (Subject[] memory) {
         // check if the voting is over
         require(block.timestamp >= votingEnd, "Voting is still ongoing");
         // create a copy of the subject list
         Subject[] memory results = subjectList;
         // sort the results using bubble sort algorithm
         for (uint i = 0; i < results.length - 1; i++) {
             for (uint j = 0; j < results.length - i - 1; j++) {
                 // swap the subjects if they are not in descending order by votes
                 if (results[j].votes < results[j+1].votes) {
                     Subject memory temp = results[j];
                     results[j] = results[j+1];
                     results[j+1] = temp;
                 }
             }
         }
         // return the sorted results
         return results;
     }
}

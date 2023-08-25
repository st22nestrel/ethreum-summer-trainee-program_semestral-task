// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "IVoteD21.sol";

contract D21 is IVoteD21 {
    address payable public owner;
    uint private D21_id;

    uint public creationTime; // state variable to store the creation time

    struct Voter{
        uint positiveVotes;
        uint negativeVotes;
    }


    mapping (address => Subject) private subjectsMap;
    Subject[] private subjects;

    //address payable[] private voters;
    mapping (address => Voter) votersMap;
    //Voter[] private voters;

    constructor () {
        owner = payable(msg.sender);
        creationTime = block.timestamp; // initialize the creation time to current time
        D21_id = 1;
    }

    function addSubject(string memory name) public {
        //if subject not already in subjects[]
        subjects.push(Subject(name, 0));
    }

    //if voter not in 
    function addVoter(address addr) public onlyOwner {
        // maybe payable(addr)
        voters.push(Voter(addr, 0, 0));
    }

    function getSubjects() public view returns(address[] memory) {
        return subjects;
    }

    function getSubject(address addr) public view returns(Subject memory) {
        return subjectsMap[addr];
    }

    function votePositive(address addr) public canVote canVotePositive {
        votersMap[msg.sender].negativeVotes += 1;
        Subject(addr).votes += 1;
    }

    function voteNegative(address addr) public canVote onlyAfter2PositiveVotes canVoteNegative {
        votersMap[msg.sender].negativeVotes = 1;
        Subject(addr).votes += 1;
    }

    function getRemainingTime() public view returns(uint) {
        
    }

    function getResults() external view returns(Subject[] memory){

    }

    // Modifiers

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    modifier onlyAfter2PositiveVotes() {
        require(votersMap[msg.sender].positiveVotes == 2, "Only the owner can call this function");
        _;
    }

    modifier canVotePositive() {
        require(votersMap[msg.sender].positiveVotes < 2, "Only the owner can call this function");
        _;
    }

    modifier canVoteNegative() {
        require(votersMap[msg.sender].positiveVotes == 2, "Only the owner can call this function");
        require(votersMap[msg.sender].negativeVotes < 1, "Only the owner can call this function");
        _;
    }


    // TODO find how to check for null in javascript
    modifier canVote() {
        require(votersMap[msg.sender] != None, "Only the owner can call this function");
        _;
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../interfaces/IVoteD21.sol";

contract D21 is IVoteD21 {
    address payable immutable public owner;

    uint immutable public creationTime; // state variable to store the creation time
    uint constant public duration = 7 days;

    struct Voter{
        address[2] votedPositive;
        bool votedNegative;
        bool registered; //for checking if mapping of address to Voter structs truly exists
    }

    mapping (address => Subject) public subjectsMap;
    mapping (string => bool) public subjectRegistered;
    address[] public subjectsAddressess;

    mapping (address => Voter) public votersMap;

    constructor () {
        owner = payable(msg.sender);
        creationTime = block.timestamp;
        //creationTime = block.number; // initialize the creation time to current time
    }

    function addSubject(string memory name) public {
        // Generate a new address for the subject
        address subjectAddress = address(bytes20(uint160(subjectsAddressess.length + 1)));

        Subject memory newSubject = Subject(name, 0);
        subjectsMap[subjectAddress] = newSubject;
        subjectsAddressess.push(subjectAddress);
    }

    //if voter not in 
    function addVoter(address addr) public onlyOwner {
        votersMap[addr] = Voter([address(0), address(0)] ,false, true);
    }

    function getSubjects() public view returns(address[] memory) {
        return subjectsAddressess;
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
        return hasVotingEnded() ? 0 : (creationTime + duration) - block.timestamp;
    }

    function convertSubjectMapToArray() public view returns(Subject[] memory){
        uint160 l = uint160(subjectsAddressess.length);
        Subject[] memory votingResults = new Subject[](l);
        for(uint160 i = 0; i < l; i = unsafe_inc160(i)) {
            votingResults[i] = subjectsMap[address(bytes20(i+1))];
        }
        return votingResults;
    }


    function getResults() public view returns(Subject[] memory) {
        require(hasVotingEnded(), "Voting not ended yet, cannot view results");

        return getResultsIterativeSort();
    }

    function getResultsIterativeSort() public view returns(Subject[] memory){
        uint160 l = uint160(subjectsAddressess.length);
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

    function quickSort(Subject[] memory arr, int left, int right) internal view{
        int i = left;
        int j = right;
        if(i==j) return;
        int pivot = arr[uint(left + (right - left) / 2)].votes;
        while (i <= j) {
            while (arr[uint(i)].votes < pivot) i++;
            while (pivot < arr[uint(j)].votes) j--;
            if (i <= j) {
                (arr[uint(i)], arr[uint(j)]) = (arr[uint(j)], arr[uint(i)]);
                i++;
                j--;
            }
        }
        if (left < j)
            quickSort(arr, left, j);
        if (i < right)
            quickSort(arr, i, right);
    }

    function getResultsQuickSort() public view returns(Subject[] memory){
        Subject[] memory votingResults = convertSubjectMapToArray();
        quickSort(votingResults, int(0), int(subjectsAddressess.length - 1));
        return votingResults;
    }
    

    /* function quickSort (uint32[] memory a) internal view returns(Subject[] memory) {
        uint160 l = uint160(subjectsAddressess.length);
        Subject[] memory votingResults = convertSubjectMapToArray();
		uint32 i;
		uint32[] memory s = new uint32[](l);
		uint32 v;
		uint32 t;
		uint32 p;
		uint32 x;
		uint32 y;
		uint32 l;
		uint32 r;


        l = 0;
        r = uint32(a.length - 1);

        i = 2;
        s[0] = l;
        s[0] = r;

        while (i > 0) {
            r = s[--i];
            l = s[--i];

            if (l < r) {
                // partition

                x = l;
                y = r - 1;

                p = l;
                v = a[p];
                a[p] = a[r];

                while (true) {
                    while (
                        x <= y &&
                        a[x] < v) {
                        x++;
                                    }
                    while (
                        x <= y &&
                        a[y] >= v) {
                        y--;
                                    }
                    if (x > y)
                        break;
                    t = a[x];
                    a[x] = a[y];
                    a[y] = t;
                }

                a[r] = a[x];
                a[x] = v;

                // end

                s[i++] = l;
                s[i++] = x - 1;
                s[i++] = x + 1;
                s[i++] = r;
            }
    } */

    function hasVotingEnded() public view returns(bool) {
        return block.timestamp < creationTime + duration ? false : true;
    }

    /// Section: modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    modifier canVotePositive() {
        require(!voted2xPositive(), "Exceeded limit for positive votes, cannot vote positive");
        _;
    }

    modifier canVoteNegative() {
        require(voted2xPositive(), "Condition for negative vote not met - need to vote 2 positives first");
        require(!votersMap[msg.sender].votedNegative, "Exceeded limit for negative votes, cannot vote negative");
        _;
    }

    function voted2xPositive() private view returns(bool) {
        Voter storage voter = votersMap[msg.sender];
        return voter.votedPositive[0] != address(0) && voter.votedPositive[1] != address(0);
    }

    modifier canVote() {
        require(!hasVotingEnded(), "Voting ended, cannot vote anymore");
        require(votersMap[msg.sender].registered, "Caller is not registered for voting");
        _;
    }

    /// Section: debug functions
    function checkCanSenderVote() public view returns(bool) {
        return votersMap[msg.sender].registered;
    }

    function getVotedParties() public view returns(address[2] memory) {
        return votersMap[msg.sender].votedPositive;
    }

    function unsafe_inc160(uint160 x) private pure returns (uint160) {
        unchecked { return x + 1; }
    }

    
}
from brownie import D21, accounts, chain
import pytest
import web3

@pytest.fixture
def d21():
    # deploy the contract with the initial parameters
    return D21.deploy(
        {"from": accounts[0]}
    )

@pytest.fixture()
def add_voters_and_parties(d21):
    d21.addSubject("Dolly democrats", {"from": accounts[0]})
    d21.addSubject("Jelly activists", {"from": accounts[0]})
    d21.addSubject("Brown eco", {"from": accounts[0]})
    d21.addVoter(accounts[1].address, {"from": accounts[0]})
    d21.addVoter(accounts[2].address, {"from": accounts[0]})

@pytest.fixture()
def results_fixture(d21, add_voters_and_parties):
    d21.addSubject("New order", {"from": accounts[0]})
    d21.addSubject("Tasty House", {"from": accounts[0]})
    d21.addVoter(accounts[3].address, {"from": accounts[0]})
    d21.addVoter(accounts[4].address, {"from": accounts[0]})

    subj_add = d21.getSubjects()
    d21.votePositive(subj_add[0], {"from": accounts[1]})
    d21.votePositive(subj_add[1], {"from": accounts[1]})
    d21.voteNegative(subj_add[3], {"from": accounts[1]})

    d21.votePositive(subj_add[1], {"from": accounts[2]})
    d21.votePositive(subj_add[0], {"from": accounts[2]})
    d21.voteNegative(subj_add[3], {"from": accounts[2]})

    d21.votePositive(subj_add[4], {"from": accounts[3]})
    d21.votePositive(subj_add[3], {"from": accounts[3]})
    d21.voteNegative(subj_add[0], {"from": accounts[3]})

    d21.votePositive(subj_add[0], {"from": accounts[4]})
    d21.votePositive(subj_add[2], {"from": accounts[4]})
    d21.voteNegative(subj_add[3], {"from": accounts[4]})

@pytest.fixture()
def time_travel(web3):
    web3 = web3.Web3(d21)
    def _time_travel(seconds):
        current_block = web3.eth.get_block('latest')
        future_timestamp = current_block['timestamp'] + seconds
        web3.provider.make_request(
            "evm_increaseTime",
            [future_timestamp - current_block['timestamp']]
        )
        web3.provider.make_request("evm_mine", [])
    yield _time_travel

@pytest.fixture()
def time_travel_2(d21):
    web3 = d21.web3
    
    # Get the current block number using the deployed contract's web3 instance
    current_block = web3.eth.blockNumber
    current_timestamp = web3.eth.getBlock(current_block)["timestamp"]

    print(f"Current block number: {updated_block}")
    print(f"Current timestamp: {updated_timestamp}")

    # Set the block timestamp to simulate the passage of time
    new_timestamp = current_timestamp + (7 * 24 * 60 * 60)
    web3.testing.timeTravel(new_timestamp)

    # Verify the updated block number and timestamp
    updated_block = web3.eth.blockNumber
    updated_timestamp = web3.eth.getBlock(updated_block)["timestamp"]

    print(f"Current block number: {updated_block}")
    print(f"Current timestamp: {updated_timestamp}")

@pytest.fixture()
def time_travel_3(d21):
    # Get the current block number
    initial_block_number = chain[-1].number
    initial_timestamp = chain[-1].timestamp

    # Calculate the number of blocks equivalent to 7 days
    blocks_to_pass = 7 * 24 * 60 * 4  # Assuming 15 seconds per block
    time_to_pass = 7 * 24 * 60 * 60

    # Increase the block number by the desired number of blocks
    #chain.mine(timestamp=initial_timestamp + time_to_pass)
    chain.mine(timedelta=time_to_pass)


def test_addSubjectAnyone(d21):
    # check that a new subject can be added
    d21.addSubject("Party A", {"from": accounts[1]})
    subj_add = d21.getSubjects()
    assert d21.subjectsMap(subj_add[0]) == ("Party A", 0) 

def test_addVoter(d21):
    d21.addVoter(accounts[1].address, {"from": accounts[0]})
    d21.addVoter(accounts[2].address, {"from": accounts[0]})

    assert d21.checkCanSenderVote({"from": accounts[1]})
    assert d21.checkCanSenderVote({"from": accounts[2]})
    
def test_voteForSubjectPositive(d21, add_voters_and_parties):
    subj_add = d21.getSubjects()
    d21.votePositive(subj_add[0], {"from": accounts[1]})
    d21.votePositive(subj_add[1], {"from": accounts[1]})

    assert d21.subjectsMap(subj_add[0])[1] == 1
    assert d21.subjectsMap(subj_add[1])[1] == 1

    subj_voted = d21.getVotedParties({"from": accounts[1]})
    assert subj_voted[0] == subj_add[0] and subj_voted[1] == subj_add[1]

def test_voteForSubjectNegative(d21, add_voters_and_parties):
    #test_voteForSubjectPositive
    subj_add = d21.getSubjects()
    d21.votePositive(subj_add[0], {"from": accounts[1]})
    d21.votePositive(subj_add[1], {"from": accounts[1]})

    d21.voteNegative(subj_add[2], {"from": accounts[1]})

    assert d21.subjectsMap(subj_add[2])[1] == -1
    assert d21.votersMap(accounts[1])[0] == True



@pytest.mark.xfail(reason="Should not be able to vote 2 positive for same party")
def test_cannotVotePositiveForSameParty(d21, add_voters_and_parties):
    #test_voteForSubjectPositive
    subj_add = d21.getSubjects()
    d21.votePositive(subj_add[0], {"from": accounts[1]})
    d21.votePositive(subj_add[0], {"from": accounts[1]})


@pytest.mark.xfail(reason="Should not be able to vote negative for party that was already voted positive")
def test_cannotVoteNegativeForPositiveParty(d21, add_voters_and_parties):
    #test_voteForSubjectPositive
    subj_add = d21.getSubjects()
    d21.votePositive(subj_add[0], {"from": accounts[1]})
    d21.votePositive(subj_add[1], {"from": accounts[1]})

    d21.voteNegative(subj_add[1], {"from": accounts[1]})


@pytest.mark.xfail(reason="Should not be able to vote positive after voting 2 positive")
def test_cannotVotePositive(d21, add_voters_and_parties):
    #test_voteForSubjectPositive
    subj_add = d21.getSubjects()
    d21.votePositive(subj_add[0], {"from": accounts[1]})
    d21.votePositive(subj_add[1], {"from": accounts[1]})

    d21.votePositive(subj_add[1], {"from": accounts[1]})


@pytest.mark.xfail(reason="Should not be able to vote negative after voting negative")
def test_cannotVoteNegative(d21, add_voters_and_parties):
    #test_voteForSubjectPositive
    subj_add = d21.getSubjects()
    d21.votePositive(subj_add[0], {"from": accounts[1]})
    d21.votePositive(subj_add[1], {"from": accounts[1]})

    #test_voteForSubjectNegative
    d21.voteNegative(subj_add[2], {"from": accounts[1]})
    d21.voteNegative(subj_add[1], {"from": accounts[1]})


def test_getRemainingTime(d21):
    assert d21.getRemainingTime() > 0

def test_getRemainingTime7DaysPassed(d21, time_travel_3):
    #TODO rewind/unwind
    #time.sleep(20)
    #time_travel(7 * 24 * 60 * 60 + 1000)

    #assert 0 == 1
    assert d21.getRemainingTime() == 0

def test_getResults(d21, results_fixture, time_travel_3):
    #TODO rewind/unwind
    assert 0 == 1

    results = d21.getResults()

    #assert 0 == 1
    #figure out what results should look like
    

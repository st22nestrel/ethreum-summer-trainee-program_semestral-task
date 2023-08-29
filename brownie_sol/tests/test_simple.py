from brownie import D21, accounts, network, config
import pytest

@pytest.fixture
def d21():
    # deploy the contract with the initial parameters
    return D21.deploy(120,
        {"from": accounts[0]}
    )

@pytest.fixture()
def add_voters_and_parties(d21):
    d21.addSubject("Demokrati", {"from": accounts[0]})
    d21.addSubject("SaS", {"from": accounts[0]})
    d21.addSubject("Smer", {"from": accounts[0]})
    d21.addVoter(accounts[1].address, {"from": accounts[0]})
    d21.addVoter(accounts[2].address, {"from": accounts[0]})

@pytest.fixture()
def results_fixture(d21, add_voters_and_parties):
    d21.addSubject("Hlas", {"from": accounts[0]})
    d21.addVoter(accounts[3].address, {"from": accounts[0]})
    d21.addVoter(accounts[4].address, {"from": accounts[0]})

    subj_add = d21.getSubjects()
    d21.votePositive(subj_add[0], {"from": accounts[1]})
    d21.votePositive(subj_add[1], {"from": accounts[1]})
    d21.voteNegative(subj_add[2], {"from": accounts[1]})

    d21.votePositive(subj_add[1], {"from": accounts[2]})
    d21.votePositive(subj_add[0], {"from": accounts[2]})
    d21.voteNegative(subj_add[2], {"from": accounts[2]})

    d21.votePositive(subj_add[2], {"from": accounts[3]})
    d21.votePositive(subj_add[3], {"from": accounts[3]})
    d21.voteNegative(subj_add[1], {"from": accounts[3]})

    d21.votePositive(subj_add[3], {"from": accounts[4]})
    d21.votePositive(subj_add[2], {"from": accounts[4]})
    d21.voteNegative(subj_add[1], {"from": accounts[4]})


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

def test_getRemainingTime7DaysPassed(d21):
    #TODO rewind/unwind
    assert d21.getRemainingTime() == 0

def test_getResults(d21, results_fixture):
    #TODO rewind/unwind
    results = d21.getResults()
    #figure out what results should look like
    

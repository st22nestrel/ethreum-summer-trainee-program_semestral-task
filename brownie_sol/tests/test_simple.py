from brownie import D21, accounts, chain
import pytest

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
    d21.addSubject("Executive House", {"from": accounts[0]})
    d21.addVoter(accounts[3].address, {"from": accounts[0]})
    d21.addVoter(accounts[4].address, {"from": accounts[0]})
    d21.addVoter(accounts[5].address, {"from": accounts[0]})

    subj_add = d21.getSubjects()
    d21.votePositive(subj_add[0], {"from": accounts[1]})
    d21.votePositive(subj_add[1], {"from": accounts[1]})
    d21.voteNegative(subj_add[3], {"from": accounts[1]})

    d21.votePositive(subj_add[0], {"from": accounts[2]})
    d21.votePositive(subj_add[2], {"from": accounts[2]})
    d21.voteNegative(subj_add[1], {"from": accounts[2]})

    d21.votePositive(subj_add[1], {"from": accounts[3]})
    d21.votePositive(subj_add[4], {"from": accounts[3]})
    d21.voteNegative(subj_add[2], {"from": accounts[3]})

    d21.votePositive(subj_add[0], {"from": accounts[4]})
    d21.votePositive(subj_add[1], {"from": accounts[4]})
    d21.voteNegative(subj_add[3], {"from": accounts[4]})

    d21.votePositive(subj_add[2], {"from": accounts[5]})
    d21.votePositive(subj_add[3], {"from": accounts[5]})
    d21.voteNegative(subj_add[4], {"from": accounts[5]})

@pytest.fixture()
def time_travel(d21):
    time_to_pass = 7 * 24 * 60 * 60 # 7 days
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

@pytest.mark.xfail(reason="Cannot add party with same name twice")
def test_addSameSubject(d21):
    d21.addSubject("Party A", {"from": accounts[1]})
    d21.addSubject("Party A", {"from": accounts[2]})

@pytest.mark.xfail(reason="Party name cannot be empty")
def test_addEmptySubject(d21):
    d21.addSubject("", {"from": accounts[1]})

@pytest.mark.xfail(reason="Only owner can add eligible voters")
def test_addVoterNonOwner(d21):
    d21.addVoter(accounts[3].address, {"from": accounts[1]})


def test_getRemainingTime(d21):
    assert d21.getRemainingTime() > 0

def test_getRemainingTime7DaysPassed(d21, time_travel):
    assert d21.getRemainingTime() == 0

def test_getResults(d21, results_fixture, time_travel):
    results = d21.getResults()
    assert results == (('Dolly democrats', 3), ('Jelly activists', 2),
                       ('Brown eco', 1), ('Executive House', 0), ('New order', -1))
    

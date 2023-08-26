from brownie import D21, accounts, network, config
import pytest

@pytest.fixture
def d21():
    # deploy the contract with the initial parameters
    """ return D21.deploy(
        config["networks"][network.show_active()]["eth_usd_price_feed"],
        {"from": accounts[0]}
    ) """
    return D21.deploy(
        {"from": accounts[0]}
    )

def test_addSubject(d21):
    # check that a new subject can be added
    tx = d21.addSubject("Party A", {"from": accounts[0]})
    tx.wait(1)
    assert d21.votingResults(0) == ("Party A", 0) 
#    print(d21.votingResults(0))
from brownie import D21, accounts, network, config

def test():
    d21 = D21.deploy(
        {"from": accounts[0]}
    )

    tx = d21.addSubject("Party A", {"from": accounts[0]})
    print(tx)
    
    print(d21.votingResults)
    hell = ("Party A", 0)
    print(d21.votingResults(0))
    print(d21.votingResults(0)[0])
    print(type(d21.votingResults(0)))

    print(d21.votingResults(0) == hell)

def main():
    # check that a new subject can be added
    test()
# Testing Bridge Transactions - Child Chain Mintable Native Token

You'll need to have a successful bridge deployment to make any cross-chain transactions. The commands are built to run in `/var/lib/bootstrap` directory of `validator-001` in order to easily fetch the variables from `genesis.json`. It does not matter which directory commands are run from as long as the arguments are properly passed in.


### Deposit workflow
This command deposits ERC-20 tokens from a Supernet to a rootchain.
```bash
polygon-edge bridge deposit-erc20 \
--sender-key $(cat validator-001.devnet13.edge.company.private/consensus/validator.key) \
--amounts 100 \
--receivers $(cat rootchain-wallet.json | jq -r '.ETHAddress') \
--root-token 0x0000000000000000000000000000000000001010 \
--root-predicate 0x0000000000000000000000000000000000001009 \
--json-rpc http://localhost:10002 \
--minter-key $(cat rootchain-wallet.json | jq -r '.HexPrivateKey') \
--child-chain-mintable

# check sender balance - this will reflect after deposit
cast balance $(cat genesis.json | jq -r '.params.engine.polybft.initialValidatorSet[0].address') --rpc-url localhost:10002

# check receiver balance - this will reflect once exit is called
cast call $(cast call 0x0000000000000000000000000000000000001009 --rpc-url http://localhost:10002 "function rootTokenToChildToken(address) returns (address)" 0x0000000000000000000000000000000000001010) "function balanceOf(address account) view returns(uint256)" $(cat rootchain-wallet.json | jq -r '.ETHAddress') --rpc-url $(cat genesis.json | jq -r '.params.engine.polybft.bridge.jsonRPCEndpoint')

```

### Withdrawal finalization/exit workflow (acquire exit proof + sending exit transaction to the root chain)
This command sends an exit transaction to the ExitHelper contract on the rootchain for a token that was deposited on the rootchain. It basically finalizes a withdrawal (initiated on the rootchain) and transfers assets to receiving address on a Supernet.
```bash
# EXIT
polygon-edge bridge exit \
--sender-key $(cat rootchain-wallet.json | jq -r '.HexPrivateKey') \
--exit-helper $(cat genesis.json | jq -r '.params.engine.polybft.bridge.exitHelperAddress') \
--exit-id 1 \
--root-json-rpc $(cat genesis.json | jq -r '.params.engine.polybft.bridge.jsonRPCEndpoint') \
--child-json-rpc http://localhost:10002
```

### Withdraw workflow
This command withdraws ERC-20 tokens from a rootchain to a Supernet.

```bash
polygon-edge bridge withdraw-erc20 \
 --sender-key $(cat rootchain-wallet.json | jq -r '.HexPrivateKey') \
 --child-token $(cast call 0x0000000000000000000000000000000000001009 --rpc-url http://localhost:10002 "function rootTokenToChildToken(address) returns (address)" 0x0000000000000000000000000000000000001010) \
 --child-predicate $(cat genesis.json | jq -r '.params.engine.polybft.bridge.erc20ChildMintablePredicateAddress') \
 --json-rpc $(cat genesis.json | jq -r '.params.engine.polybft.bridge.jsonRPCEndpoint') \
 --receivers $(cat genesis.json | jq -r '.params.engine.polybft.initialValidatorSet[0].address') \
 --amounts 100 \
 --child-chain-mintable

# check withdrawal - should have deducted after withdraw
cast call $(cast call 0x0000000000000000000000000000000000001009 \
--rpc-url http://localhost:10002 "function rootTokenToChildToken(address) returns (address)" 0x0000000000000000000000000000000000001010) "function balanceOf(address account) view returns(uint256)" \
$(cat rootchain-wallet.json | jq -r '.ETHAddress') \
--rpc-url $(cat genesis.json | jq -r '.params.engine.polybft.bridge.jsonRPCEndpoint')

# check sender balance - this will go up after withdraw
cast balance $(cat genesis.json | jq -r '.params.engine.polybft.initialValidatorSet[0].address') --rpc-url localhost:10002

```
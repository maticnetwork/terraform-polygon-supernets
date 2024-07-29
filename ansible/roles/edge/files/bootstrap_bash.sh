#!/bin/bash -x

# Set environment variables
export CLEAN_DEPLOY_TITLE="devnet13"
export BLOCK_GAS_LIMIT=50000000
export BLOCK_TIME=5s
export CHAIN
export POLYCLI_TAG="0.1.30"
export EDGE_TAG="761bc2231156ffa1445eb85cbdefec1a87544f65"
export GETH_TAG="v1.12.0"
export GO_TAG="1.20.7.linux-amd64"
export ROOTCHAIN_STAKE_TOKEN_FUND_AMOUNT="2ether"
export ROOTCHAIN_DEPLOYER_FUND_AMOUNT="10ether"
export ROOTCHAIN_VALIDATOR_FUND_AMOUNT="2ether"
export ROOTCHAIN_VALIDATOR_CONVERT_AMOUNT_ETHER="1ether"
export ROOTCHAIN_JSON_RPC="https://holesky.infura.io/v3/39bbce1963cb476aab6d41fdd4303985"
export FUND_ROOTCHAIN_COINBASE=false
export ROOTCHAIN_COINBASE_ADDRESS="0xA8A4f31fF1445dA283aC3624430c954A13D4675d"
export ROOTCHAIN_COINBASE_PRIVATE_KEY="5bb82c5bd87bdef1c1262ea18f51eb60a99af46519b477c09e933b72995f8b74"
export STAKE_TOKEN_ADDRESS="0xd9b2df73f87719f986fbbe4b956c1331d84389e9"
export IS_STAKE_TOKEN_ERC_20=true
export IS_DEPLOY_STAKE_TOKEN_ERC20=false
export NATIVE_TOKEN_CONFIG="BBBStakeToken:BBBSTK:18:true"
export BASE_DN="${CLEAN_DEPLOY_TITLE}.edge.polygon.private"
export COINBASE_ADDRESS="0xA8A4f31fF1445dA283aC3624430c954A13D4675d"

main() {
    if [[ -d "/var/lib/bootstrap" ]]; then
        echo "It appears this network has already been boot strapped"
        exit
    fi
    mkdir /var/lib/bootstrap
    pushd /var/lib/bootstrap

    # Replace this with your actual host variables logic
    # Example: declare -A hostvars=(["host1"]="fullnode" ["host2"]="validator")
    declare -A hostvars=(["host1"]="fullnode" ["host2"]="validator")

    for item in "${!hostvars[@]}"; do
        role="${hostvars[$item]}"
        if [[ "$role" == "fullnode" || "$role" == "validator" ]]; then
            polygon-edge polybft-secrets --data-dir "$item" --json --insecure > "${item}.json"
        fi
    done

    apt update
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    apt-get install -y nodejs

    pushd /opt/polygon-edge/
    make compile-core-contracts
    cp -r /opt/polygon-edge/core-contracts /var/lib/bootstrap/core-contracts/
    popd

    BURN_CONTRACT_ADDRESS=0x0000000000000000000000000000000000000000
    BALANCE=0x0

    polycli wallet create --words 12 --language english | jq '.Addresses[0]' > rootchain-wallet.json

    # Should the deployer be funded from an unlocked L1 chain or from a prefunded account on L1
    if [ "$FUND_ROOTCHAIN_COINBASE" = true ]; then
        COINBASE_ADDRESS=$(cast rpc --rpc-url $ROOTCHAIN_JSON_RPC eth_coinbase | sed 's/"//g')
        cast send --rpc-url $ROOTCHAIN_JSON_RPC --from $COINBASE_ADDRESS --value $ROOTCHAIN_DEPLOYER_FUND_AMOUNT $(cat rootchain-wallet.json | jq -r '.ETHAddress') --unlocked
    else
        cast send --rpc-url $ROOTCHAIN_JSON_RPC --from $ROOTCHAIN_COINBASE_ADDRESS --value $ROOTCHAIN_DEPLOYER_FUND_AMOUNT $(cat rootchain-wallet.json | jq -r '.ETHAddress') --private-key $ROOTCHAIN_COINBASE_PRIVATE_KEY
    fi

    if [ "$IS_DEPLOY_STAKE_TOKEN_ERC20" = true ]; then
        echo "Deploying MockERC20 (Stake Token) contract"
        cast send --from $(cat rootchain-wallet.json | jq -r '.ETHAddress') \
            --private-key $(cat rootchain-wallet.json | jq -r '.HexPrivateKey') \
            --rpc-url $ROOTCHAIN_JSON_RPC -j --create \
            "$(jq -r '.bytecode' ./core-contracts/artifacts/contracts/mocks/MockERC20.sol/MockERC20.json)" > MockStakeTokenERC20.json

        cast send $(cat MockStakeTokenERC20.json | jq -r '.contractAddress') "function mint(address to, uint256 amount) returns()" $(cat rootchain-wallet.json | jq -r '.ETHAddress') $ROOTCHAIN_STAKE_TOKEN_FUND_AMOUNT \
        --rpc-url $ROOTCHAIN_JSON_RPC \
        --private-key $(cat rootchain-wallet.json | jq -r '.HexPrivateKey')
    fi

    # Constructing genesis
    polygon-edge genesis \
                 --consensus polybft \
                 --chain-id $CHAIN_ID \
                 --premine $BURN_CONTRACT_ADDRESS \
                 --reward-wallet 0x0101010101010101010101010101010101010101:1000000000000000000000000000 \
                 --block-gas-limit $BLOCK_GAS_LIMIT \
                 --block-time $BLOCK_TIME

    # Continue with the deployment process
    polygon-edge polybft stake-manager-deploy \
        --jsonrpc $ROOTCHAIN_JSON_RPC \
        --private-key $(cat rootchain-wallet.json | jq -r '.HexPrivateKey')

    polygon-edge rootchain deploy \
                 --stake-manager $(cat genesis.json | jq -r '.params.engine.polybft.bridge.stakeManagerAddr') \
                 --stake-token $(cat genesis.json | jq -r '.params.engine.polybft.bridge.stakeTokenAddr') \
                 --json-rpc $ROOTCHAIN_JSON_RPC \
                 --deployer-key $(cat rootchain-wallet.json | jq -r '.HexPrivateKey')

    counter=1
    for item in "${!hostvars[@]}"; do
        role="${hostvars[$item]}"
        if [[ "$role" == "validator" ]]; then
            echo "Registering validator: ${counter}"
            polygon-edge polybft register-validator \
                         --data-dir "$item" \
                         --supernet-manager $(cat genesis.json | jq -r '.params.engine.polybft.bridge.customSupernetManagerAddr') \
                         --jsonrpc $ROOTCHAIN_JSON_RPC

            cast send --private-key $(cat "$item"/consensus/validator.key) \
                 --rpc-url $ROOTCHAIN_JSON_RPC -j \
                 $(cat genesis.json | jq -r '.params.engine.polybft.bridge.stakeTokenAddr') \
                 'function approve(address spender, uint256 amount) returns(bool)' \
                 $(cat genesis.json | jq -r '.params.engine.polybft.bridge.stakeManagerAddr') \
                 $ROOTCHAIN_VALIDATOR_CONVERT_AMOUNT_ETHER

            polygon-edge polybft stake \
                         --data-dir "$item" \
                         --amount $ROOTCHAIN_VALIDATOR_CONVERT_AMOUNT_ETHER \
                         --supernet-id $(cat genesis.json | jq -r '.params.engine.polybft.supernetID') \
                         --stake-manager $(cat genesis.json | jq -r '.params.engine.polybft.bridge.stakeManagerAddr') \
                         --stake-token $(cat genesis.json | jq -r '.params.engine.polybft.bridge.stakeTokenAddr') \
                         --jsonrpc $ROOTCHAIN_JSON_RPC

            ((counter++))
        fi
    done

    polygon-edge polybft supernet \
                 --private-key $(cat rootchain-wallet.json | jq -r '.HexPrivateKey') \
                 --supernet-manager $(cat genesis.json | jq -r '.params.engine.polybft.bridge.customSupernetManagerAddr') \
                 --finalize-genesis-set \
                 --enable-staking \
                 --jsonrpc $ROOTCHAIN_JSON_RPC

    tar czf $BASE_DN.tar.gz *.json *.private
    popd
}

main

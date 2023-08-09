#!/bin/bash -x

main() {
    if [[ -d "/var/lib/bootstrap" ]]; then
        echo "It appears this network has already been boot strapped"
        exit
    fi
    mkdir /var/lib/bootstrap
    pushd /var/lib/bootstrap

{% for item in hostvars %}
{% if (hostvars[item].tags.Role == "fullnode" or hostvars[item].tags.Role == "validator") %}
    polygon-edge polybft-secrets --data-dir {{ hostvars[item].tags["Name"] }} --json --insecure > {{ hostvars[item].tags["Name"] }}.json
{% endif %}
{% endfor %}

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
    {% if (not fund_rootchain_coinbase) %}# {% endif %}COINBASE_ADDRESS=$(cast rpc --rpc-url {{ rootchain_json_rpc }} eth_coinbase | sed 's/"//g')
    {% if (not fund_rootchain_coinbase) %}# {% endif %}cast send --rpc-url {{ rootchain_json_rpc }} --from $COINBASE_ADDRESS --value {{ rootchain_deployer_fund_amount }} $(cat rootchain-wallet.json | jq -r '.ETHAddress') --unlocked
    # {% if (fund_rootchain_coinbase) %}# {% endif %}cast send --rpc-url {{ rootchain_json_rpc }} --from {{ rootchain_coinbase_address }} --value {{ rootchain_deployer_fund_amount }} $(cat rootchain-wallet.json | jq -r '.ETHAddress') --private-key {{ rootchain_coinbase_private_key }}
    {% if (fund_rootchain_coinbase) %}# {% endif %}mv ../edge/rootchain-wallet.json ./rootchain-wallet.json

{% if (is_deploy_stake_token_erc20) %}
    echo "Deploying MockERC20 (Stake Token) contract"
    cast send --from $(cat rootchain-wallet.json | jq -r '.ETHAddress') \
         --private-key $(cat rootchain-wallet.json | jq -r '.HexPrivateKey') \
         --rpc-url {{ rootchain_json_rpc }} -j --create \
         "$(jq -r '.bytecode' ./core-contracts/artifacts/contracts/mocks/MockERC20.sol/MockERC20.json)" > MockStakeTokenERC20.json

    cast send $(cat MockStakeTokenERC20.json | jq -r '.contractAddress') "function mint(address to, uint256 amount) returns()" $(cat rootchain-wallet.json | jq -r '.ETHAddress') {{ rootchain_stake_token_fund_amount }} \
    --rpc-url {{ rootchain_json_rpc }} \
    --private-key $(cat rootchain-wallet.json | jq -r '.HexPrivateKey')
{% endif %}

    polygon-edge genesis \
                 --consensus polybft \
                 --chain-id {{ chain_id }} \
                 {% for item in hostvars %}{% if (hostvars[item].tags.Role == "fullnode" or hostvars[item].tags.Role == "validator") %} --bootnode /dns4/{{ hostvars[item].tags["Name"] }}/tcp/{{ edge_p2p_port }}/p2p/$(cat {{ hostvars[item].tags["Name"] }}.json | jq -r '.[0].node_id') {% endif %}{% endfor %} \
                 {% for item in hostvars %}{% if (hostvars[item].tags.Role == "fullnode" or hostvars[item].tags.Role == "validator") %} --premine $(cat {{ hostvars[item].tags["Name"] }}.json | jq -r '.[0].address'):1000000000000000000000000 {% endif %}{% endfor %} \
                 --premine {{ loadtest_account }}:1000000000000000000000000000 \
                 --premine $BURN_CONTRACT_ADDRESS \
{% if (enable_eip_1559) %}
                 --burn-contract 0:$BURN_CONTRACT_ADDRESS \
{% endif %}
                 --reward-wallet 0x0101010101010101010101010101010101010101:1000000000000000000000000000 \
                 --block-gas-limit {{ block_gas_limit }} \
                 --block-time {{ block_time }}s \
                 {% for item in hostvars %}{% if (hostvars[item].tags.Role == "validator") %} --validators /dns4/{{ hostvars[item].tags["Name"] }}/tcp/{{ edge_p2p_port }}/p2p/$(cat {{ hostvars[item].tags["Name"] }}.json | jq -r '.[0].node_id'):$(cat {{ hostvars[item].tags["Name"] }}.json | jq -r '.[0].address' | sed 's/^0x//'):$(cat {{ hostvars[item].tags["Name"] }}.json | jq -r '.[0].bls_pubkey') {% endif %}{% endfor %} \
                 --epoch-size 10 \
                 --native-token-config {{ native_token_config }}:$(cat rootchain-wallet.json | jq -r '.ETHAddress')

    polygon-edge polybft stake-manager-deploy \
        --jsonrpc {{ rootchain_json_rpc }} \
        --private-key $(cat rootchain-wallet.json | jq -r '.HexPrivateKey') \
{% if (is_deploy_stake_token_erc20) %}
        --stake-token $(cat MockStakeTokenERC20.json | jq -r '.contractAddress')
{% else %}
        --stake-token {{ stake_token_address }}
{% endif %}

    polygon-edge rootchain deploy \
                 --stake-manager $(cat genesis.json | jq -r '.params.engine.polybft.bridge.stakeManagerAddr') \
                 --stake-token $(cat genesis.json | jq -r '.params.engine.polybft.bridge.stakeTokenAddr') \
                 --json-rpc {{ rootchain_json_rpc }} \
                 --deployer-key $(cat rootchain-wallet.json | jq -r '.HexPrivateKey')

{% for item in hostvars %}
{% if (hostvars[item].tags.Role == "validator") %}
    cast send --rpc-url {{ rootchain_json_rpc }} --from $(cat rootchain-wallet.json | jq -r '.ETHAddress') --private-key $(cat rootchain-wallet.json | jq -r '.HexPrivateKey') \
         --value {{ rootchain_validator_fund_amount }} $(cat {{ hostvars[item].tags["Name"] }}.json | jq -r '.[0].address')

    {% if (is_stake_token_erc_20) %}
    cast send $(cat genesis.json | jq -r '.params.engine.polybft.bridge.stakeTokenAddr') "function mint(address to, uint256 amount) returns()" $(cat {{ hostvars[item].tags["Name"] }}.json | jq -r '.[0].address') {{ rootchain_validator_convert_amount_ether }}ether \
    --rpc-url {{ rootchain_json_rpc }} \
    --private-key $(cat rootchain-wallet.json | jq -r '.HexPrivateKey')
    {% else %}
    cast send \
    --private-key $(cat {{ hostvars[item].tags["Name"] }}/consensus/validator.key) \
    --rpc-url {{ rootchain_json_rpc }} \
    --value {{ rootchain_validator_convert_amount_ether }}ether $(cat genesis.json | jq -r '.params.engine.polybft.bridge.stakeTokenAddr')
    {% endif %}

{% endif %}
{% endfor %}

     polygon-edge polybft whitelist-validators \
                  --private-key $(cat rootchain-wallet.json | jq -r '.HexPrivateKey') \
                  --addresses $(cat validator-*.json | jq -r ".[].address" | paste -sd "," - | tr -d '\n') \
                  --supernet-manager $(cat genesis.json | jq -r '.params.engine.polybft.bridge.customSupernetManagerAddr') \
                  --jsonrpc {{ rootchain_json_rpc }}

{% set conversion_rate = 10 ** 18 %}
{% set rootchain_validator_convert_amount_wei = (rootchain_validator_convert_amount_ether * conversion_rate) | int %}

    counter=1
{% for item in hostvars %}
{% if (hostvars[item].tags.Role == "validator") %}
    echo "Registering validator: ${counter}"

    polygon-edge polybft register-validator \
                 --data-dir {{ hostvars[item].tags["Name"] }} \
                 --supernet-manager $(cat genesis.json | jq -r '.params.engine.polybft.bridge.customSupernetManagerAddr') \
                 --jsonrpc {{ rootchain_json_rpc }}

    cast send --private-key $(cat {{ hostvars[item].tags["Name"] }}/consensus/validator.key) \
         --rpc-url {{ rootchain_json_rpc }} -j \
         $(cat genesis.json | jq -r '.params.engine.polybft.bridge.stakeTokenAddr') \
         'function approve(address spender, uint256 amount) returns(bool)' \
         $(cat genesis.json | jq -r '.params.engine.polybft.bridge.stakeManagerAddr') \
         {{ rootchain_validator_convert_amount_wei }}

    # 1000000000000000000 should be whatever "0.1 ether is - dynamic"
    polygon-edge polybft stake \
                 --data-dir {{ hostvars[item].tags["Name"] }} \
                 --amount {{ rootchain_validator_convert_amount_wei }} \
                 --supernet-id $(cat genesis.json | jq -r '.params.engine.polybft.supernetID') \
                 --stake-manager $(cat genesis.json | jq -r '.params.engine.polybft.bridge.stakeManagerAddr') \
                 --stake-token $(cat genesis.json | jq -r '.params.engine.polybft.bridge.stakeTokenAddr') \
                 --jsonrpc {{ rootchain_json_rpc }}

    ((counter++))
{% endif %}
{% endfor %}

{% for item in hostvars %}
{% if (hostvars[item].tags.Role == "validator") %}
{% endif %}
{% endfor %}

    polygon-edge polybft supernet \
                 --private-key $(cat rootchain-wallet.json | jq -r '.HexPrivateKey') \
                 --supernet-manager $(cat genesis.json | jq -r '.params.engine.polybft.bridge.customSupernetManagerAddr') \
                 --stake-manager $(cat genesis.json | jq -r '.params.engine.polybft.bridge.stakeManagerAddr') \
                 --finalize-genesis-set \
                 --enable-staking \
                 --jsonrpc {{ rootchain_json_rpc }}

    tar czf {{ base_dn }}.tar.gz *.json *.private
    popd
}

main

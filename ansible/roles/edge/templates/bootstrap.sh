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

    polygon-edge genesis \
                 --consensus polybft \
                 --chain-id {{ chain_id }} \
                 {% for item in hostvars %}{% if (hostvars[item].tags.Role == "fullnode" or hostvars[item].tags.Role == "validator") %} --bootnode /dns4/{{ hostvars[item].tags["Name"] }}/tcp/{{ edge_p2p_port }}/p2p/$(cat {{ hostvars[item].tags["Name"] }}.json | jq -r '.[0].node_id') {% endif %}{% endfor %} \
                 {% for item in hostvars %}{% if (hostvars[item].tags.Role == "fullnode" or hostvars[item].tags.Role == "validator") %} --premine $(cat {{ hostvars[item].tags["Name"] }}.json | jq -r '.[0].address'):1000000000000000000000000 {% endif %}{% endfor %} \
                 --premine {{ loadtest_account }}:1000000000000000000000000000 \
                 --premine $BURN_CONTRACT_ADDRESS \
                 --burn-contract 0:$BURN_CONTRACT_ADDRESS \
                 --reward-wallet 0x0101010101010101010101010101010101010101:1000000000000000000000000000 \
                 --block-gas-limit {{ block_gas_limit }} \
                 --block-time {{ block_time }}s \
                 {% for item in hostvars %}{% if (hostvars[item].tags.Role == "validator") %} --validators /dns4/{{ hostvars[item].tags["Name"] }}/tcp/{{ edge_p2p_port }}/p2p/$(cat {{ hostvars[item].tags["Name"] }}.json | jq -r '.[0].node_id'):$(cat {{ hostvars[item].tags["Name"] }}.json | jq -r '.[0].address' | sed 's/^0x//'):$(cat {{ hostvars[item].tags["Name"] }}.json | jq -r '.[0].bls_pubkey') {% endif %}{% endfor %} \
                 --epoch-size 10 \
                 --native-token-config {{ native_token_config }}

{% if (enable_eip_1559) %}
    # EIP-1559
    jq --argjson code $(cat /var/lib/bootstrap/core-contracts/artifacts/contracts/child/EIP1559Burn.sol/EIP1559Burn.json | jq '.deployedBytecode')  \
       --arg balance "$BALANCE" \
       --arg addr "$BURN_CONTRACT_ADDRESS" \
       '.genesis.alloc += {($addr): {"code": $code, "balance": $balance}}' \
       genesis.json | jq . > tmp.json && mv tmp.json genesis.json
{% endif %}

    polycli wallet create --words 12 --language english | jq '.Addresses[0]' > rootchain-wallet.json

    # Should the deployer be funded from an unlocked L1 chain or from a prefunded account on L1
    {% if (not fund_rootchain_coinbase) %}# {% endif %}COINBASE_ADDRESS=$(cast rpc --rpc-url {{ rootchain_json_rpc }} eth_coinbase | sed 's/"//g')
    {% if (not fund_rootchain_coinbase) %}# {% endif %}cast send --rpc-url {{ rootchain_json_rpc }} --from $COINBASE_ADDRESS --value {{ rootchain_deployer_fund_amount }} $(cat rootchain-wallet.json | jq -r '.ETHAddress') --unlocked
    {% if (fund_rootchain_coinbase) %}# {% endif %}cast send --rpc-url {{ rootchain_json_rpc }} --from {{ rootchain_coinbase_address }} --value {{ rootchain_deployer_fund_amount }} $(cat rootchain-wallet.json | jq -r '.ETHAddress') --private-key {{ rootchain_coinbase_private_key }}

    polygon-edge polybft stake-manager-deploy \
        --jsonrpc {{ rootchain_json_rpc }} \
        --test

    #    --private-key $(cat rootchain-wallet.json | jq -r '.HexPrivateKey')

    polygon-edge rootchain deploy \
                 --stake-manager $(cat genesis.json | jq -r '.params.engine.polybft.bridge.stakeManagerAddr') \
                 --stake-token $(cat genesis.json | jq -r '.params.engine.polybft.bridge.stakeTokenAddr') \
                 --json-rpc {{ rootchain_json_rpc }} \
                 --test

    #             --deployer-key $(cat rootchain-wallet.json | jq -r '.HexPrivateKey') \

    polygon-edge rootchain fund \
                --stake-token $(cat genesis.json | jq -r '.params.engine.polybft.bridge.stakeTokenAddr') \
                --mint \
                --addresses $(cat validator-*.json | jq -r ".[].address" | paste -sd "," - | tr -d '\n') \
                --amounts $(for f in validator-*.json; do echo -n "1000000000000000000000000,"; done | sed 's/,$//') \
                --json-rpc {{ rootchain_json_rpc }}

    #            --private-key $(cat rootchain-wallet.json | jq -r '.HexPrivateKey')

     polygon-edge polybft whitelist-validators \
                  --private-key aa75e9a7d427efc732f8e4f1a5b7646adcc61fd5bae40f80d13c8419c9f43d6d \
                  --addresses $(cat validator-*.json | jq -r ".[].address" | paste -sd "," - | tr -d '\n') \
                  --supernet-manager $(cat genesis.json | jq -r '.params.engine.polybft.bridge.customSupernetManagerAddr') \
                  --jsonrpc {{ rootchain_json_rpc }}

    #              --private-key $(cat rootchain-wallet.json | jq -r '.HexPrivateKey') \

    counter=1
{% for item in hostvars %}
{% if (hostvars[item].tags.Role == "validator") %}
    echo "Registering validator: ${counter}"

    polygon-edge polybft register-validator \
                 --data-dir {{ hostvars[item].tags["Name"] }} \
                 --supernet-manager $(cat genesis.json | jq -r '.params.engine.polybft.bridge.customSupernetManagerAddr') \
                 --jsonrpc {{ rootchain_json_rpc }}

    polygon-edge polybft stake \
                 --data-dir {{ hostvars[item].tags["Name"] }} \
                 --amount 1000000000000000000000000 \
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
                 --private-key aa75e9a7d427efc732f8e4f1a5b7646adcc61fd5bae40f80d13c8419c9f43d6d \
                 --supernet-manager $(cat genesis.json | jq -r '.params.engine.polybft.bridge.customSupernetManagerAddr') \
                 --stake-manager $(cat genesis.json | jq -r '.params.engine.polybft.bridge.stakeManagerAddr') \
                 --finalize-genesis-set \
                 --enable-staking \
                 --jsonrpc {{ rootchain_json_rpc }}

    #             --private-key $(cat rootchain-wallet.json | jq -r '.HexPrivateKey') \

    tar czf {{ base_dn }}.tar.gz *.json *.private
    popd
}

main

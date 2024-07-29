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

    #Should the deployer be funded from an unlocked L1 chain or from a prefunded account on L1
    cast send --rpc-url {{ rootchain_json_rpc }} --from {{ rootchain_coinbase_address }} --value {{ rootchain_deployer_fund_amount }} $(cat rootchain-wallet.json | jq -r '.ETHAddress') --private-key {{ rootchain_coinbase_private_key }}

    polygon-edge genesis \
                 --consensus polybft \
                 --chain-id {{ chain_id }} \
                 --reward-wallet {{ rootchain_coinbase_address }} \
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
                 --native-token-config {{ native_token_config }}:{{ rootchain_coinbase_address }}

    polygon-edge polybft stake-manager-deploy \
        --jsonrpc {{ rootchain_json_rpc }} \
        --private-key $(cat rootchain-wallet.json | jq -r '.HexPrivateKey') \
        --stake-token {{ stake_token_address }}

    polygon-edge rootchain deploy \
                 --stake-manager $(cat genesis.json | jq -r '.params.engine.polybft.bridge.stakeManagerAddr') \
                 --stake-token {{ stake_token_address }} \
                 --json-rpc {{ rootchain_json_rpc }} \
                 --deployer-key $(cat rootchain-wallet.json | jq -r '.HexPrivateKey')

{% for item in hostvars %} 
{% if (hostvars[item].tags.Role == "validator") %}
    cast send --rpc-url {{ rootchain_json_rpc }} --from $(cat rootchain-wallet.json | jq -r '.ETHAddress') --private-key $(cat rootchain-wallet.json | jq -r '.HexPrivateKey') \
         --value {{ rootchain_validator_fund_amount }} $(cat {{ hostvars[item].tags["Name"] }}.json | jq -r '.[0].address')

    # Call ERC20 transfer instead of minting
    cast send {{ stake_token_address }} "function transfer(address to, uint256 amount) returns(bool)" $(cat {{ hostvars[item].tags["Name"] }}.json | jq -r '.[0].address') {{ rootchain_validator_convert_amount_ether }}ether \
    --rpc-url {{ rootchain_json_rpc }} \
    --private-key {{ rootchain_coinbase_private_key }}

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
         {{stake_token_address}} \
         'function approve(address spender, uint256 amount) returns(bool)' \
         $(cat genesis.json | jq -r '.params.engine.polybft.bridge.stakeManagerAddr') \
         {{ rootchain_validator_convert_amount_wei }}

    polygon-edge polybft stake \
                 --data-dir {{ hostvars[item].tags["Name"] }} \
                 --amount {{ rootchain_validator_convert_amount_wei }} \
                 --supernet-id $(cat genesis.json | jq -r '.params.engine.polybft.supernetID') \
                 --stake-manager $(cat genesis.json | jq -r '.params.engine.polybft.bridge.stakeManagerAddr') \
                 --stake-token {{stake_token_address}} \
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
                 --finalize-genesis-set \
                 --enable-staking \
                 --jsonrpc {{ rootchain_json_rpc }}

    tar czf {{ base_dn }}.tar.gz *.json *.private
    popd
}

main


polygon-edge polybft supernet --private-key f21a4aaaa55e6382e98b60536e55cde9c928a76780308c39135bdf6ae9c2c2b6 --supernet-manager 0x09b00EFba6507D4498957e5D3256e01D5862C2F6 --finalize-genesis-set --enable-staking --jsonrpc http://10.10.67.79:8545
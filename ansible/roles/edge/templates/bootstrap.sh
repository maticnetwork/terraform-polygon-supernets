#!/bin/bash

main() {
    if [[ -d "/var/lib/bootstrap" ]]; then
        echo "It appears this network has already been boot strapped"
        exit
    fi
    mkdir /var/lib/bootstrap
    pushd /var/lib/bootstrap

{% for item in hostvars %}
{% if (hostvars[item].tags.Role == "fullnode" or hostvars[item].tags.Role == "validator") %}
    polygon-edge polybft-secrets init --data-dir {{ hostvars[item].tags["Name"] }} \
    --chain-id {{ chain_id }} \
    --json \
    --insecure > {{ hostvars[item].tags["Name"] }}.json
{% endif %}
{% endfor %}

 polygon-edge manifest {% for item in hostvars %}{% if (hostvars[item].tags.Role == "validator") %} --validators /dns4/{{ hostvars[item].tags["Name"] }}/tcp/{{ edge_p2p_port }}/p2p/$(cat {{ hostvars[item].tags["Name"] }}.json | jq -r '.[0].node_id'):$(cat {{ hostvars[item].tags["Name"] }}.json | jq -r '.[0].address'):$(cat {{ hostvars[item].tags["Name"] }}.json | jq -r '.[0].bls_pubkey'):$(cat {{ hostvars[item].tags["Name"] }}.json | jq -r '.[0].bls_signature') {% endif %}{% endfor %} \
                 --path ./manifest.json \
                 --premine-validators 1000000000000000000000000000 \
                 --chain-id  {{ chain_id }}

    mkdir rootchain-secrets
    pushd rootchain-secrets
    mkdir consensus
    pushd consensus
    touch validator.key
    echo -n "" > validator.key
    popd
    popd

    polygon-edge rootchain init-contracts \
      --data-dir ./rootchain-secrets \
      --json-rpc https://polygon-mumbai.g.alchemy.com/v2/

    LATEST_BLOCK=$(curl -H "Content-Type: application/json" -X POST --data '{"jsonrpc":"2.0","method":"eth_blockNumber", "params": [""]}' https://polygon-mumbai.g.alchemy.com/v2/ | jq -r '.result')

    polygon-edge genesis \
                 --consensus polybft \
                 --bridge-json-rpc https://polygon-mumbai.g.alchemy.com/v2/ \
                 {% for item in hostvars %}{% if (hostvars[item].tags.Role == "fullnode" or hostvars[item].tags.Role == "validator") %} --bootnode /dns4/{{ hostvars[item].tags["Name"] }}/tcp/{{ edge_p2p_port }}/p2p/$(cat {{ hostvars[item].tags["Name"] }}.json | jq -r '.[0].node_id') {% endif %}{% endfor %} \
                 --premine {{ loadtest_account }}:1000000000000000000000000000 \
                 --premine 0x0000000000000000000000000000000000000000 \  # do not delete this line (for bridge use)
                 --tracker-start-blocks $(cat manifest.json | jq -r '.rootchain.stateSenderAddress'):$(echo $(($LATEST_BLOCK))) \ # do not delete this line (for bridge use)
                 --block-gas-limit {{ block_gas_limit }} \
                 --block-time {{ block_time }}s \
                 --chain-id  {{ chain_id }}

    tar czf {{ base_dn }}.tar.gz validator* fullnode* genesis.json
    popd
}

main

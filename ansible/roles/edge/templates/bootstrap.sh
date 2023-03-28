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
    polygon-edge polybft-secrets init --data-dir {{ hostvars[item].tags["Name"] }} --chain-id {{ chain_id }} --json --insecure > {{ hostvars[item].tags["Name"] }}.json
{% endif %}
{% endfor %}

    polygon-edge manifest {% for item in hostvars %}{% if (hostvars[item].tags.Role == "validator") %} --validators $(cat {{ hostvars[item].tags["Name"] }}.json | jq -r '.[0].node_id'):$(cat {{ hostvars[item].tags["Name"] }}.json | jq -r '.[0].address'):$(cat {{ hostvars[item].tags["Name"] }}.json | jq -r '.[0].bls_pubkey'):$(cat {{ hostvars[item].tags["Name"] }}.json | jq -r '.[0].bls_signature') {% endif %}{% endfor %} \
                 --path ./manifest.json --premine-validators 1000000000000000000000000000

    polygon-edge genesis \
                 --consensus polybft \
                 {% for item in hostvars %}{% if (hostvars[item].tags.Role == "fullnode" or hostvars[item].tags.Role == "validator") %} --bootnode /dns4/{{ hostvars[item].tags["Name"] }}/tcp/{{ edge_p2p_port }}/p2p/$(cat {{ hostvars[item].tags["Name"] }}.json | jq -r '.[0].node_id') {% endif %}{% endfor %} \
                 {% for item in hostvars %}{% if (hostvars[item].tags.Role == "fullnode" or hostvars[item].tags.Role == "validator") %} --premine $(cat {{ hostvars[item].tags["Name"] }}.json | jq -r '.[0].address'):1000000000000000000000000 {% endif %}{% endfor %} \
                 --premine {{ loadtest_account }}:1000000000000000000000000000 \
		         --block-gas-limit {{ block_gas_limit }} --block-time {{ block_time }}s \
                 --chain-id  {{ chain_id }}

    tar czf {{ base_dn }}.tar.gz validator* fullnode* genesis.json
    popd
}

main

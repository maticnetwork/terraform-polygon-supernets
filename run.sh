terraform init
terraform plan
terraform apply -auto-approve

terraform output pk_ansible > ~/cert/devnet_private.key
ROOTCHAIN_RPC=$(terraform output -raw geth_private_ip)

cd ansible
echo -n "viable decrease resist spoil loop vocal foot only become glass satisfy dog pull junior jaguar maple entry donate panel slow innocent try movie snake" > password.txt
cp local-extra-vars.yml.template local-extra-vars.yml
echo "rootchain_json_rpc: http://$ROOTCHAIN_RPC:8545" >> local-extra-vars.yml

ansible --inventory inventory/aws_ec2.yml --vault-password-file=password.txt --extra-vars "@local-extra-vars.yml" all -m ping
ansible-playbook --inventory inventory/aws_ec2.yml --vault-password-file=password.txt --extra-vars "@local-extra-vars.yml" site.yml

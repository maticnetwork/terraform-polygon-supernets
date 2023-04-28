### Creating resources with Terraform
terraform init
terraform plan
terraform apply -auto-approve

### Output the private key for instances
terraform output pk_ansible > ~/devnet_private.key
chmod 600 ~/devnet_private.key 
eval "$(ssh-agent)"
ssh-add ~/devnet_private.key

### Save the rootchain rpc address
ROOTCHAIN_RPC=$(terraform output -raw geth_private_ip)

cd ansible
### Set ansible vault password
echo "viable decrease resist spoil loop vocal foot only become glass satisfy dog pull junior jaguar maple entry donate panel slow innocent try movie snake" > password.txt
### Create variable file from template
cp local-extra-vars.yml.template local-extra-vars.yml
### Add rootchain rpc address to the variable file
echo "\nrootchain_json_rpc: http://$ROOTCHAIN_RPC:8545" >> local-extra-vars.yml

### Run ansible to configure the nodes
ansible --inventory inventory/aws_ec2.yml --vault-password-file=password.txt --extra-vars "@local-extra-vars.yml" all -m ping
ansible-galaxy install -r requirements.yml
# if this step fails due to "sudo: a password is required", make sure you are in sudo mode in the terminal you are running this on
ansible-playbook --inventory inventory/aws_ec2.yml --vault-password-file=password.txt --extra-vars "@local-extra-vars.yml" site.yml

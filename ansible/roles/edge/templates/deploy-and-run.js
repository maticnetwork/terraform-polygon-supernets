import Web3 from 'web3';
import fs from 'fs/promises';

const data = JSON.parse(await fs.readFile('/var/lib/bootstrap/core-contracts/artifacts/contracts/mocks/MockERC20.sol/MockERC20.json', { encoding: 'utf8' }));

const web3 = new Web3('{{ rootchain_json_rpc }}')

const loadtestAccount = web3.eth.accounts.privateKeyToAccount('0x' + process.env.PRIVATE_KEY)
console.log(loadtestAccount)

const addedAccount = web3.eth.accounts.wallet.add(loadtestAccount);
console.log('addedAccount', addedAccount);

var contract = new web3.eth.Contract(data.abi, process.env.NATIVE_ERC20_ADDR); // provide a correct address here
console.log('contract', contract);

// value wasn't correct, because we are providing ether value and convert it into Wei
// so if we want to convert 1000 ether to wei, just put 1000 (instead of 10^21) :) 
const mint = await contract.methods.mint(loadtestAccount.address, web3.utils.toWei('1000', 'ether')).send({
  gas: 10000000,
  from: loadtestAccount.address
})
console.log('mint', mint)
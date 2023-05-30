# Load Testing

`polycli` assumes that the address `0x85dA99c8a7C2C95964c8EfD687E95E632Fc533D6` has been premined with
enough value to do the load test. If you'd like to use a different key
when generating the load, the argument `--private-key` can be used to
specify another private key for running the load test.
```
# Send EOA transactions
polycli loadtest --chain-id 100 --verbosity 700 --mode t --concurrency 250 --requests 120 --rate-limit 1900 --to-random=false --summarize=true http://127.0.0.1:10222

# Send ERC 20 transfers
polycli loadtest --chain-id 100 --verbosity 700 --mode 2 --concurrency 250 --requests 200 --rate-limit 700 --to-random=false --summarize=true --send-amount 0x1 http://127.0.0.1:10222

# Send ERC 721 transfers
polycli loadtest --chain-id 100 --verbosity 700 --mode 7 --concurrency 250 --requests 120 --rate-limit 700 --to-random=false --summarize=true http://127.0.0.1:10222
```
At the end of each test a line will be printed like this:
```
11:32PM INF rough test summary (ignores errors) firstBlockTime=2023-03-15T23:32:25Z lastBlockTime=2023-03-15T23:32:46Z testDuration=21 tps=476.1904761904762 transactionCount=10000
```
This will give a sense of how long the process took and how many transactions per second were observed. It can be useful to observe the details of each block. The command `polycli monitor http://127.0.0.1:10222` can be used to
observe the blocks as their mined to look for any irregularities or unexpected behaviors in block production.
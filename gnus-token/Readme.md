## GNUS Token and ICO contract are integrated
### GNUS token Info
- Token name: Genius Tokens
- Token Symbol: GNUS
- 50 million limit - 7.38 million to owner's contract, 36.9 million in ICO, so only 5.72 million left to mint
### ICO Contracts for GNUS token with Ethereum
- Deposit ETH (Detect ETH and Amount)
- Send GNUS (Detect Receiver and Manage Balances)
- Widthraw ETH (Only Owner)
- ICO Logic
- ConvTable
```
50,000 Max ethereum with 36.9 million max GNUS
first 12,500 Ethereum = 12,500,000 GNUS = 1 ETH TO 1,000 GNUS
second 12,500 Ethereum = 10,000,000 GNUS = 1 ETH TO 800 GNUS
third 12,500 Ethereum = 8,000,000 GNUS = 1  ETH TO 640 GNUS
fourth 12,500 Ethreum = 6,400,000 GNUS = 1 ETH TO 512 GNUS
```
## Testing in Ganache and Rinkeby
- Contract Name: ICOContract
- address: [0xB65dBbb4952091E80590a60DB6136b5cFa3b7D3b](https://rinkeby.etherscan.io/address/0xB65dBbb4952091E80590a60DB6136b5cFa3b7D3b)

## Building and Testing.
Use `yarn generate` to generate the typescript files for the smart contract under build/types
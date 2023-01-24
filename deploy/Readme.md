### Deploy Dominion 

1. Install prerequisites: 

* Go 

* Ignite 

* Gcc 

* Dasel 


or run `./deploy/01-install.sh` from the project dir. 


2. Build dominion binary

```
ignite chain build --release

tar -xvf ./release/dominion_*_*.tar.gz

# copy the binary to somewhere where $PATH points to.
cp dominiond /usr/local/bin/

chmod a+x /usr/local/bin/dominiond
```

or run `./deploy/02-build.sh` 



3. Configure Node to Join the Testnet

* 
```
./deploy/03-generate-config.sh -c=<CHAIN-ID> -m=<MONIKER> -pva=<ADDRESS-OF-ONLINE-PEER>
dominiond start
```

#### Run Testnet on local machine using Docker.

* `./deploy/docker-compose.yml` allows to run a localnet on your machine.
* `docker compose -f deploy/docker-compose.yml up -d`
* `node0` is the primary validator to which rest of the node join.

* Additionally look at the `Dockerfile.*` in `deploy` dir, which shows how to use the above mentioned scripts to spin a node and join the network.


#### Connect with keplr 
use the following chain info to connect dominion chain to keplr
```
export const dominionChainInfo = {
	chainId: 'dominion',
	chainName: 'DOMINION Network',
	rpc: 'http://dominion-testnet-rest.webisoft.org:26657',
	rest: 'http://dominion-testnet-rest.webisoft.org:1317',
	stakeCurrency: {
		coinDenom: 'MINION',
		coinMinimalDenom: 'uminion',
		coinDecimals: 0,
	},
	bip44: {
		coinType: 118,
	},
	bech32Config: {
		bech32PrefixAccAddr: 'dom',
		bech32PrefixAccPub: 'dompub',
		bech32PrefixValAddr: 'domvaloper',
		bech32PrefixValPub: 'domvaloperpub',
		bech32PrefixConsAddr: 'domvalcons',
		bech32PrefixConsPub: 'domvalconspub',
	},
	currencies: [
		{
			coinDenom: 'MINION',
			coinMinimalDenom: 'uminion',
			coinDecimals: 6,
		},
	],
	feeCurrencies: [
		{
			coinDenom: 'MINION',
			coinMinimalDenom: 'uminion',
			coinDecimals: 6,
		},
	],
	coinType: 118,
	beta: true,
	features: ['cosmwasm'],
};
```





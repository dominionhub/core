#!/bin/sh
set -ex

# obtain moniker and chain_id from args
for i in "$@"; do
    case $i in
    -m=* | --moniker=*)
        MONIKER="${i#*=}"
        shift # past argument=value
        ;;
    -c=* | --chain_id=*)
        CHAIN_ID="${i#*=}"
        shift # past argument=value
        ;;
    # primary validator address to which this node will connect
    -pva=* | --primary_validator_address=*)
        PRIMARY_VALIDATOR_ADDRESS="${i#*=}"
        shift # past argument=value
        ;;
    *)
        # unknown option
        ;;
    esac
done

# all the arguments are required if not set, exit with error
if [ -z "$MONIKER" ] || [ -z "$CHAIN_ID" ] || [ -z "$PRIMARY_VALIDATOR_ADDRESS" ]; then
    echo "Missing required arguments"
    exit 1
fi

# get validator public key
VALIDATOR_PUBKEY=$(dominiond tendermint show-validator | dasel -r json .key | tr -d '"')

# using dominiond generate a create-validator transaction
dominiond tx staking create-validator \
  --amount=10000000000uminion \
  --pubkey=$VALIDATOR_PUBKEY \
  --chain-id=$CHAIN_ID \
  --moniker=$MONIKER \
  --commission-rate="0.10" \
  --commission-max-rate="0.20" \
  --commission-max-change-rate="0.01" \
  --min-self-delegation="1" \
  --gas="auto" \
  --gas-adjustment="1.5" \
  --gas-prices="0.025uminion" \
  --from=alice-beta \
  --keyring-backend test \
  --node="http://${PRIMARY_VALIDATOR_ADDRESS}:26657" \
  -y

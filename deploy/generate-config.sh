#!/bin/sh
set +ex

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
    # get list of cosmos sdk style accounts specified as a comma separated list from the command line
    -a=* | --accounts=*)
        ACCOUNTS="${i#*=}"
        shift # past argument=value
        ;;
    # flag to indicate whether this node is a primary validator
    -pv | --primary_validator)
        PRIMARY_VALIDATOR="true"
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

# if primary_validator and primary_validator_address are specified then error. Only one of these should be specified as they are mutually exclusive.
if [ ! -z "$PRIMARY_VALIDATOR" ] && [ ! -z "$PRIMARY_VALIDATOR_ADDRESS" ]; then
    echo "Error: primary_validator and primary_validator_address are mutually exclusive. Please specify only one of these."
    exit 1
fi

# set defaults if not specified
MONIKER=${MONIKER:-"primary-node"}
CHAIN_ID=${CHAIN_ID:-"dominion"}

dominiond init $MONIKER --chain-id $CHAIN_ID

# check if addresses are provided if yes then iterate over the list of accounts and add them to the genesis file,
# otherwise use the call a function to generate the default accounts.
if [ ! -z "$ACCOUNTS" ]; then
    echo "Adding accounts to genesis file"
    # iterate over the list of accounts and add them to the genesis file
    for account in $(echo $ACCOUNTS | sed "s/,/ /g"); do
        dominiond add-genesis-account $account 1000000000minion
    done
else
    echo "Generating default accounts"
    # generate default accounts
    # ## Setup an alice account
    export ALICE_TEXT=$(dominiond keys add --keyring-backend test alice)
    export ALICE_ACCOUNT=$(echo $ALICE_TEXT | grep address | awk '{ print $2 }')
    echo "ALICE_TEXT:"
    echo $ALICE_TEXT \n
    echo $ALICE_TEXT >> alice.txt

    # Setup a bob account
    export BOB_TEXT=$(dominiond keys add --keyring-backend test bob | grep address | awk '{ print $2 }')
    echo "BOB_TEXT:"
    echo $BOB_TEXT \n
    echo $BOB_TEXT >> bob.txt

    # Setup the genesis accounts with $$
    dominiond add-genesis-account $(dominiond keys show -a alice --keyring-backend test) 1000000000minion
    dominiond add-genesis-account $(dominiond keys show -a bob --keyring-backend test) 1000000000minion
fi

# Setup alice as the validator
dominiond gentx alice 1000000000000000stake --keyring-backend test --chain-id $CHAIN_ID

# collect the genesis transaction
dominiond collect-gentxs

# Echo the account addresses
echo "ALICE_ACCOUNT:"
echo $(dominiond keys show -a alice --keyring-backend test)
echo "BOB_ACCOUNT:"
echo $(dominiond keys show -a bob --keyring-backend test)

config_dir="$(realpath ~)/.dominion/config"
app_toml="$config_dir/app.toml"
config_toml="$config_dir/config.toml"

dasel put bool -f $app_toml api.enable true
dasel put string -f $app_toml api.address tcp://0.0.0.0:1317
dasel put string -f $app_toml minimum-gas-prices "0minion"
#dasel put bool -f $app_toml api.swagger true
#dasel put bool -f $app_toml grpc-web true
dasel put string -f $config_toml chain-id $CHAIN_ID
dasel put string -f $config_toml rpc.laddr tcp://0.0.0.0:26657

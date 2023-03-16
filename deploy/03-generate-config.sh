#!/bin/sh
set -ex

# arguments to this functions are moniker, chain-id.
create_primary_validator_config(){
  local MONIKER=$1
  local CHAIN_ID=$2

  dominiond init $MONIKER --chain-id $CHAIN_ID

  local config_dir="$(realpath ~)/.dominion/config"
  local genesis_json="$config_dir/genesis.json"
  local app_toml="$config_dir/app.toml"
  local config_toml="$config_dir/config.toml"

  # Change denoms to minion

  dasel put -t string -f $genesis_json 'app_state.staking.params.bond_denom' -v uminion
  dasel put -t string -f $genesis_json 'app_state.crisis.constant_fee.denom' -v uminion
  dasel put -t string -f $genesis_json 'app_state.gov.deposit_params.min_deposit.[0].denom' -v uminion
  dasel put -t string -f $genesis_json 'app_state.mint.params.mint_denom' -v uminion
  sed -i "s/\"stake\"/\"uminion\"/g" $genesis_json
  echo "Generating default accounts"
  # generate default accounts
  # Setup an alice account
  local ALICE_TEXT=$(dominiond keys add --keyring-backend test alice-alpha)
  local ALICE_ACCOUNT=$(echo $ALICE_TEXT | grep address | awk '{ print $2 }')
  echo "ALICE_TEXT:"
  echo $ALICE_TEXT \n
  echo $ALICE_TEXT >> alice.txt
  
  # Setup a bob account
  local BOB_TEXT=$(dominiond keys add --keyring-backend test bob-alpha | grep address | awk '{ print $2 }')
  echo "BOB_TEXT:"
  echo $BOB_TEXT \n
  echo $BOB_TEXT >> bob.txt
  
  # Setup the genesis accounts 
  dominiond add-genesis-account $(dominiond keys show -a alice-alpha --keyring-backend test) 10000000000000uminion
  dominiond add-genesis-account $(dominiond keys show -a bob-alpha --keyring-backend test) 10000000000000uminion
  
  # Setup alice as the validator
  dominiond gentx alice-alpha 10000000000uminion --keyring-backend test --chain-id $CHAIN_ID
  
  # collect the genesis transaction
  dominiond collect-gentxs
  
  # Echo the account addresses
  echo "ALICE_ACCOUNT:"
  echo $(dominiond keys show -a alice-alpha --keyring-backend test)
  echo "BOB_ACCOUNT:"
  echo $(dominiond keys show -a bob-alpha --keyring-backend test)
  
  dasel put -t bool -f $app_toml api.enable -v true
  dasel put -t bool -f $app_toml api.enabled-unsafe-cors -v true
  dasel put -t string -f $app_toml api.address -v tcp://0.0.0.0:1317
  dasel put -t string -f $app_toml minimum-gas-prices -v 0uminion
  #dasel put -t bool -f $app_toml api.swagger true
  #dasel put -t bool -f $app_toml grpc-web true
  dasel put -t string -f $config_toml  -s ".rpc.cors_allowed_origins.[]" -v '*'
  dasel put -t string -f $config_toml chain-id -v $CHAIN_ID
  dasel put -t string -f $config_toml rpc.laddr -v tcp://0.0.0.0:26657
}

create_validator_config(){ 
  local MONIKER=$1
  local CHAIN_ID=$2
  local PRIMARY_VALIDATOR_ADDR=$3

  dominiond init $MONIKER --chain-id $CHAIN_ID

  local config_dir="$(realpath ~)/.dominion/config"
  local genesis_json="$config_dir/genesis.json"
  local app_toml="$config_dir/app.toml"
  local config_toml="$config_dir/config.toml"

  echo "Generating default accounts"
  # generate default accounts
  # ## Setup an alice account
  local ALICE_TEXT=$(dominiond keys add --keyring-backend test alice-beta)
  local ALICE_ACCOUNT=$(echo $ALICE_TEXT | grep address | awk '{ print $2 }')
  echo "ALICE_TEXT: $ALICE_TEXT\n"
  echo $ALICE_TEXT >> alice.txt
  
  # Setup a bob account
  local BOB_TEXT=$(dominiond keys add --keyring-backend test bob-beta | grep address | awk '{ print $2 }')
  echo "BOB_TEXT: $BOB_TEXT\n"
  echo $BOB_TEXT >> bob.txt

  echo 'Waiting for primary node to come up.'
  until [ \
  "$(curl -s -w '%{http_code}' -o /dev/null "http://${PRIMARY_VALIDATOR_ADDR}:1317/node_info")" \
  -eq 200 ]
  do
    echo '.'
    sleep 2
  done
  echo 'Primary node is up.'
  export PRIMARY_VALIDATOR_ID=$(curl --retry 3 --retry-delay 5 -X GET "http://${PRIMARY_VALIDATOR_ADDR}:1317/node_info" -H "accept: application/json" \
  | dasel -r json ".node_info.id" | tr -d '"')
  curl "http://${PRIMARY_VALIDATOR_ADDR}:26657/genesis" | dasel -r json .result.genesis > ~/.dominion/config/genesis.json
  dasel put -t string -f $config_toml p2p.persistent_peers -v "${PRIMARY_VALIDATOR_ID}@${PRIMARY_VALIDATOR_ADDR}:26656"

  dasel put -t bool -f $app_toml api.enable -v true
  dasel put -t bool -f $app_toml api.enabled-unsafe-cors -v true
  dasel put -t string -f $app_toml api.address -v tcp://0.0.0.0:1317
  dasel put -t string -f $app_toml minimum-gas-prices -v 0uminion
  #dasel put -t bool -f $app_toml api.swagger true
  #dasel put -t bool -f $app_toml grpc-web true
  dasel put -t string -f $config_toml chain-id -v $CHAIN_ID
  dasel put -t string -f $config_toml rpc.laddr -v tcp://0.0.0.0:26657
}

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

# set defaults if not specified
MONIKER=${MONIKER:-"primary-node"}
CHAIN_ID=${CHAIN_ID:-"dominion"}

# if primary_validator and primary_validator_address are specified then error. Only one of these should be specified as they are mutually exclusive.
if [ ! -z "$PRIMARY_VALIDATOR" ] && [ ! -z "$PRIMARY_VALIDATOR_ADDRESS" ]; then
    echo "Error: primary_validator and primary_validator_address are mutually exclusive. Please specify only one of these."
    exit 1
fi

# if PRIMARY_VALIDATOR is true run function to create primary validator config
if [ ! -z "$PRIMARY_VALIDATOR" ]; then
    create_primary_validator_config $MONIKER $CHAIN_ID
elif [ ! -z "$PRIMARY_VALIDATOR_ADDRESS" ]; then
    create_validator_config $MONIKER $CHAIN_ID $PRIMARY_VALIDATOR_ADDRESS
fi


# using simd send 100 tokens from alice to bob 
# dominiond tx bank send $(dominiond keys show -a alice-alpha --keyring-backend test) $(dominiond keys show -a bob-alpha --keyring-backend test) 1000000000uminion --keyring-backend test -y


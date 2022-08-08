package keeper

import (
	"dominion/x/dominion/types"
)

var _ types.QueryServer = Keeper{}

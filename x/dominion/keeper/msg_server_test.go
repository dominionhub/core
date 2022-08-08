package keeper_test

import (
	"context"
	"testing"

	keepertest "dominion/testutil/keeper"
	"dominion/x/dominion/keeper"
	"dominion/x/dominion/types"
	sdk "github.com/cosmos/cosmos-sdk/types"
)

func setupMsgServer(t testing.TB) (types.MsgServer, context.Context) {
	k, ctx := keepertest.DominionKeeper(t)
	return keeper.NewMsgServerImpl(*k), sdk.WrapSDKContext(ctx)
}

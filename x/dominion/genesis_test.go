package dominion_test

import (
	"testing"

	keepertest "dominion/testutil/keeper"
	"dominion/testutil/nullify"
	"dominion/x/dominion"
	"dominion/x/dominion/types"
	"github.com/stretchr/testify/require"
)

func TestGenesis(t *testing.T) {
	genesisState := types.GenesisState{
		Params: types.DefaultParams(),

		// this line is used by starport scaffolding # genesis/test/state
	}

	k, ctx := keepertest.DominionKeeper(t)
	dominion.InitGenesis(ctx, *k, genesisState)
	got := dominion.ExportGenesis(ctx, *k)
	require.NotNil(t, got)

	nullify.Fill(&genesisState)
	nullify.Fill(got)

	// this line is used by starport scaffolding # genesis/test/assert
}

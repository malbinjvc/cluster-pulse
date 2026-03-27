# ClusterPulse - Error Log

## Error 1: Gleam ecosystem version incompatibility
- **Error**: `The module gleam/dynamic does not have a from value` — gleam_erlang 0.34.0 and 1.0.0-rc1 both reference `dynamic.from` which was removed from gleam_stdlib >= 0.68
- **Root Cause**: Gleam 1.14 ships with stdlib changes that broke backward compatibility with published packages on Hex (gleam_erlang, glisten, etc.)
- **Resolution**: Replaced Gleam/Wisp with Lua/Pegasus. The Gleam ecosystem needs package updates to be mutually compatible with stdlib 0.68+.

## Error 2: Lua tests not resetting state between runs
- **Error**: Test failures showing accumulated data from previous tests (e.g., `test_list_points_empty` found 24 points)
- **Root Cause**: Global `setUp()` function not invoked by luaunit for global test functions. State persisted across test runs.
- **Resolution**: Added explicit `reset()` call at the start of each test function instead of relying on luaunit setUp hooks.

## Error 3: K-means nil arithmetic on single-dimension vectors
- **Error**: `attempt to perform arithmetic on a nil value` in clustering when points had varying feature dimensions
- **Root Cause**: Feature vector dimension mismatch during centroid recomputation — accessing indices beyond vector length
- **Resolution**: Fixed by ensuring centroid dimension matches input features exactly, using `#centroids[ci]` for loop bounds.

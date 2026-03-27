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

## Error 4: Docker lzlib build failure on Alpine
- **Error**: `Could not find header file for ZLIB` and `Could not find library file for ZLIB` when installing pegasus via luarocks
- **Root Cause**: Pegasus depends on lzlib for optional gzip support, but lzlib's rockspec can't find zlib headers on Alpine even with zlib-dev installed
- **Resolution**: Installed pegasus dependencies manually (mimetypes, luasocket, luafilesystem), then `luarocks install pegasus --deps-mode=none` to skip lzlib

## Error 5: CI lzlib/zlib detection failure on Alpine container
- **Error**: Same zlib detection issue as Error 4 but in GitHub Actions Alpine container
- **Root Cause**: lzlib rockspec uses custom detection logic incompatible with Alpine's zlib paths
- **Resolution**: Switched CI test job from Alpine container to ubuntu-latest with apt-get installed packages

## Error 6: CI luaunit module not found
- **Error**: `module 'luaunit' not found` when running tests on ubuntu-latest
- **Root Cause**: luarocks installs modules to Lua 5.1 paths by default, but lua5.4 binary looks in 5.4 paths
- **Resolution**: Set LUA_PATH and LUA_CPATH environment variables covering both 5.1 and 5.4 installation paths

## Error 7: Docker Hub rate limit
- **Error**: `toomanyrequests: too many failed login attempts` during CI Docker build
- **Root Cause**: Docker Hub anonymous pull rate limit exceeded
- **Resolution**: Re-ran the workflow after rate limit window reset

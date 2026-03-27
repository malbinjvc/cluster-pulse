local pegasus = require("pegasus")
local json = require("dkjson")
local services = require("src.services")

local M = {}

-- JSON response helper
local function json_response(handler, status, data)
  local body = json.encode(data)
  handler:statusCode(status, "")
  handler:addHeader("Content-Type", "application/json")
  handler:write(body)
  return true
end

-- Parse JSON body
local function parse_body(content)
  if not content or content == "" then return nil end
  local obj, _, err = json.decode(content)
  if err then return nil end
  return obj
end

-- Route matching helper
local function match_route(method, path)
  -- Static routes
  if method == "GET" and path == "/health" then return "health" end
  if method == "GET" and path == "/api/points" then return "list_points" end
  if method == "POST" and path == "/api/points" then return "add_point" end
  if method == "POST" and path == "/api/cluster" then return "cluster" end
  if method == "GET" and path == "/api/clusters" then return "get_clusters" end
  if method == "POST" and path == "/api/similarity" then return "similarity" end
  if method == "POST" and path == "/api/nearest" then return "nearest" end
  if method == "GET" and path == "/api/stats" then return "stats" end

  -- Dynamic routes: /api/points/:id
  local id = path:match("^/api/points/([%w_]+)$")
  if id then
    if method == "GET" then return "get_point", id end
    if method == "DELETE" then return "delete_point", id end
  end

  return nil
end

-- Route handlers
local handlers = {}

function handlers.health(_, _)
  return 200, { status = "healthy", service = "cluster-pulse" }
end

function handlers.list_points(_, _)
  local points = services.list_points()
  return 200, { points = points, count = #points }
end

function handlers.add_point(body, _)
  local data = parse_body(body)
  if not data or not data.name or not data.features then
    return 400, { error = "Invalid request body: name and features required" }
  end
  local point = services.add_point(data.name, data.features, data.label)
  return 201, point
end

function handlers.get_point(_, id)
  local point = services.get_point(id)
  if not point then
    return 404, { error = "Point not found" }
  end
  return 200, point
end

function handlers.delete_point(_, id)
  if services.delete_point(id) then
    return 200, { deleted = true }
  end
  return 404, { error = "Point not found" }
end

function handlers.cluster(body, _)
  local data = parse_body(body)
  if not data or not data.k then
    return 400, { error = "Invalid request body: k required" }
  end
  local clusters = services.run_clustering(data.k)
  local analysis = services.analyze_clusters()
  return 200, { clusters = clusters, count = #clusters, analysis = analysis }
end

function handlers.get_clusters(_, _)
  local st = services.get_state()
  return 200, { clusters = st.clusters, count = #st.clusters }
end

function handlers.similarity(body, _)
  local data = parse_body(body)
  if not data or not data.point_a or not data.point_b then
    return 400, { error = "Invalid request body: point_a and point_b required" }
  end
  local result = services.compute_similarity(data.point_a, data.point_b)
  if not result then
    return 404, { error = "One or both points not found" }
  end
  return 200, result
end

function handlers.nearest(body, _)
  local data = parse_body(body)
  if not data or not data.query_id or not data.k then
    return 400, { error = "Invalid request body: query_id and k required" }
  end
  local result = services.find_nearest(data.query_id, data.k)
  if not result then
    return 404, { error = "Query point not found" }
  end
  return 200, result
end

function handlers.stats(_, _)
  return 200, services.get_stats()
end

-- Request handler for Pegasus
function M.handle_request(req, rep)
  local method = req:method()
  local path = req:path()
  local route, param = match_route(method, path)

  if not route then
    return json_response(rep, 404, { error = "Not found" })
  end

  local handler_fn = handlers[route]
  if not handler_fn then
    return json_response(rep, 500, { error = "Internal server error" })
  end

  local body = req:post()
  local status, data = handler_fn(body, param)
  return json_response(rep, status, data)
end

-- Start server
function M.start(port)
  port = port or tonumber(os.getenv("PORT")) or 8080
  local server = pegasus:new({ port = port })
  print("ClusterPulse running on port " .. tostring(port))
  server:start(function(req, rep)
    M.handle_request(req, rep)
  end)
end

return M

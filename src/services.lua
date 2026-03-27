local models = require("src.models")

local M = {}

-- State
local state = {
  points = {},
  clusters = {},
}

function M.get_state()
  return state
end

function M.reset_state()
  state = { points = {}, clusters = {} }
  models.reset_ids()
end

-- Point CRUD
function M.add_point(name, features, label)
  local point = models.new_data_point(name, features, label)
  state.points[point.id] = point
  return point
end

function M.get_point(id)
  return state.points[id]
end

function M.list_points()
  local result = {}
  for _, p in pairs(state.points) do
    result[#result + 1] = p
  end
  table.sort(result, function(a, b) return a.id < b.id end)
  return result
end

function M.delete_point(id)
  if state.points[id] then
    state.points[id] = nil
    return true
  end
  return false
end

function M.count_points()
  local n = 0
  for _ in pairs(state.points) do n = n + 1 end
  return n
end

-- Math helpers
function M.dot_product(a, b)
  local sum = 0
  for i = 1, #a do
    sum = sum + (a[i] or 0) * (b[i] or 0)
  end
  return sum
end

function M.magnitude(v)
  local sum = 0
  for i = 1, #v do
    sum = sum + v[i] * v[i]
  end
  return math.sqrt(sum)
end

function M.cosine_similarity(a, b)
  local dot = M.dot_product(a, b)
  local mag_a = M.magnitude(a)
  local mag_b = M.magnitude(b)
  if mag_a * mag_b == 0 then return 0 end
  return dot / (mag_a * mag_b)
end

function M.euclidean_distance(a, b)
  local sum = 0
  for i = 1, #a do
    local diff = (a[i] or 0) - (b[i] or 0)
    sum = sum + diff * diff
  end
  return math.sqrt(sum)
end

-- Similarity
function M.compute_similarity(id_a, id_b)
  local pa = state.points[id_a]
  local pb = state.points[id_b]
  if not pa or not pb then return nil end
  local score = M.cosine_similarity(pa.features, pb.features)
  return models.new_similarity_result(id_a, id_b, score)
end

-- Nearest neighbors
function M.find_nearest(query_id, k)
  local query = state.points[query_id]
  if not query then return nil end

  local distances = {}
  for id, p in pairs(state.points) do
    if id ~= query_id then
      distances[#distances + 1] = {
        id = id,
        distance = M.euclidean_distance(query.features, p.features),
      }
    end
  end

  table.sort(distances, function(a, b) return a.distance < b.distance end)

  local neighbors = {}
  for i = 1, math.min(k, #distances) do
    neighbors[#neighbors + 1] = distances[i]
  end

  return models.new_nearest_result(query_id, neighbors)
end

-- K-means clustering
function M.run_clustering(k)
  local points = M.list_points()
  local n = #points
  if n == 0 then
    state.clusters = {}
    return state.clusters
  end

  local actual_k = math.min(k, n)

  -- Initialize centroids from first k points
  local centroids = {}
  for i = 1, actual_k do
    local c = {}
    for j = 1, #points[i].features do
      c[j] = points[i].features[j]
    end
    centroids[i] = c
  end

  -- Run 10 iterations
  for _ = 1, 10 do
    -- Assign points to nearest centroid
    local assignments = {}
    for ci = 1, actual_k do
      assignments[ci] = {}
    end

    for _, p in ipairs(points) do
      local best_idx = 1
      local best_dist = M.euclidean_distance(p.features, centroids[1])
      for ci = 2, actual_k do
        local dist = M.euclidean_distance(p.features, centroids[ci])
        if dist < best_dist then
          best_dist = dist
          best_idx = ci
        end
      end
      assignments[best_idx][#assignments[best_idx] + 1] = p
    end

    -- Recompute centroids
    for ci = 1, actual_k do
      if #assignments[ci] > 0 then
        local dim = #centroids[ci]
        local new_c = {}
        for d = 1, dim do new_c[d] = 0 end
        for _, p in ipairs(assignments[ci]) do
          for d = 1, dim do
            new_c[d] = new_c[d] + p.features[d]
          end
        end
        for d = 1, dim do
          new_c[d] = new_c[d] / #assignments[ci]
        end
        centroids[ci] = new_c
      end
    end
  end

  -- Final assignment
  local cluster_points = {}
  for ci = 1, actual_k do
    cluster_points[ci] = {}
  end
  for _, p in ipairs(points) do
    local best_idx = 1
    local best_dist = M.euclidean_distance(p.features, centroids[1])
    for ci = 2, actual_k do
      local dist = M.euclidean_distance(p.features, centroids[ci])
      if dist < best_dist then
        best_dist = dist
        best_idx = ci
      end
    end
    cluster_points[best_idx][#cluster_points[best_idx] + 1] = p.id
  end

  local clusters = {}
  for ci = 1, actual_k do
    clusters[ci] = models.new_cluster(
      "cluster_" .. tostring(ci - 1),
      centroids[ci],
      cluster_points[ci]
    )
  end
  state.clusters = clusters
  return clusters
end

-- Stats
function M.get_stats()
  local total_points = M.count_points()
  local total_clusters = #state.clusters
  local avg = 0
  if total_clusters > 0 then
    avg = total_points / total_clusters
  end
  return models.new_stats(total_points, total_clusters, avg)
end

-- Mock Claude analysis
function M.analyze_clusters()
  local count = #state.clusters
  local total = 0
  for _, c in ipairs(state.clusters) do
    total = total + #c.point_ids
  end
  return "Analysis: " .. tostring(count) .. " clusters identified with "
    .. tostring(total) .. " total data points. Clustering appears well-distributed."
end

return M

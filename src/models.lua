local M = {}

local next_id = 0

function M.new_id(prefix)
  next_id = next_id + 1
  return prefix .. "_" .. tostring(next_id)
end

function M.reset_ids()
  next_id = 0
end

function M.new_data_point(name, features, label)
  return {
    id = M.new_id("pt"),
    name = name,
    features = features,
    label = label or nil,
  }
end

function M.new_cluster(id, centroid, point_ids)
  return {
    id = id,
    centroid = centroid,
    point_ids = point_ids,
  }
end

function M.new_similarity_result(point_a, point_b, score)
  return {
    point_a = point_a,
    point_b = point_b,
    score = score,
  }
end

function M.new_nearest_result(query_id, neighbors)
  return {
    query_id = query_id,
    neighbors = neighbors,
  }
end

function M.new_stats(total_points, total_clusters, avg_cluster_size)
  return {
    total_points = total_points,
    total_clusters = total_clusters,
    avg_cluster_size = avg_cluster_size,
  }
end

return M

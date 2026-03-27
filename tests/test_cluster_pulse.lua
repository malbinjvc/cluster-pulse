local luaunit = require("luaunit")
local services = require("src.services")

-- Helper to reset state before each test
local function reset()
  services.reset_state()
end

-- === Point CRUD Tests ===

function test_add_point()
  reset()
  local point = services.add_point("test", {1.0, 2.0, 3.0})
  luaunit.assertNotNil(point.id)
  luaunit.assertEquals(point.name, "test")
  luaunit.assertEquals(point.features, {1.0, 2.0, 3.0})
  luaunit.assertNil(point.label)
end

function test_add_point_with_label()
  reset()
  local point = services.add_point("labeled", {1.0}, "category_a")
  luaunit.assertEquals(point.label, "category_a")
end

function test_add_multiple_points()
  reset()
  services.add_point("a", {1.0})
  services.add_point("b", {2.0})
  services.add_point("c", {3.0})
  luaunit.assertEquals(services.count_points(), 3)
end

function test_get_point()
  reset()
  local p = services.add_point("test", {1.0})
  local found = services.get_point(p.id)
  luaunit.assertNotNil(found)
  luaunit.assertEquals(found.name, "test")
end

function test_get_point_not_found()
  reset()
  local found = services.get_point("nonexistent")
  luaunit.assertNil(found)
end

function test_list_points()
  reset()
  services.add_point("a", {1.0})
  services.add_point("b", {2.0})
  local points = services.list_points()
  luaunit.assertEquals(#points, 2)
end

function test_list_points_empty()
  reset()
  local points = services.list_points()
  luaunit.assertEquals(#points, 0)
end

function test_delete_point()
  reset()
  local p = services.add_point("test", {1.0})
  luaunit.assertTrue(services.delete_point(p.id))
  luaunit.assertEquals(services.count_points(), 0)
end

function test_delete_point_not_found()
  reset()
  luaunit.assertFalse(services.delete_point("nonexistent"))
end

-- === Math Tests ===

function test_dot_product()
  local result = services.dot_product({1, 2, 3}, {4, 5, 6})
  luaunit.assertEquals(result, 32)
end

function test_dot_product_zero()
  local result = services.dot_product({1, 0}, {0, 1})
  luaunit.assertEquals(result, 0)
end

function test_magnitude()
  local result = services.magnitude({3, 4})
  luaunit.assertAlmostEquals(result, 5.0, 0.001)
end

function test_cosine_similarity_identical()
  local result = services.cosine_similarity({1, 2}, {1, 2})
  luaunit.assertAlmostEquals(result, 1.0, 0.001)
end

function test_cosine_similarity_orthogonal()
  local result = services.cosine_similarity({1, 0}, {0, 1})
  luaunit.assertAlmostEquals(result, 0.0, 0.001)
end

function test_cosine_similarity_opposite()
  local result = services.cosine_similarity({1, 0}, {-1, 0})
  luaunit.assertAlmostEquals(result, -1.0, 0.001)
end

function test_cosine_similarity_zero_vector()
  local result = services.cosine_similarity({0, 0}, {1, 2})
  luaunit.assertEquals(result, 0)
end

function test_euclidean_distance_same()
  local result = services.euclidean_distance({1, 2}, {1, 2})
  luaunit.assertEquals(result, 0)
end

function test_euclidean_distance()
  local result = services.euclidean_distance({0, 0}, {3, 4})
  luaunit.assertAlmostEquals(result, 5.0, 0.001)
end

-- === Similarity Service Tests ===

function test_compute_similarity()
  reset()
  local pa = services.add_point("a", {1, 0})
  local pb = services.add_point("b", {1, 0})
  local result = services.compute_similarity(pa.id, pb.id)
  luaunit.assertNotNil(result)
  luaunit.assertAlmostEquals(result.score, 1.0, 0.001)
end

function test_compute_similarity_not_found()
  reset()
  local result = services.compute_similarity("x", "y")
  luaunit.assertNil(result)
end

-- === Nearest Neighbors Tests ===

function test_find_nearest()
  reset()
  local p1 = services.add_point("origin", {0, 0})
  local p2 = services.add_point("near", {1, 0})
  services.add_point("far", {10, 10})
  local result = services.find_nearest(p1.id, 2)
  luaunit.assertNotNil(result)
  luaunit.assertEquals(result.query_id, p1.id)
  luaunit.assertEquals(#result.neighbors, 2)
  -- First neighbor should be the nearest (distance 1.0)
  luaunit.assertEquals(result.neighbors[1].id, p2.id)
  luaunit.assertAlmostEquals(result.neighbors[1].distance, 1.0, 0.001)
end

function test_find_nearest_not_found()
  reset()
  local result = services.find_nearest("nonexistent", 2)
  luaunit.assertNil(result)
end

function test_find_nearest_k_larger()
  reset()
  local p1 = services.add_point("a", {0})
  services.add_point("b", {1})
  local result = services.find_nearest(p1.id, 10)
  luaunit.assertEquals(#result.neighbors, 1)
end

-- === Clustering Tests ===

function test_cluster_empty()
  reset()
  local clusters = services.run_clustering(2)
  luaunit.assertEquals(#clusters, 0)
end

function test_cluster_single_point()
  reset()
  services.add_point("alone", {1, 2})
  local clusters = services.run_clustering(1)
  luaunit.assertEquals(#clusters, 1)
  luaunit.assertEquals(#clusters[1].point_ids, 1)
end

function test_cluster_two_groups()
  reset()
  services.add_point("a1", {0, 0})
  services.add_point("a2", {0.1, 0.1})
  services.add_point("b1", {10, 10})
  services.add_point("b2", {10.1, 10.1})
  local clusters = services.run_clustering(2)
  luaunit.assertEquals(#clusters, 2)
  local total = #clusters[1].point_ids + #clusters[2].point_ids
  luaunit.assertEquals(total, 4)
end

function test_cluster_k_greater_than_points()
  reset()
  services.add_point("a", {1})
  services.add_point("b", {2})
  local clusters = services.run_clustering(5)
  luaunit.assertEquals(#clusters, 2)
end

-- === Stats Tests ===

function test_stats_empty()
  reset()
  local stats = services.get_stats()
  luaunit.assertEquals(stats.total_points, 0)
  luaunit.assertEquals(stats.total_clusters, 0)
  luaunit.assertEquals(stats.avg_cluster_size, 0)
end

function test_stats_with_data()
  reset()
  services.add_point("a", {1})
  services.add_point("b", {2})
  services.add_point("c", {3})
  services.run_clustering(2)
  local stats = services.get_stats()
  luaunit.assertEquals(stats.total_points, 3)
  luaunit.assertEquals(stats.total_clusters, 2)
  luaunit.assertAlmostEquals(stats.avg_cluster_size, 1.5, 0.001)
end

-- === Analysis Tests ===

function test_analyze_clusters()
  reset()
  services.add_point("a", {1})
  services.add_point("b", {10})
  services.run_clustering(2)
  local analysis = services.analyze_clusters()
  luaunit.assertStrContains(analysis, "2 clusters")
  luaunit.assertStrContains(analysis, "2 total data points")
end

function test_analyze_clusters_empty()
  reset()
  local analysis = services.analyze_clusters()
  luaunit.assertStrContains(analysis, "0 clusters")
end

os.exit(luaunit.LuaUnit.run())

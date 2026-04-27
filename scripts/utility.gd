class_name Utility

## Find the lowest common ancestor of two arrays. Returns null if no common ancestor exists.
static func find_lca(a: Array, b: Array) -> Variant:
	var smallest_size := mini(a.size(), b.size())
	var lca = null

	for i in smallest_size:
		if a[i] == b[i]:
			lca = a[i]
		else:
			break

	return lca
package raytracer

AaBb :: struct {
	x, y, z: Interval,
}

aabb :: proc {
	aabb_point,
	aabb_interval3,
	aabb_union,
}

aabb_point :: proc(a, b: Point3) -> AaBb {
	aabb := AaBb {
		x = (a[0] <= b[0]) ? Interval{a[0], b[0]} : Interval{b[0], a[0]},
		y = (a[1] <= b[1]) ? Interval{a[1], b[1]} : Interval{b[1], a[1]},
		z = (a[2] <= b[2]) ? Interval{a[2], b[2]} : Interval{b[2], a[2]},
	}

	return aabb_pad_to_minimums(&aabb)
}

aabb_interval3 :: proc(x, y, z: Interval) -> AaBb {
	aabb := AaBb{x, y, z}

	return aabb_pad_to_minimums(&aabb)
}

aabb_offset :: proc(bbox: AaBb, offset: Vec3) -> AaBb {
	return AaBb {
		x = interval_offset(bbox.x, offset.x),
		y = interval_offset(bbox.y, offset.y),
		z = interval_offset(bbox.z, offset.z),
	}
}

aabb_union :: proc(box0, box1: AaBb) -> AaBb {
	aabb := AaBb {
		x = interval_union(box0.x, box1.x),
		y = interval_union(box0.y, box1.y),
		z = interval_union(box0.z, box1.z),
	}

	return aabb_pad_to_minimums(&aabb)
}

aabb_pad_to_minimums :: proc(aabb: ^AaBb) -> AaBb {
	delta: f64 = 0.0001

	if interval_size(aabb.x) < delta do aabb.x = expand(aabb.x, delta)
	if interval_size(aabb.y) < delta do aabb.y = expand(aabb.y, delta)
	if interval_size(aabb.z) < delta do aabb.z = expand(aabb.z, delta)

	return aabb^
}

aabb_axis_interval :: proc(aabb: AaBb, n: int) -> Interval {
	if n == 1 {return aabb.y}
	if n == 2 {return aabb.z}
	return aabb.x
}

aabb_empty :: proc() -> AaBb {
	return AaBb{x = INTERVAL_EMPTY, y = INTERVAL_EMPTY, z = INTERVAL_EMPTY}
}

aabb_universe :: proc() -> AaBb {
	return AaBb{x = INTERVAL_UNIVERSE, y = INTERVAL_UNIVERSE, z = INTERVAL_UNIVERSE}
}

aabb_hit :: proc(aabb: AaBb, r: Ray, ray_t: Interval) -> bool {
	ray_orig := r.origin
	ray_dir := r.dir
	interval := ray_t

	for axis := 0; axis < 3; axis += 1 {
		ax := aabb_axis_interval(aabb, axis)
		adinv := 1.0 / ray_dir[axis]

		t0 := (ax.min - ray_orig[axis]) * adinv
		t1 := (ax.max - ray_orig[axis]) * adinv

		if t0 < t1 {
			if t0 > interval.min {interval.min = t0}
			if t1 < interval.max {interval.max = t1}
		} else {
			if t1 > interval.min {interval.min = t1}
			if t1 < interval.max {interval.max = t0}
		}

		if interval.max <= interval.min {
			return false
		}
	}

	return true
}

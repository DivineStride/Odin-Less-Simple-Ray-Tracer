package raytracer

import "core:slice"
Bvh_Node :: struct {
	left:  ^Hittable,
	right: ^Hittable,
	bbox:  AaBb,
}

new_bvh_node :: proc(objects: []^Hittable, start, end: uint) -> Bvh_Node {
	bbox_span := aabb_empty()
	for object_index := start; object_index < end; object_index += 1 {
		bbox_span = aabb_union(bbox_span, get_bbox(objects[object_index]))
	}

	axis := bbox_longest_axis(bbox_span)

	comparator: proc(a: ^Hittable, b: ^Hittable) -> bool
	if axis == 0 {
		comparator = box_x_compare
	} else if axis == 1 {
		comparator = box_y_compare
	} else {
		comparator = box_z_compare
	}

	object_span := end - start
	left, right: ^Hittable

	if object_span == 1 {
		left = objects[start]
		right = objects[start]
	} else if object_span == 2 {
		left = objects[start]
		right = objects[start + 1]
	} else {
		slice.sort_by(objects[start:end], comparator)

		mid := start + object_span / 2
		left = hittable_new(new_bvh_node(objects, start, mid))
		right = hittable_new(new_bvh_node(objects, mid, end))
	}

	bbox := aabb_union(get_bbox(left), get_bbox(right))

	return {left, right, bbox}
}

get_sphere_bbox :: proc(s: ^Sphere) -> AaBb {
	return s.bbox
}

box_compare :: proc(a, b: ^Hittable, axis_index: int) -> bool {
	a_axis_interval := aabb_axis_interval(get_bbox(a), axis_index)
	b_axis_interval := aabb_axis_interval(get_bbox(b), axis_index)
	return a_axis_interval.min < b_axis_interval.min
}

box_x_compare :: proc(a, b: ^Hittable) -> bool {
	return box_compare(a, b, 0)
}

box_y_compare :: proc(a, b: ^Hittable) -> bool {
	return box_compare(a, b, 1)
}

box_z_compare :: proc(a, b: ^Hittable) -> bool {
	return box_compare(a, b, 2)
}

bbox_longest_axis :: proc(bbox: AaBb) -> int {
	if interval_size(bbox.x) > interval_size(bbox.y) {
		return interval_size(bbox.x) > interval_size(bbox.z) ? 0 : 2
	} else {
		return interval_size(bbox.y) > interval_size(bbox.z) ? 1 : 2
	}
}

hit_bvh :: proc(bvh_node: Bvh_Node, r: Ray, ray_t: Interval) -> (Hit_Record, bool) {
	if !aabb_hit(bvh_node.bbox, r, ray_t) {
		return {}, false
	}

	rec, hit_left := hit_single(bvh_node.left^, r, ray_t)
	right_max := hit_left ? rec.t : ray_t.max
	rec_right, hit_right := hit_single(bvh_node.right^, r, Interval{ray_t.min, right_max})

	if hit_right {
		return rec_right, true
	}
	return rec, hit_left
}

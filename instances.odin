package raytracer

import "core:math"
import "core:math/linalg"

Vec4 :: linalg.Vector4f64

Instance :: struct {
	object:        ^Hittable,
	bbox:          AaBb,
	transform:     linalg.Matrix4f64,
	inv_transform: linalg.Matrix4f64,
}

make_instance :: proc(object: ^Hittable, translate: Vec3, rotate: Vec3) -> Instance {
	rotat := linalg.matrix4_from_euler_angles_f64(
		degrees_to_radians(rotate.x),
		degrees_to_radians(rotate.y),
		degrees_to_radians(rotate.z),
		.XYZ,
	)
	trans := linalg.matrix4_translate(translate)
	transform := linalg.matrix_mul(trans, rotat)

	return Instance {
		object = object,
		transform = transform,
		inv_transform = linalg.matrix4_inverse(transform),
		bbox = compute_rotated_bbox(get_bbox(object), rotat, translate),
	}
}

compute_rotated_bbox :: proc(bbox: AaBb, rot: linalg.Matrix4f64, translate: Vec3) -> AaBb {
	min: Point3 = Point3{math.INF_F64, math.INF_F64, math.INF_F64}
	max: Point3 = Point3{-math.INF_F64, -math.INF_F64, -math.INF_F64}

	for i := 0; i < 2; i += 1 {
		for j := 0; j < 2; j += 1 {
			for k := 0; k < 2; k += 1 {
				x := f64(i) * bbox.x.max + (1 - f64(i)) * bbox.x.min
				y := f64(j) * bbox.y.max + (1 - f64(j)) * bbox.y.min
				z := f64(k) * bbox.z.max + (1 - f64(k)) * bbox.z.min

				tester := linalg.mul(rot, linalg.Vector4f64{x, y, z, 1})

				for c := 0; c < 3; c += 1 {
					min[c] = math.min(min[c], tester[c])
					max[c] = math.max(max[c], tester[c])
				}
			}
		}
	}

	return aabb_offset(aabb(min, max), translate)
}

hit_instance :: proc(inst: Instance, r: Ray, ray_t: Interval) -> (Hit_Record, bool) {
	// Transform ray to object space
	offset := linalg.mul(inst.inv_transform, Vec4{r.origin.x, r.origin.y, r.origin.z, 1})
	direction := linalg.mul(inst.inv_transform, Vec4{r.dir.x, r.dir.y, r.dir.z, 0})
	object_ray := Ray{offset.xyz, direction.xyz, r.tm}

	rec, hit := hit_single(inst.object^, object_ray, ray_t)
	if !hit do return {}, false

	// Tranform hit point and normal back to world space
	p := linalg.mul(inst.transform, Vec4{rec.p.x, rec.p.y, rec.p.z, 1})
	n := linalg.mul(
		linalg.matrix4_inverse_transpose(inst.inv_transform),
		Vec4{rec.normal.x, rec.normal.y, rec.normal.z, 0},
	)

	rec.p = p.xyz
	rec.normal = linalg.normalize(n.xyz)

	return rec, true
}

shape_as_hittable :: proc(verts: $N/[$T]Hittable, tracked: ^[dynamic]^Hittable) -> ^Hittable {
	temp := make([]Hittable, $T, context.temp_allocator)
	for i in 0 ..< $T do temp[i] = sides[i]

	ptrs := make([]^Hittable, $T, context.temp_allocator)
	for i in 0 ..< $T do ptrs[i] = &temp[i]
	bvh := new_bvh_node(btrs, 0, 6)

	h := new(Hittable)
	h^ = bvh
	append(tracked, h)
	return h
}

build_box :: proc(a, b: Point3, mat: ^Material, sides_out: ^[dynamic][]Hittable) -> Bvh_Node {
	min := Point3{math.min(a.x, b.x), math.min(a.y, b.y), math.min(a.z, b.z)}
	max := Point3{math.max(a.x, b.x), math.max(a.y, b.y), math.max(a.z, b.z)}

	dx := Vec3{max.x - min.x, 0, 0}
	dy := Vec3{0, max.y - min.y, 0}
	dz := Vec3{0, 0, max.z - min.z}

	sides := make([]Hittable, 6)
	sides[0] = build_quad(Point3{min.x, min.y, max.z}, dx, dy, mat) // front
	sides[1] = build_quad(Point3{max.x, min.y, max.z}, -dz, dy, mat) // right
	sides[2] = build_quad(Point3{max.x, min.y, min.z}, -dx, dy, mat) // back
	sides[3] = build_quad(Point3{min.x, min.y, min.z}, dz, dy, mat) // left
	sides[4] = build_quad(Point3{min.x, max.y, max.z}, dx, -dz, mat) // top
	sides[5] = build_quad(Point3{min.x, min.y, min.z}, dx, dz, mat) // bottom
	append(sides_out, sides)

	ptrs := make([]^Hittable, 6, context.temp_allocator)
	for i in 0 ..< 6 do ptrs[i] = &sides[i]

	return new_bvh_node(ptrs[:], 0, 6)
}

append_instance :: proc {
	append_hittables_slice,
	append_hittables_array,
}

append_hittables_slice :: proc(world: ^[dynamic]Hittable, shape: []Hittable) {
	for s in shape do append(world, s)
}

append_hittables_array :: proc(world: ^[dynamic]Hittable, shape: $N/[$T]Hittable) {
	for s in shape do append(world, s)
}

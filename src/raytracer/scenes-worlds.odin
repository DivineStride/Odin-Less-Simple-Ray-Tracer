package raytracer

import "core:math/linalg"

CORE_COUNT: int

world_many_spheres :: proc(render: Render_Details, bounce: bool = false) {
	// Setup Camera
	cam := camera_default()
	cam.lookfrom = {13, 2, 3}
	cam.lookat = {0, 0, 0}
	cam.image_width = render.image_width
	cam.samples_per_pixel = render.samples
	cam.focal_length_mm = 85
	cam.fstop = 8.0
	cam.aperture = Aperture_Polygon {
		blades   = 6,
		rotation = 15,
	}
	cam.max_depth = render.depth

	// World
	world: [dynamic]Hittable
	defer delete(world)

	ground_mat := make_burley(checker_texture(0.32, Color{.2, .3, .1}, Color{.9, .9, .9}), 1.0)
	append(&world, Hittable(build_sphere({0, -1000, 0}, 1000, &ground_mat)))

	materials: [dynamic]^Material
	defer {
		for m in materials do free(m)
		delete(materials)
	}
	for a := -11; a < 11; a += 1 {
		for b := -11; b < 11; b += 1 {
			choose_mat := random_f64()
			center := Point3{f64(a) + 0.9 * random_f64(), 0.2, f64(b) + 0.9 * random_f64()}

			if linalg.length(center - Point3{4, 0.2, 0}) > 0.9 {
				sphere_material := new(Material)
				if choose_mat < 0.8 {
					// Diffuse
					albedo := random_vec3() * random_vec3()
					roughness := random_f64()
					sphere_material^ = make_burley(albedo, roughness)
					center2 := center + Vec3{0, random_f64_range(0, .5), 0}
					if bounce {
						append(
							&world,
							Hittable(build_moving_sphere(center, center2, 0.2, sphere_material)),
						)
					} else {
						append(&world, Hittable(build_sphere(center, 0.2, sphere_material)))
					}
				} else if choose_mat < 0.95 {
					// Metal
					albedo: Color = random_vec3() * random_vec3()
					fuzz := random_f64()
					sphere_material^ = make_metal(albedo, fuzz)
					append(&world, Hittable(build_sphere(center, 0.2, sphere_material)))
				} else {
					// Glass
					sphere_material^ = Dielectric{1.5}
					append(&world, Hittable(build_sphere(center, 0.2, sphere_material)))
				}

				append(&materials, sphere_material)
			}

		}
	}
	material_1 := new(Material)
	append(&materials, material_1)
	material_1^ = Dielectric{1.5}
	append(&world, Hittable(build_sphere(Point3{0, 1, 0}, 1.0, material_1)))

	material_2 := new(Material)
	append(&materials, material_2)
	material_2^ = make_burley(Color{0.4, 0.2, 0.1}, 1)
	append(&world, Hittable(build_sphere(Point3{-4, 1, 0}, 1.0, material_2)))

	material_3 := new(Material)
	append(&materials, material_3)
	material_3^ = make_metal(Color{0.7, 0.6, 0.5}, 0.0)
	append(&world, Hittable(build_sphere(Point3{4, 1, 0}, 1.0, material_3)))

	// Init BVH
	world_ptrs := make([]^Hittable, len(world))
	defer delete(world_ptrs)

	for i in 0 ..< len(world) {
		world_ptrs[i] = &world[i]
	}

	bvh := new_bvh_node(world_ptrs, 0, uint(len(world)))
	bvh_world := []Hittable{Hittable(bvh)}

	// Render
	camera_render(&cam, bvh_world)

}

world_checkered_spheres :: proc(render: Render_Details) {
	// Setup Camera
	cam := camera_default()
	cam.lookfrom = {13, 2, 3}
	cam.lookat = {0, 0, 0}
	cam.image_width = render.image_width
	cam.samples_per_pixel = render.samples
	cam.focal_length_mm = 85
	cam.fstop = 20
	cam.aperture = Aperture_Polygon {
		blades   = 6,
		rotation = 15,
	}
	cam.max_depth = render.depth

	// World
	world: [dynamic]Hittable
	defer delete(world)

	materials: [dynamic]^Material
	defer {
		for m in materials do free(m)
		delete(materials)
	}
	// Start World Declaration ---------

	checker := checker_texture(0.32, Color{.2, .3, .1}, Color{.9, .9, .9})
	material := new(Material)
	append(&materials, material)
	material^ = make_burley(checker, 0)

	append(&world, build_sphere(Point3{0, -10, 0}, 10, material))
	append(&world, build_sphere(Point3{0, 10, 0}, 10, material))

	// End World Declaration -----------

	// Init BVH
	world_ptrs := make([]^Hittable, len(world))
	defer delete(world_ptrs)

	for i in 0 ..< len(world) {
		world_ptrs[i] = &world[i]
	}

	bvh := new_bvh_node(world_ptrs, 0, uint(len(world)))
	bvh_world := []Hittable{Hittable(bvh)}

	// Render
	camera_render(&cam, bvh_world)
}

world_earth :: proc(render: Render_Details) {
	// Setup Camera
	cam := camera_default()
	cam.lookfrom = {0, 0, 12}
	cam.lookat = {0, 0, 0}
	cam.image_width = render.image_width
	cam.samples_per_pixel = render.samples
	cam.focal_length_mm = 85
	cam.fstop = 20
	cam.aperture = Aperture_Polygon {
		blades   = 6,
		rotation = 15,
	}
	cam.max_depth = render.depth

	// World
	world: [dynamic]Hittable
	defer delete(world)

	materials: [dynamic]^Material
	defer {
		for m in materials do free(m)
		delete(materials)
	}
	// Start World Declaration ---------

	ok: bool
	earth_texture := new(Image)
	earth_texture^, ok = load_image("./images/planets/2k_earth_daymap.jpg"); assert(ok)
	defer destroy_image(earth_texture)

	earth_surface := new(Material)
	append(&materials, earth_surface)
	earth_surface^ = make_burley(image_texture(earth_texture), 0)

	append(&world, build_sphere({0, 0, 0}, 2.0, earth_surface))

	// End World Declaration -----------

	// Init BVH
	world_ptrs := make([]^Hittable, len(world))
	defer delete(world_ptrs)

	for i in 0 ..< len(world) {
		world_ptrs[i] = &world[i]
	}

	bvh := new_bvh_node(world_ptrs, 0, uint(len(world)))
	bvh_world := []Hittable{Hittable(bvh)}


	// Render
	camera_render(&cam, bvh_world)
}

world_perlin_spheres :: proc(render: Render_Details) {
	// Setup Camera
	cam := camera_default()
	cam.lookfrom = {13, 2, 3}
	cam.lookat = {0, 0, 0}
	cam.image_width = render.image_width
	cam.samples_per_pixel = render.samples
	cam.focal_length_mm = 120
	cam.fstop = 20
	cam.aperture = Aperture_Polygon {
		blades   = 6,
		rotation = 15,
	}
	cam.max_depth = render.depth

	// World
	world: [dynamic]Hittable
	defer delete(world)

	materials: [dynamic]^Material
	defer {
		for m in materials do free(m)
		delete(materials)
	}
	// Start World Declaration ---------


	pertex := new(Material)
	append(&materials, pertex)
	pertex^ = make_burley(noise_texture(), 0)
	append(&world, build_sphere({0, -1000, 0}, 1000, pertex))
	append(&world, build_sphere({0, 2, 0}, 2, pertex))

	// End World Declaration -----------

	// Init BVH
	world_ptrs := make([]^Hittable, len(world))
	defer delete(world_ptrs)

	for i in 0 ..< len(world) {
		world_ptrs[i] = &world[i]
	}

	bvh := new_bvh_node(world_ptrs, 0, uint(len(world)))
	bvh_world := []Hittable{Hittable(bvh)}


	// Render
	camera_render(&cam, bvh_world)
}

world_quads :: proc(render: Render_Details) {
	// Setup Camera
	cam := camera_default()
	cam.lookfrom = {0, 0, 9}
	cam.aspect_ratio = 1.0
	cam.lookat = {0, 0, 0}
	cam.image_width = render.image_width
	cam.samples_per_pixel = render.samples
	cam.focal_length_mm = 20
	cam.fstop = 20
	cam.aperture = Aperture_Polygon {
		blades   = 6,
		rotation = 15,
	}
	cam.max_depth = render.depth

	// World
	world: [dynamic]Hittable
	defer delete(world)

	materials: [dynamic]^Material
	defer {
		for m in materials do free(m)
		delete(materials)
	}

	// Start World Declaration ---------

	left_red := new(Material)
	back_green := new(Material)
	right_blue := new(Material)
	upper_orange := new(Material)
	lower_teal := new(Material)

	append(&materials, left_red)
	append(&materials, back_green)
	append(&materials, right_blue)
	append(&materials, upper_orange)
	append(&materials, lower_teal)

	left_red^ = make_burley(Color{1, 0.2, 0.2}, .5)
	back_green^ = make_burley(Color{0.2, 1, 0.2}, .5)
	right_blue^ = make_burley(Color{0.2, 0.2, 1}, .5)
	upper_orange^ = make_burley(Color{1, 0.5, 0}, .5)
	lower_teal^ = make_burley(Color{0.2, 0.8, 0.8}, .5)

	append(&world, build_quad(Point3{-3, -2, 5}, Vec3{0, 0, -4}, Vec3{0, 4, 0}, left_red))
	append(&world, build_quad(Point3{-2, -2, 0}, Vec3{4, 0, 0}, Vec3{0, 4, 0}, back_green))
	append(&world, build_quad(Point3{3, -2, 1}, Vec3{0, 0, 4}, Vec3{0, 4, 0}, right_blue))
	append(&world, build_quad(Point3{-2, 3, 1}, Vec3{4, 0, 0}, Vec3{0, 0, 4}, upper_orange))
	append(&world, build_quad(Point3{-2, -3, 5}, Vec3{4, 0, 0}, Vec3{0, 0, -4}, lower_teal))

	// End World Declaration -----------

	// Init BVH
	world_ptrs := make([]^Hittable, len(world))
	defer delete(world_ptrs)

	for i in 0 ..< len(world) {
		world_ptrs[i] = &world[i]
	}

	bvh := new_bvh_node(world_ptrs, 0, uint(len(world)))
	bvh_world := []Hittable{Hittable(bvh)}


	// Render
	camera_render(&cam, bvh_world)
}

world_simple_light :: proc(render: Render_Details) {
	// Setup Camera
	cam := camera_default()
	cam.lookfrom = {26, 3, 6}
	cam.lookat = {0, 2, 0}
	cam.image_width = render.image_width
	cam.samples_per_pixel = render.samples
	cam.focal_length_mm = 120
	cam.fstop = 20
	cam.focus_dist = 26
	cam.aperture = Aperture_Polygon {
		blades   = 6,
		rotation = 15,
	}
	cam.max_depth = render.depth
	cam.background = Color{0, 0, 0}

	// World
	world: [dynamic]Hittable
	defer delete(world)

	materials: [dynamic]^Material
	defer {
		for m in materials do free(m)
		delete(materials)
	}
	// Start World Declaration ---------

	pertex := new(Material)
	append(&materials, pertex)
	pertex^ = make_burley(noise_texture(), 0)
	append(&world, build_sphere({0, -1000, 0}, 1000, pertex))
	append(&world, build_sphere({0, 2, 0}, 2, pertex))

	difflight := new(Material)
	append(&materials, difflight)
	difflight^ = make_diffuse(Color{4, 4, 4})
	append(&world, build_quad(Point3{3, 1, -2}, Vec3{2, 0, 0}, Vec3{0, 2, 0}, difflight))
	append(&world, build_sphere({0, 7, 0}, 2, difflight))

	// End World Declaration -----------

	// Init BVH
	world_ptrs := make([]^Hittable, len(world))
	defer delete(world_ptrs)

	for i in 0 ..< len(world) {
		world_ptrs[i] = &world[i]
	}

	bvh := new_bvh_node(world_ptrs, 0, uint(len(world)))
	bvh_world := []Hittable{Hittable(bvh)}


	// Render
	camera_render(&cam, bvh_world)
}

world_cornell_box :: proc(render: Render_Details) {
	// Setup Camera
	cam := camera_default()
	cam.lookfrom = {278, 278, -800}
	cam.lookat = {278, 278, 0}
	cam.aspect_ratio = 1.0
	cam.image_width = render.image_width
	cam.samples_per_pixel = render.samples
	cam.focal_length_mm = 50
	cam.fstop = 20
	cam.focus_dist = 50
	cam.aperture = Aperture_Polygon {
		blades   = 6,
		rotation = 15,
	}
	cam.max_depth = render.depth
	cam.background = Color{0, 0, 0}

	// World
	world: [dynamic]Hittable
	defer delete(world)

	materials: [dynamic]^Material
	defer {
		for m in materials do free(m)
		delete(materials)
	}
	// Start World Declaration ---------

	red := new(Material)
	white := new(Material)
	green := new(Material)
	light := new(Material)

	append(&materials, red)
	append(&materials, white)
	append(&materials, green)
	append(&materials, light)

	red^ = make_burley(Color{.65, 0.05, 0.05}, 1)
	white^ = make_burley(Color{.73, .73, .73}, 1)
	green^ = make_burley(Color{.12, .45, .15}, 1)
	light^ = make_diffuse(Color{15, 15, 15})

	box_sides: [dynamic][]Hittable
	defer {
		for s in box_sides do delete(s)
		delete(box_sides)
	}

	box1_raw := new(Hittable)
	box1_raw^ = Hittable(build_box(Point3{0, 0, 0}, Point3{165, 330, 165}, white, &box_sides))

	box1 := make_instance(box1_raw, Vec3{265, 0, 295}, Vec3{0, 15, 0})

	box2_raw := new(Hittable)
	box2_raw^ = Hittable(build_box(Point3{0, 0, 0}, Point3{165, 165, 165}, white, &box_sides))

	box2 := make_instance(box2_raw, Vec3{130, 0, 65}, Vec3{0, -18, 0})

	append(&world, build_quad(Point3{555, 0, 0}, Vec3{0, 555, 0}, Vec3{0, 0, 555}, green))
	append(&world, build_quad(Point3{0, 0, 0}, Vec3{0, 555, 0}, Vec3{0, 0, 555}, red))
	append(&world, build_quad(Point3{343, 554, 332}, Vec3{-130, 0, 0}, Vec3{0, 0, -105}, light))
	append(&world, build_quad(Point3{0, 0, 0}, Vec3{555, 0, 0}, Vec3{0, 0, 555}, white))
	append(&world, build_quad(Point3{555, 555, 555}, Vec3{-555, 0, 4}, Vec3{0, 0, -555}, white))
	append(&world, build_quad(Point3{0, 0, 555}, Vec3{555, 0, 0}, Vec3{0, 555, 0}, white))
	append(&world, box1)
	append(&world, box2)

	// End World Declaration -----------

	// Init BVH
	world_ptrs := make([]^Hittable, len(world))
	defer delete(world_ptrs)

	for i in 0 ..< len(world) {
		world_ptrs[i] = &world[i]
	}

	bvh := new_bvh_node(world_ptrs, 0, uint(len(world)))
	bvh_world := []Hittable{Hittable(bvh)}


	// Render
	camera_render(&cam, bvh_world)
}

world_cornell_smoke :: proc(render: Render_Details) {
	// Setup Camera
	cam := camera_default()
	cam.lookfrom = {278, 278, -800}
	cam.lookat = {278, 278, 0}
	cam.aspect_ratio = 1.0
	cam.image_width = render.image_width
	cam.samples_per_pixel = render.samples
	cam.focal_length_mm = 50
	cam.fstop = 20
	cam.focus_dist = 50
	cam.aperture = Aperture_Polygon {
		blades   = 6,
		rotation = 15,
	}
	cam.max_depth = render.depth
	cam.background = Color{0, 0, 0}

	// World
	world: [dynamic]Hittable
	defer delete(world)

	materials: [dynamic]^Material
	defer {
		for m in materials do free(m)
		delete(materials)
	}
	// Start World Declaration ---------

	red := new(Material)
	white := new(Material)
	green := new(Material)
	light := new(Material)

	append(&materials, red)
	append(&materials, white)
	append(&materials, green)
	append(&materials, light)

	red^ = make_burley(Color{.65, 0.05, 0.05}, 1)
	white^ = make_burley(Color{.73, .73, .73}, 1)
	green^ = make_burley(Color{.12, .45, .15}, 1)
	light^ = make_diffuse(Color{7, 7, 7})

	box_sides: [dynamic][]Hittable
	defer {
		for s in box_sides do delete(s)
		delete(box_sides)
	}
	hittables: [dynamic]^Hittable
	defer {
		for h in hittables do free(h)
		delete(hittables)
	}

	box1_raw := new(Hittable)
	box1_raw^ = Hittable(build_box(Point3{0, 0, 0}, Point3{165, 330, 165}, white, &box_sides))

	box1 := new(Hittable)
	box1^ = Hittable(make_instance(box1_raw, Vec3{265, 0, 295}, Vec3{0, 15, 0}))

	box1_smoke := build_constant_medium(box1, 0.01, Color{0, 0, 0}, &materials)

	box2_raw := new(Hittable)
	box2_raw^ = Hittable(build_box(Point3{0, 0, 0}, Point3{165, 165, 165}, white, &box_sides))

	box2 := new(Hittable)
	box2^ = Hittable(make_instance(box2_raw, Vec3{130, 0, 65}, Vec3{0, -18, 0}))

	box2_smoke := build_constant_medium(box2, 0.01, Color{1, 1, 1}, &materials)

	append(&world, build_quad(Point3{555, 0, 0}, Vec3{0, 555, 0}, Vec3{0, 0, 555}, green))
	append(&world, build_quad(Point3{0, 0, 0}, Vec3{0, 555, 0}, Vec3{0, 0, 555}, red))
	append(&world, build_quad(Point3{113, 554, 127}, Vec3{330, 0, 0}, Vec3{0, 0, 305}, light))
	append(&world, build_quad(Point3{0, 0, 0}, Vec3{555, 0, 0}, Vec3{0, 0, 555}, white))
	append(&world, build_quad(Point3{555, 555, 555}, Vec3{-555, 0, 4}, Vec3{0, 0, -555}, white))
	append(&world, build_quad(Point3{0, 0, 555}, Vec3{555, 0, 0}, Vec3{0, 555, 0}, white))
	append(&world, box1_smoke)
	append(&world, box2_smoke)

	append(&hittables, box1_raw, box1, box2_raw, box2)

	// End World Declaration -----------

	// Init BVH
	world_ptrs := make([]^Hittable, len(world))
	defer delete(world_ptrs)

	for i in 0 ..< len(world) {
		world_ptrs[i] = &world[i]
	}

	bvh := new_bvh_node(world_ptrs, 0, uint(len(world)))
	bvh_world := []Hittable{Hittable(bvh)}


	// Render
	camera_render(&cam, bvh_world)
}

final_scene :: proc(render: Render_Details) {
	// Setup Camera
	cam := camera_default()
	cam.lookfrom = {470, 270, -600}
	cam.lookat = {278, 278, 0}
	cam.aspect_ratio = 1.0
	cam.image_width = render.image_width
	cam.samples_per_pixel = render.samples
	cam.focal_length_mm = 50
	cam.fstop = 20
	cam.focus_dist = 50
	cam.aperture = Aperture_Polygon {
		blades   = 6,
		rotation = 15,
	}
	cam.max_depth = render.depth
	cam.background = Color{0, 0, 0}

	// World
	world: [dynamic]Hittable
	defer delete(world)

	materials: [dynamic]^Material
	defer {
		for m in materials do free(m)
		delete(materials)
	}
	// Start World Declaration ---------


	box_sides: [dynamic][]Hittable
	defer {
		for s in box_sides do delete(s)
		delete(box_sides)
	}
	hittables: [dynamic]^Hittable
	defer {
		for h in hittables do free(h)
		delete(hittables)
	}

	// All this for the ground
	boxes1: [dynamic]Hittable
	defer {
		delete(boxes1)
	}

	ground := new(Material)
	append(&materials, ground)
	ground^ = make_burley(Color{0.48, 0.83, 0.53}, 0.8)
	boxes_per_side := 20
	for i in 0 ..< boxes_per_side {
		for j in 0 ..< boxes_per_side {
			w := 100.0
			x0 := -1000.0 + f64(i) * w
			z0 := -1000.0 + f64(j) * w
			y0 := 0.0
			x1 := x0 + w
			y1 := random_f64_range(1, 101)
			z1 := z0 + w

			append(
				&boxes1,
				Hittable(build_box(Point3{x0, y0, z0}, Point3{x1, y1, z1}, ground, &box_sides)),
			)
		}
	}

	boxes1_ptrs := make([]^Hittable, len(boxes1))
	for i in 0 ..< len(boxes1) do boxes1_ptrs[i] = &boxes1[i]
	defer delete(boxes1_ptrs)
	append(&world, Hittable(new_bvh_node(boxes1_ptrs, 0, len(boxes1))))
	// End Ground

	// Light
	light := new(Material)
	append(&materials, light)
	light^ = make_diffuse(Color{7, 7, 7})
	append(&world, build_quad(Point3{123, 554, 147}, Vec3{300, 0, 0}, Vec3{0, 0, 265}, light))

	// Moving Sphere
	lambertian := new(Material)
	append(&materials, lambertian)
	lambertian^ = make_burley(Color{0.7, 0.3, 0.1}, 0.8)
	center1 := Point3{400, 400, 200}
	center2 := center1 + Vec3{30, 0, 0}
	append(&world, build_moving_sphere(center1, center2, 50, lambertian))

	// Glass Sphere
	dielectric := new(Material)
	append(&materials, dielectric)
	dielectric^ = Dielectric{1.5}
	append(&world, build_sphere(Point3{260, 150, 45}, 50, dielectric))

	// Metal Sphere
	metal := new(Material)
	append(&materials, metal)
	metal^ = make_metal(Color{0.8, 0.8, 0.9}, 1.0)
	append(&world, build_sphere(Point3{0, 150, 145}, 50, metal))

	// Blue Shiney Ball
	boundary := Hittable(build_sphere(Point3{360, 150, 145}, 70, dielectric))
	append(&world, boundary)
	boundary_shine := new(Hittable)
	boundary_shine^ = Hittable(boundary)
	append(&world, build_constant_medium(boundary_shine, 0.2, Color{0.2, 0.4, 0.9}, &materials))

	// Foggy Atmosphere
	boundary2 := new(Hittable)
	boundary2^ = Hittable(build_sphere(Point3{0, 0, 0}, 5000, dielectric))

	append(&world, build_constant_medium(boundary2, 0.0001, Color{1, 1, 1}, &materials))

	// Earth!!!
	emat := new(Material)
	append(&materials, emat)
	// Get Earth Texture
	ok: bool
	earth_texture := new(Image)
	earth_texture^, ok = load_image("./images/planets/2k_earth_daymap.jpg"); assert(ok)
	defer destroy_image(earth_texture)
	emat^ = make_burley(image_texture(earth_texture), 0)
	append(&world, build_sphere(Point3{400, 200, 400}, 100, emat))

	// Perlin Noise Sphere
	pertext := new(Material)
	append(&materials, pertext)
	pertext^ = make_burley(noise_texture(0.2), 0.6)
	append(&world, build_sphere(Point3{220, 280, 300}, 80, pertext))

	// Weird cube of spheres
	boxes2: [dynamic]Hittable
	defer {
		delete(boxes2)
	}
	white := new(Material)
	append(&materials, white)
	white^ = make_burley(Color{.73, .73, .73}, 0.5)

	ns := 1000
	for k in 0 ..< ns {
		append(&boxes2, Hittable(build_sphere(random_vec3_range(0, 165), 10, white)))
	}
	boxes2_ptrs := make([]^Hittable, len(boxes2))
	for box in 0 ..< len(boxes2) do boxes2_ptrs[box] = &boxes2[box]
	defer {
		delete(boxes2_ptrs)
	}

	boxes2_bvh := new(Hittable)
	boxes2_bvh^ = Hittable(new_bvh_node(boxes2_ptrs[:], 0, len(boxes2_ptrs)))

	boxes2_instance := make_instance(boxes2_bvh, Vec3{-100, 270, 395}, Vec3{0, 15, 0})

	append(&world, boxes2_instance)
	// End Weird cube of spheres

	// append(&hittables)

	// End World Declaration -----------

	// Init BVH
	world_ptrs := make([]^Hittable, len(world))
	defer delete(world_ptrs)

	for i in 0 ..< len(world) {
		world_ptrs[i] = &world[i]
	}

	bvh := new_bvh_node(world_ptrs, 0, uint(len(world)))
	bvh_world := []Hittable{Hittable(bvh)}


	// Render
	camera_render(&cam, bvh_world)
}

package raytracer

import "core:os"

render_world :: proc(
	world: int = 10,
	render: Render_Details = {image_width = 600, samples = 125, depth = 50},
) {
	// Set global after runtime
	CORE_COUNT = os.get_processor_core_count()

	scene: Scene
	cam: Camera

	render_overwrite := render

	switch world {

	case 1:
		scene, cam = world_many_spheres(true)
	case 2:
		scene, cam = world_many_spheres(false)
	case 3:
		scene, cam = world_checkered_spheres()
	case 4:
		scene, cam = world_earth()
	case 5:
		scene, cam = world_perlin_spheres()
	case 6:
		scene, cam = world_quads()
	case 7:
		scene, cam = world_simple_light()
	case 8:
		scene, cam = world_cornell_box()
	case 9:
		scene, cam = world_cornell_smoke()
	case 10:
		scene, cam = final_scene()
		render_overwrite.image_width = 800
		render_overwrite.samples = 100000
		render_overwrite.depth = 40
	case 11:
		scene, cam = final_scene()
		render_overwrite.image_width = 400
		render_overwrite.samples = 250
		render_overwrite.depth = 4
	}

	cam.image_width = render_overwrite.image_width
	cam.samples_per_pixel = render_overwrite.samples
	cam.max_depth = render_overwrite.depth


	render_to_ppm(&cam, scene.bvh_world[:])

	defer scene_destroy(&scene)
}

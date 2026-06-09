package raytracer

import "core:os"

render_world :: proc(
	world: int = 10,
	render: Render_Details = {image_width = 600, samples = 125, depth = 50},
) {
	// Set global after runtime
	CORE_COUNT = os.get_processor_core_count()

	switch world {
	case 1:
		world_many_spheres(render, true)
	case 2:
		world_checkered_spheres(render)
	case 3:
		world_earth(render)
	case 4:
		world_perlin_spheres(render)
	case 5:
		world_quads(render)
	case 6:
		world_simple_light(render)
	case 7:
		world_cornell_box(render)
	case 8:
		world_cornell_smoke(render)
	case 9:
		final_scene(Render_Details{800, 10000, 40})
	case 10:
		final_scene(Render_Details{400, 250, 4})
	}
}

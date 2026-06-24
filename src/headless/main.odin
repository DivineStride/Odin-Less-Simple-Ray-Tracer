package headless

import rt "../raytracer/"
import "core:flags"
import "core:fmt"
import "core:log"
import "core:math"
import "core:os"
import "core:slice"

Headless_Flags :: struct {
	world:   int `usage:"Scene to render (1-11)"`,
	width:   int `usage:"Image width in pixels"`,
	samples: int `usage:"Samples per pixel"`,
	depth:   int `usage:"Maximum ray bounce depth"`,
	threads: int `usage:"Thread count override (0 = use all cores)"`,
}

f :: proc(d: rt.Vec3) -> f64 {
	// x := cos(2.0 * math.PI * r1) 2.0 * math.sqrt(r2 * (1 - r2))
	// y := cos(2.0 * math.PI * r1) 2.0 * math.sqrt(r2 * (1 - r2))
	cos_theta := d.z
	return cos_theta * cos_theta * cos_theta
}

icd :: proc(d: f64) -> f64 {
	return 8.0 * math.pow(d, 1.0 / 3.0)
}

pdf :: proc(d: rt.Vec3) -> f64 {
	return d.z / math.PI
}

main :: proc() {
	logger := log.create_console_logger()
	context.logger = logger

	opts := Headless_Flags {
		world   = 11,
		width   = 600,
		samples = 125,
		depth   = 50,
		threads = 0,
	}
	flags.parse_or_exit(&opts, os.args, .Unix)

	rt.set_processor_core_count(opts.threads)

	render_details := rt.Render_Details {
		image_width = opts.width,
		samples     = opts.samples,
		depth       = opts.depth,
	}

	rt.render_world(opts.world, render_details)
	// N := 1000000
	// sum := 0.0
	//
	// for i in 0 ..< N {
	// 	d := rt.random_cosine_direction()
	// 	sum += f(d) / pdf(d)
	// }
	//
	// fmt.printfln("PI/2 = %.12v", math.PI / 2.0)
	// fmt.printfln("Estimate = %.12v", sum / f64(N))
}

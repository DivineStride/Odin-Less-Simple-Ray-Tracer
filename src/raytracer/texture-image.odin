package raytracer

import "core:fmt"
import "core:mem"
import "core:strings"
import stbi "vendor:stb/image"

Image :: struct {
	pixels:             []u8,
	allocator:          mem.Allocator,
	width:              int,
	height:             int,
	bytes_per_scanline: int,
	bytes_per_pixel:    int,
}

BYTES_PER_PIXEL :: 3

load_image :: proc(path: string, allocator := context.allocator) -> (Image, bool) {
	// Check environment vairable override first
	cpath := strings.clone_to_cstring(path)
	defer delete(cpath)

	width, height, channels: i32
	bpp :: 3
	fdata := stbi.loadf(cpath, &width, &height, &channels, bpp)
	if fdata == nil {
		fmt.eprintln("ERROR: Could not load image file: ", path)
		return {}, false
	}
	defer stbi.image_free(fdata)

	img := Image {
		allocator          = allocator,
		width              = int(width),
		height             = int(height),
		bytes_per_pixel    = bpp,
		bytes_per_scanline = int(width) * bpp,
	}

	total := int(width) * int(height) * bpp
	img.pixels = make([]u8, total, allocator)

	fslice := fdata[:total]
	for v, i in fslice {
		img.pixels[i] = u8(v * 255.0 + 0.5)
	}

	return img, true
}

destroy_image :: proc(img: ^Image) {
	delete(img.pixels, img.allocator)
	img^ = {}
}

clamp_pixel :: proc(x, low, high: int) -> int {
	if x < low do return low
	if x < high do return x
	return high - 1
}

image_pixel_data :: proc(img: Image, x, y: int) -> (r, g, b: u8) {
	color := [3]u8{255, 0, 255}

	if len(img.pixels) == 0 do return color[0], color[1], color[2]

	cx := clamp_pixel(x, 0, img.width)
	cy := clamp_pixel(y, 0, img.height)
	i := cy * img.bytes_per_scanline + cx * img.bytes_per_pixel

	return img.pixels[i], img.pixels[i + 1], img.pixels[i + 2]
}

image_texture_value :: proc(img: Image, u, v: f64, p: Point3) -> Color {
	// Cyan sentinel for missing data
	if img.pixels == nil do return Color{0, 1, 1}

	// Clamp UV to [0,1]
	u := clamp(Interval{0, 1}, u)
	v := 1.0 - clamp(Interval{0, 1}, v) // flip v

	i := int(u * f64(img.width))
	j := int(v * f64(img.height))
	r, g, b := image_pixel_data(img, i, j)

	color_scale := 1.0 / 255.0

	return {f64(r) * color_scale, f64(g) * color_scale, f64(b) * color_scale}
}

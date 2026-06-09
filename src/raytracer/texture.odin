package raytracer

import "core:math"

Color_Texture :: struct {
	albedo: Color,
}

Checker_Texture :: struct {
	inv_scale: f64,
	even, odd: ^Texture,
}

Image_Texture_Ref :: struct {
	data: ^Image,
}

Noise_Texture_Ref :: struct {
	data: ^Noise_Texture,
}

Texture :: union {
	Color_Texture,
	Checker_Texture,
	Image_Texture_Ref,
	Noise_Texture_Ref,
}

texture_value :: proc(tex: Texture, u, v: f64, p: Point3) -> Color {
	switch t in tex {
	case Color_Texture:
		return t.albedo
	case Checker_Texture:
		return checker_texture_value(t, u, v, p)
	case Image_Texture_Ref:
		return image_texture_value(t.data^, u, v, p)
	case Noise_Texture_Ref:
		return noise_texture_value(t.data, u, v, p)
	}

	return {}
}

checker_texture_value :: proc(tex: Checker_Texture, u, v: f64, p: Point3) -> Color {
	xInteger := int(math.floor(tex.inv_scale * p.x))
	yInteger := int(math.floor(tex.inv_scale * p.y))
	zInteger := int(math.floor(tex.inv_scale * p.z))

	isEven := (xInteger + yInteger + zInteger) % 2 == 0

	return isEven ? texture_value(tex.even^, u, v, p) : texture_value(tex.odd^, u, v, p)
}

solid_color :: proc {
	solid_color_albedo,
	solid_color_rgb,
}

solid_color_albedo :: proc(albedo: Color) -> Texture {
	return Texture(Color_Texture{albedo})
}

solid_color_rgb :: proc(red, green, blue: f64) -> Texture {
	return Texture(Color_Texture{{red, green, blue}})
}

checker_texture :: proc {
	checker_texture_textures,
	checker_texture_colors,
}

checker_texture_textures :: proc(scale: f64, even, odd: Texture) -> Texture {
	return Texture(
		Checker_Texture{inv_scale = 1.0 / scale, even = new_clone(even), odd = new_clone(odd)},
	)
}

checker_texture_colors :: proc(scale: f64, even, odd: Color) -> Texture {
	return checker_texture_textures(scale, solid_color(even), solid_color(odd))
}

image_texture :: proc(img: ^Image) -> Texture {
	return Texture(Image_Texture_Ref{data = img})
}

noise_texture :: proc(scale: f64 = 4) -> Texture {
	tex := new(Noise_Texture)
	tex.noise = perlin()
	tex.scale = scale

	return Texture(Noise_Texture_Ref{tex})
}

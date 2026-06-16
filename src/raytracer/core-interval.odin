package raytracer

import "core:math"

INTERVAL_EMPTY :: Interval {
	min = math.INF_F64,
	max = -math.INF_F64,
}

INTERVAL_UNIVERSE :: Interval {
	min = -math.INF_F64,
	max = math.INF_F64,
}

Interval :: struct {
	min, max: f64,
}

interval_size :: proc(i: Interval) -> f64 {
	return i.max - i.min
}

interval_union :: proc(a: Interval, b: Interval) -> Interval {
	return Interval{min = a.min <= b.min ? a.min : b.min, max = a.max >= b.max ? a.max : b.max}
}

contains :: proc(i: Interval, x: f64) -> bool {
	return i.min <= x && x <= i.max
}

surrounds :: proc(i: Interval, x: f64) -> bool {
	return i.min < x && x < i.max
}

expand :: proc(i: Interval, delta: f64) -> Interval {
	padding := delta / 2
	return Interval{i.min - padding, i.max + padding}
}

clamp :: proc(i: Interval, x: f64) -> f64 {
	if x < i.min {return i.min}
	if x > i.max {return i.max}
	return x
}

interval_offset :: proc(i: Interval, d: f64) -> Interval {
	return Interval{i.min + d, i.max + d}
}

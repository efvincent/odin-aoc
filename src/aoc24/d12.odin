package aoc24

import "../util"
import "core:fmt"
import "core:slice"
import conv "core:strconv"
import "core:strings"

@(private = "file")
Puz :: struct {
	data:    []u8,
	maxx:    int,
	maxy:    int,
	plots:   map[int]Region, // key = plot, value = region it's in
	regions: [dynamic]Region, // list of all regions
}

@(private = "file")
Region :: struct {
	plant: u8,
	plots: map[int]Point,
}

@(private = "file")
Point :: [2]int

@(private = "file")
Direction :: enum (u8) {
	N,
	E,
	S,
	W,
}

solve_d12 :: proc(part: util.Part, data: string) -> string {
	switch part {
	case .p1:
		return solve1(data)
	case .p2:
		return solve2(data)
	}
	return ""
}

@(private = "file")
parse :: proc(data: string) -> Puz {
	span := strings.index(data, "\n")
	puz := Puz {
		data    = transmute([]u8)(data),
		maxx    = span,
		maxy    = (len(data) / span),
		plots   = make_map(map[int]Region),
		regions = make_dynamic_array([dynamic]Region),
	}
	return puz
}

@(private = "file")
solve2 :: proc(data: string) -> string {
	return ""
}

@(private = "file")
solve1 :: proc(data: string) -> string {
	puz := parse(data)
	ppuz(&puz)
	for y in 0 ..< puz.maxy {
		for x in 0 ..< puz.maxx {
			p := Point{x, y}
			process_plot(&puz, p)
		}
	}
	return ""
}

process_plot :: proc(puz: ^Puz, p: Point) {
	// is this plot in a region?
	key := hash(p)
	if key in puz.plots {
		// yes, move along...
		return
	}
	// not in a region. Create a region for this
}

@(private = "file")
move :: proc(puz: Puz, from: Point, dir: Direction) -> (to: Point, ok: bool) {
	switch dir {
	case .N:
		to = from + Point{0, -1}
	case .S:
		to = from + Point{0, 1}
	case .E:
		to = from + Point{1, 0}
	case .W:
		to = from + Point{-1, 0}
	}
	if to.x > puz.maxx || to.y > puz.maxy || to.x < 0 || to.y < 0 {
		ok = false
	} else {
		ok = true
	}
	return to, ok
}

@(private = "file")
get :: proc(puz: Puz, p: Point) -> u8 {
	if p.x < 0 || p.x >= puz.maxx do return 0
	if p.y < 0 || p.y >= puz.maxx do return 0
	return puz.data[p.x + p.y * puz.maxx + p.y]
}

@(private = "file")
hash :: proc(p: Point) -> int {
	return 1000 * p.y + p.x
}

@(private = "file")
iterate_puz :: proc(
	puz: ^Puz,
	value_fn: proc(puz: ^Puz, point: Point, value: u8),
	row_fn: proc() = proc() {},
) {
	for y in 0 ..< puz.maxy {
		for x in 0 ..< puz.maxx {
			p := Point{x, y}
			value_fn(puz, p, get(puz^, p))
		}
		row_fn()
	}
}

@(private = "file")
ppuz :: proc(puz: ^Puz) {
	value_fn :: proc(_: ^Puz, p: Point, v: u8) {fmt.print(rune(v))}
	row_fn :: proc() {fmt.println()}
	iterate_puz(puz, value_fn, row_fn)
	fmt.println()
}

@(private = "file")
make_region :: proc(plant: u8) -> Region {
	return Region{plant = plant, plots = make_map(map[int]Point)}
}

@(private = "file")
delete_region :: proc(r: ^Region) {
	delete(r.plots)
}

@(private = "file")
delete_puz :: proc(puz: ^Puz) {
	delete_map(puz.plots)
	delete_dynamic_array(puz.regions)
}

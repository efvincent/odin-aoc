package aoc24

import "../util"
import "core:fmt"
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
	plant:              u8,
	plots:              map[int]Point,
	perimeter:          int,
	discount_perimeter: int,
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

@(private = "file")
CornerTest :: struct {
	delta: Point,
	dirs:  [2]Direction,
}

@(private = "file")
CORNER_TESTS :: [4]CornerTest {
	CornerTest{delta = {-1, -1}, dirs = {.E, .S}},
	CornerTest{delta = {1, -1}, dirs = {.W, .S}},
	CornerTest{delta = {1, 1}, dirs = {.W, .N}},
	CornerTest{delta = {-1, 1}, dirs = {.E, .N}},
}

@(private)
cost_part_1: int
cost_part_2: int

solve_d12 :: proc(part: util.Part, data: string) -> string {
	puz := solve(data)

	switch part {
	case .p1:
		if cost_part_1 == 0 {
			for region in puz.regions {
				cost_part_1 += region.perimeter * len(region.plots)
			}
		}
		return util.to_str(cost_part_1)
	case .p2:
		if cost_part_2 == 0 {
			for region in puz.regions {
				cost_part_2 += region.discount_perimeter * len(region.plots)
			}
		}
		return util.to_str(cost_part_2)
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
solve :: proc(data: string) -> Puz {
	puz := parse(data)
	defer delete_puz(&puz)
	for y in 0 ..< puz.maxy {
		for x in 0 ..< puz.maxx {
			p := Point{x, y}
			process_plot(&puz, p)
		}
	}
	return puz
}

@(private = "file")
process_plot :: proc(puz: ^Puz, plot: Point) {
	// is this plot in a region?
	key := hash(plot)
	if key in puz.plots {
		// yes, move along...
		return
	}
	// not in a region. Create a region for this and save it
	region := make_region(get(puz^, plot))
	region.plots[key] = plot
	puz.plots[key] = region

	// then fill the region
	fill_region(puz, &region, plot)
	calc_perimeter_part1(puz^, &region)
	calc_perimeter_part2(puz^, &region)
	append(&puz.regions, region)
}

@(private = "file")
fill_region :: proc(puz: ^Puz, region: ^Region, fill_from: Point) {
	// for each neighbor of the point
	for dir in Direction {
		neighbor := move(puz^, fill_from, dir) or_continue
		neighbor_plant := get(puz^, neighbor)
		neighbor_key := hash(neighbor)
		if neighbor_plant == region.plant && !(neighbor_key in puz.plots) {
			// neighbor is the right kind of plant and is not in a region yet,
			// so add it to this region
			region.plots[neighbor_key] = neighbor
			puz.plots[neighbor_key] = region^
			// continue to find plots for this region from this new neighbor
			fill_region(puz, region, neighbor)
		}
	}
}

@(private = "file")
test_corner :: proc(puz: Puz, region: Region, p: Point, test: CornerTest) -> bool {
	test_plot := p + test.delta
	test_hash := hash(test_plot)

	// is test plot in region?
	_, test_in_region := region.plots[test_hash]

	// check the 2 neighbors from the directions in this test to see
	// if they're in our region
	_, d1 := region.plots[hash(delta_point(test_plot, test.dirs[0]))]
	_, d2 := region.plots[hash(delta_point(test_plot, test.dirs[1]))]

	if !d1 && !d2 do return true // outside corner
	if d1 && d2 && !test_in_region do return true // inside corner

	return false
}

@(private = "file")
calc_perimeter_part2 :: proc(puz: Puz, region: ^Region) {
	for _, plot in region.plots {
		for test in CORNER_TESTS {
			if test_corner(puz, region^, plot, test) {
				region.discount_perimeter += 1
			}
		}
	}
}

@(private = "file")
calc_perimeter_part1 :: proc(puz: Puz, region: ^Region) {
	p := 0
	for _, plot in region.plots {
		for dir in Direction {
			neighbor, ok := move(puz, plot, dir)
			if !ok || get(puz, neighbor) != get(puz, plot) {
				p += 1
			}
		}
	}
	region.perimeter = p
}

@(private = "file")
delta_point :: proc(point: Point, dir: Direction) -> Point {
	switch dir {
	case .N:
		return point + Point{0, -1}
	case .S:
		return point + Point{0, 1}
	case .E:
		return point + Point{1, 0}
	case .W:
		return point + Point{-1, 0}
	}
	return point
}

@(private = "file")
move :: proc(puz: Puz, from: Point, dir: Direction) -> (to: Point, ok: bool) {
	to = delta_point(from, dir)
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
	for region in puz.regions do delete_map(region.plots)
	delete_dynamic_array(puz.regions)
}

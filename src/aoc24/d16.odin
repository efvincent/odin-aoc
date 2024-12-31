package aoc24

import "../util"
import pq "core:container/priority_queue"
import "core:fmt"
import "core:math"
import "core:slice"
import "core:strings"

@(private = "file")
Point :: [2]int

@(private = "file")
// a set of points
PointSet :: map[Point]struct {}

@(private = "file")
// possible directions that can be traversed
Dir :: enum {
	N = 0,
	E = 1,
	S = 2,
	W = 3,
}

@(private = "file")
Content :: enum {
	Wall    = '█',
	Space   = ' ',
	Start   = 'S',
	End     = 'E',
	Visited = 'O',
}

@(private = "file")
Node :: struct {
	pos:     Point,
	dir:     Dir,
	cost:    int,
	pred:    Point,
	visited: bool,
}

@(private = "file")
Grid :: struct {
	max:     [2]int,
	content: []Content,
	start:   Point,
	end:     Point,
}

@(private = "file")
Puz :: struct {
	maxx:  int,
	grid:  []Content,
	maxy:  int,
	start: Point,
	end:   Point,
}

solve_d16 :: proc(data: string) -> (int, int) {
	grid := parse(data)
	defer delete(grid.content)
	nodes := part1(&grid)
	result, res := part2(&grid, nodes)
	defer delete(nodes)
	pgrid(grid)
	fmt.printfln("set size: %v, res: %v", len(result), res)
	return nodes[grid.end].cost, len(result)
}

// -------------------------------------------------------------------------

@(private = "file")
part2 :: proc(grid: ^Grid, nodes: map[Point]Node) -> (PointSet, int) {

	result := make(PointSet, allocator = context.temp_allocator)
	result[grid.start] = {}
	result[grid.end] = {}
	ncount := 1

	queue: pq.Priority_Queue(Node)
	pq.init(&queue, node_less_cost, node_swap, allocator = context.temp_allocator)
	end_node := nodes[grid.end]
	pq.push(&queue, end_node)

	for {

		// if the shift from opposite(cur.dir) cost - 1 is a HIT, enqueue with cost - 1
		// otherwise enqueue with cost - 1001

		if pq.len(queue) == 0 do break
		cur := pq.pop(&queue)
		if cur.pos == grid.start do continue
		for dir in Dir {
			candidate, ok := nodes[shift(cur.pos, dir)]
			allow_cost := dir == opposite_of(cur.dir) ? cur.cost - 1 : cur.cost - 1001

			// if candidate.cost == allow_cost || (candidate.cost % 1000) == (allow_cost % 1000) {
			if candidate.cost == allow_cost || candidate.cost == allow_cost - 1000 {
				if candidate.cost != allow_cost {
					fmt.printfln(
						"mod hit: candidate.cost %v, allow_cost %v",
						candidate.cost,
						allow_cost,
					)
				}
				new_cost := dir == opposite_of(cur.dir) ? cur.cost - 1 : cur.cost - 1001
				if new_cost < 0 do continue
				new_node := Node {
					pos  = candidate.pos,
					cost = allow_cost,
					dir  = opposite_of(dir),
				}
				pq.push(&queue, new_node)
				put(grid, cur.pos, .Visited)
				if !(cur.pos in result) do ncount += 1
				result[cur.pos] = {}

			}
		}
	}

	return result, ncount
}

@(private = "file")
part1 :: proc(grid: ^Grid) -> map[Point]Node {
	queue: pq.Priority_Queue(Node)
	pq.init(&queue, node_less_cost, node_swap)

	// initialize all the nodes
	nodes := make(map[Point]Node)
	for y in 0 ..< grid.max.y {
		for x in 0 ..< grid.max.x {
			p := Point{x, y}
			if c := get(grid^, p); c != nil && c != .Wall {
				n := Node {
					pos     = p,
					dir     = .E,
					cost    = c == .Start ? 0 : max(int),
					visited = false,
				}
				nodes[p] = n
			}
		}
	}
	pq.push(&queue, nodes[grid.start])

	for {
		// set current node to the lowest cost node, should be the start node
		// the first time through. From then on, it's the lowest cost node
		if pq.len(queue) == 0 do break
		cur := pq.pop(&queue)

		// consider all unvisited neighbors. 
		for dir_to_nbr in Dir {

			// neighbor position determined by moving in the dir to neighbor from current position
			nbr_pos := shift(cur.pos, dir_to_nbr)

			// cost change due to change in direction. Delta cost < 0 means invalid change in dir
			delta_cost := cost_change(cur.dir, dir_to_nbr)
			if delta_cost < 0 do continue

			// get the neighbor node and if it's not yet visited (no loops) then we'll examine it
			if nbr, ok := nodes[nbr_pos]; ok && !nbr.visited {
				// how much would it cost to get to this neighbor?
				new_cost := cur.cost + delta_cost

				// if the new cost is less than the current cost, then we've found a cheaper way
				// to get to the neighbor. Set the neighbor's new cost and the direction we were
				// going when we arrived at the neighbor, as well as the predecessor of the neighbor
				// which is the current node. We also add the node to the set of nodes that make up
				// the shortest path
				if new_cost <= nbr.cost {
					new_nbr := Node {
						cost    = new_cost,
						pos     = nbr_pos,
						dir     = dir_to_nbr,
						pred    = cur.pos,
						visited = false,
					}
					nodes[nbr_pos] = new_nbr
					pq.push(&queue, new_nbr)
				}
			}
		}

		// mark current node as visited. it's already removed from the
		// queue from the pop at the start of the loop
		new_cur := nodes[cur.pos]
		new_cur.visited = true
		nodes[cur.pos] = new_cur
	}

	pgrid(grid^)
	fmt.println("------------------- END PART 1 -------------------")
	return nodes
}

// -------------------------------------------------------------------------

@(private = "file")
right :: proc(dir: Dir) -> Dir {
	switch dir {
	case .E:
		return .S
	case .N:
		return .E
	case .W:
		return .N
	case .S:
		return .W
	}
	panic("invariant failed")
}

@(private = "file")
left :: proc(dir: Dir) -> Dir {
	switch dir {
	case .E:
		return .N
	case .N:
		return .W
	case .W:
		return .S
	case .S:
		return .E
	}
	panic("invariant failed")
}


@(private = "file")
parse :: proc(data: string) -> Grid {
	grid: Grid
	raw_lines := strings.split_lines(data, allocator = context.temp_allocator)
	grid.max.y = len(raw_lines)
	first := true
	cost: int
	for raw_line, y in raw_lines {
		if first {
			first = false
			grid.max.x = len(raw_line)
			grid.content = make([]Content, grid.max.y * grid.max.x)
		}
		for char, x in raw_line {
			loc := Point{x, y}
			if char == 'S' {
				grid.start = loc
			} else if char == 'E' {
				grid.end = loc
			}
			char_mod: rune
			if char == '.' do char_mod = ' '
			else if char == '#' do char_mod = '█'
			else do char_mod = char
			put(&grid, loc, Content(char_mod))
		}
	}
	return grid
}

@(private = "file")
cost_change :: proc(a: Dir, b: Dir) -> int {
	d1 := int(a)
	d2 := int(b)
	if d1 == d2 do return 1
	diff := int(math.abs(d1 - d2))
	dist := math.min(diff, 4 - diff)
	if dist == 1 do return 1001
	return -1
}

@(private = "file")
opposite_of :: proc(d: Dir) -> Dir {
	switch d {
	case .N:
		return .S
	case .S:
		return .N
	case .E:
		return .W
	case .W:
		return .E
	}
	panic("impossible")
}

@(private = "file")
can_move :: proc(
	grid: Grid,
	visited: map[int]struct {},
	loc: Point,
	dir: Dir,
	check_visited: bool = true,
) -> (
	moved: Point,
	ok: bool,
) {
	moved = shift(loc, dir)
	if get(grid, moved) == Content.Wall do return loc, false
	if inbounds(grid, loc) && (!check_visited || !(hash(moved) in visited)) do return moved, true
	return loc, false
}

@(private = "file")
pgrid :: proc(grid: Grid) {
	for y in 0 ..< grid.max.y {
		for x in 0 ..< grid.max.x {
			p := Point{x, y}
			c := rune(get(grid, p))
			if c == rune(Content.Space) {
				fmt.printf("  ")
			} else if c == rune(Content.Visited) {
				fmt.printf("O ")
			} else {
				fmt.printf("%v%v", c, c)
			}
		}
		fmt.println()
	}
	fmt.printfln(
		"Start: (%v,%v)\nEnd:   (%v,%v)",
		grid.start.x,
		grid.start.y,
		grid.end.x,
		grid.end.y,
	)
}

@(private = "file")
pgridx :: proc(grid: Grid, nodes: map[Point]Node = nil) {
	for y in 0 ..< grid.max.y {
		for x in 0 ..< grid.max.x {
			p := Point{x, y}
			c := rune(get(grid, p))
			if c == rune(Content.Space) {
				if nodes[p].cost < max(int) {
					fmt.printf(" %4v ", nodes[p].cost)
				} else {
					fmt.printf("  MAX ")
				}
			} else if c == rune(Content.Visited) {
				fmt.printf("*%4v ", nodes[p].cost)
			} else {
				fmt.printf("%v%v%v%v%v%v", c, c, c, c, c, c)
			}
		}
		fmt.println()
	}
	fmt.printfln(
		"Start: (%v,%v)\nEnd:   (%v,%v)",
		grid.start.x,
		grid.start.y,
		grid.end.x,
		grid.end.y,
	)
}

@(private = "file")
inbounds :: #force_inline proc(grid: Grid, loc: Point) -> bool {
	return !(loc.x < 0 || loc.x >= grid.max.x || loc.y < 0 || loc.y >= grid.max.y)
}

@(private = "file")
get :: #force_inline proc(grid: Grid, loc: Point) -> Content {
	if !inbounds(grid, loc) do return nil
	return grid.content[loc.y * grid.max.y + loc.x]
}

@(private = "file")
put :: #force_inline proc(grid: ^Grid, loc: Point, content: Content) -> bool {
	if !inbounds(grid^, loc) do return false
	grid.content[loc.y * grid.max.y + loc.x] = content
	return true
}

@(private = "file")
hash :: proc(loc: Point, dir: Dir = .N) -> int {
	return int(dir) * 1000000 + loc.y * 1000 + loc.x
}

@(private = "file")
destroy_puz :: proc(puz: ^Puz) {
	delete(puz.grid)
}

@(private = "file")
shift :: #force_inline proc(loc: Point, dir: Dir) -> Point {
	new_loc: Point
	switch dir {
	case .N:
		new_loc = loc + {0, -1}
	case .S:
		new_loc = loc + {0, 1}
	case .E:
		new_loc = loc + {1, 0}
	case .W:
		new_loc = loc + {-1, 0}
	}
	return new_loc
}

@(private = "file")
node_less_cost :: proc(a, b: Node) -> bool {
	return a.cost < b.cost
}

@(private = "file")
node_swap :: proc(q: []Node, i, j: int) {q[i], q[j] = q[j], q[i]}

@(private = "file")
add_point :: proc(ps: ^PointSet, p: Point) {
	ps[p] = {}
}

@(private = "file")
remove_point :: proc(ps: ^PointSet, p: Point) {
	delete_key(ps, p)
}

#+private file
package aoc24

import pq "core:container/priority_queue"
import "core:fmt"
import "core:math"
import "core:strings"

Point :: [2]int

PointSet :: map[Point]struct {}

Dir :: enum {
	N = 0,
	E = 1,
	S = 2,
	W = 3,
}

Content :: enum {
	Wall    = '█',
	Space   = ' ',
	Start   = 'S',
	End     = 'E',
	Visited = 'O',
}

Node :: struct {
	pos:     Point,
	dir:     Dir,
	cost:    int,
	pred:    Point,
	visited: bool,
}

NodeMap :: map[Point]^Node

Grid :: struct {
	max:     [2]int,
	content: []Content,
	start:   Point,
	end:     Point,
}

Puz :: struct {
	maxx:  int,
	grid:  []Content,
	maxy:  int,
	start: Point,
	end:   Point,
}

@(private = "package")
solve_d16 :: proc(data: string) -> (int, int) {
	grid := parse(data)
	defer delete(grid.content)
	nodes := part1(&grid)
	res := part2(&grid, nodes)
	defer delete(nodes)
	return nodes[grid.end].cost, len(res)
}

// -------------------------------------------------------------------------

part2 :: proc(grid: ^Grid, nodes: NodeMap) -> PointSet {

	result := make(PointSet, allocator = context.temp_allocator)
	result[grid.start] = {}
	result[grid.end] = {}

	queue: pq.Priority_Queue(^Node)
	pq.init(&queue, node_less_cost, node_swap, allocator = context.temp_allocator)
	end_node := nodes[grid.end]
	pq.push(&queue, end_node)
	for {

		if pq.len(queue) == 0 do break
		cur := pq.pop(&queue)
		if cur.pos == grid.start do continue
		for dir in Dir {
			candidate := nodes[shift(cur.pos, dir)] or_continue
			allow_cost := dir == opposite_of(cur.dir) ? cur.cost - 1 : cur.cost - 1001

			if candidate.cost == allow_cost || candidate.cost == allow_cost - 1000 {
				new_cost := dir == opposite_of(cur.dir) ? cur.cost - 1 : cur.cost - 1001
				if new_cost < 0 do continue
				new_node := Node {
					pos  = candidate.pos,
					cost = allow_cost,
					dir  = opposite_of(dir),
				}
				pq.push(&queue, &new_node)
				put(grid, cur.pos, .Visited)
				result[cur.pos] = {}
			}
		}
	}

	return result
}

part1 :: proc(grid: ^Grid) -> NodeMap {
	queue: pq.Priority_Queue(^Node)
	pq.init(&queue, node_less_cost, node_swap, capacity = 100, allocator = context.temp_allocator)
	// initialize all the nodes
	nodes := make(NodeMap)
	for y in 0 ..< grid.max.y {
		for x in 0 ..< grid.max.x {
			p := Point{x, y}
			if c := get(grid^, p); c != nil && c != .Wall {
				n := new(Node, context.temp_allocator)
				n.pos = p
				n.dir = .E
				n.cost = c == .Start ? 0 : max(int)
				n.visited = false
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
					new_nbr := new(Node, context.temp_allocator)
					new_nbr.cost = new_cost
					new_nbr.pos = nbr_pos
					new_nbr.dir = dir_to_nbr
					new_nbr.pred = cur.pos
					new_nbr.visited = false
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
	return nodes
}

// -------------------------------------------------------------------------

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


parse :: proc(data: string) -> Grid {
	grid: Grid
	raw_lines := strings.split_lines(data, allocator = context.temp_allocator)
	grid.max.y = len(raw_lines)
	first := true
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

cost_change :: proc(a: Dir, b: Dir) -> int {
	d1 := int(a)
	d2 := int(b)
	if d1 == d2 do return 1
	diff := int(math.abs(d1 - d2))
	dist := math.min(diff, 4 - diff)
	if dist == 1 do return 1001
	return -1
}

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

inbounds :: #force_inline proc(grid: Grid, loc: Point) -> bool {
	return !(loc.x < 0 || loc.x >= grid.max.x || loc.y < 0 || loc.y >= grid.max.y)
}

get :: #force_inline proc(grid: Grid, loc: Point) -> Content {
	if !inbounds(grid, loc) do return nil
	return grid.content[loc.y * grid.max.y + loc.x]
}

put :: #force_inline proc(grid: ^Grid, loc: Point, content: Content) -> bool {
	if !inbounds(grid^, loc) do return false
	grid.content[loc.y * grid.max.y + loc.x] = content
	return true
}

hash :: proc(loc: Point, dir: Dir = .N) -> int {
	return int(dir) * 1000000 + loc.y * 1000 + loc.x
}

destroy_puz :: proc(puz: ^Puz) {
	delete(puz.grid)
}

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

node_less_cost :: proc(a, b: ^Node) -> bool {
	return a.cost < b.cost
}

node_swap :: proc(q: []^Node, i, j: int) {q[i], q[j] = q[j], q[i]}

add_point :: proc(ps: ^PointSet, p: Point) {
	ps[p] = {}
}

remove_point :: proc(ps: ^PointSet, p: Point) {
	delete_key(ps, p)
}

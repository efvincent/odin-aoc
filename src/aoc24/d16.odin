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

solve_d16 :: proc(part: util.Part, data: string) -> string {
	switch part {
	case .p1:
		return solve1(data)
	case .p2:
		return solve2(data)
	}
	return ""
}

@(private = "file")
solve2 :: proc(data: string) -> string {
	grid := parse(data)
	defer delete(grid.content)
	nodes := part1(&grid)
	target_cost := nodes[grid.end].cost
	sln_nodes := make(PointSet, allocator = context.temp_allocator)
	part2(&grid, nodes, &sln_nodes, nodes[grid.start], target_cost)
	pgrid(grid)
	return util.to_str(len(sln_nodes))
}

@(private = "file")
solve1 :: proc(data: string) -> string {
	grid := parse(data)
	defer delete(grid.content)
	nodes := part1(&grid)
	pgrid(grid)
	return util.to_str(nodes[grid.end].cost)
}

// -------------------------------------------------------------------------

@(private = "file")
part2 :: proc(
	grid: ^Grid,
	nodes: map[Point]Node,
	sln_nodes: ^PointSet,
	cur: Node,
	target_cost: int,
) -> bool {
	part_of_sln_path := false
	if cur == nodes[grid.end] {
		// we've reached the end and not exceeded cost!
		add_point(sln_nodes, cur.pos)
		return true
	}
	for dir_to_nbr in Dir {
		if nbr, ok := nodes[shift(cur.pos, dir_to_nbr)]; ok && dir_to_nbr != opposite_of(cur.dir) {
			// does adding its cost to current cost exceed target?
			new_cost := cur.cost + 1 + cost_change(cur.dir, dir_to_nbr)
			if new_cost > target_cost {
				// this branch is invalid
				return false
			}
			// adding this node doesn't blow up target cost
			nbr.dir = dir_to_nbr
			nbr.cost = new_cost
			if part2(grid, nodes, sln_nodes, nbr, target_cost) {
				// we're part of a solution path!
				part_of_sln_path = true

				// only add us as part of the path if we're not also the starting point
				if cur.pos != grid.start do put(grid, cur.pos, .Visited)
				add_point(sln_nodes, cur.pos)
			}
		}
	}
	/* 	algo:
			- starting from the current node
			- check each of the neighbors -> nbr
				- does adding it exceed max cost?
					- no:
						nbr.dir = dir to nbr
						nbr.cost = cur cost + cost_change(cur.dir, nbr.dir)
						- do we find one or more solution paths from this neighbor?
							-> ifpart2(grid, sln_nodes, nbr, target_cost)
							- yes:
								we're part of a solution path (we'll return true)
								add cur to sln_nodes
								check next neighbor
					- yes:
						this branch is invalid
						return 0, false
			- after checking all neighbors
			- if any of them returned true, then we return true, otherwise we return false
			- when it's all done, the answer is the length of the PointSet
	*/
	return part_of_sln_path
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
			// get the neighbor node and if it's not yet visited (no loops) then we'll examine it
			if nbr, ok := nodes[nbr_pos]; ok && !nbr.visited {
				// how much would it cost to get to this neighbor?
				new_cost := cur.cost + 1 + cost_change(cur.dir, dir_to_nbr)

				// if the new cost is less than the current cost, then we've found a cheaper way
				// to get to the neighbor. Set the neighbor's new cost and the direction we were
				// going when we arrived at the neighbor, as well as the predecessor of the neighbor
				// which is the current node. We also add the node to the set of nodes that make up
				// the shortest path
				if new_cost < nbr.cost {
					nbr.cost = new_cost
					nbr.dir = dir_to_nbr
					nbr.pred = cur.pos
					nodes[nbr.pos] = nbr
					pq.push(&queue, nbr)
				}
			}
		}

		// mark current node as visited. it's already removed from the
		// queue from the pop at the start of the loop
		cur.visited = true
		nodes[cur.pos] = cur
	}

	// update grid with visited content by backtracking from the end through the preds. This is
	// only needed for printing the grid
	cur := nodes[grid.end]
	path_count := make(map[Point]struct {}, allocator = context.temp_allocator)
	for {
		if cur.pred == {0, 0} do break
		cur = nodes[cur.pred]
		put(grid, cur.pos, .Visited)
		if cur.pos == grid.end do continue
		if cur.pos == grid.start do break
	}
	return nodes
}

// -------------------------------------------------------------------------

@(private = "file")
dir_of :: proc(p2: Point, p1: Point) -> Dir {
	diff := p1 - p2
	dir: Dir
	switch (diff) {
	case {1, 0}:
		dir = .E
	case {-1, 0}:
		dir = .W
	case {0, 1}:
		dir = .S
	case {0, -1}:
		dir = .N
	}
	return dir
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
	if d1 == d2 do return 0
	diff := int(math.abs(d1 - d2))
	dist := math.min(diff, 4 - diff)
	if dist == 1 do return 1000
	return 2000
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
pgrid :: proc(grid: Grid, visited: map[int]struct {} = nil) {
	for y in 0 ..< grid.max.y {
		for x in 0 ..< grid.max.x {
			p := Point{x, y}
			c := rune(get(grid, p))
			if c == rune(Content.Wall) {
				fmt.printf("%v%v", c, c)
			} else {
				fmt.printf("%v ", c)
			}
			// } else if visited != nil && c == rune(Content.Space) && hash(p) in visited {
			// 	fmt.print(". ")
			// } else {
			// 	fmt.printf("%v ", c)
			// }
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

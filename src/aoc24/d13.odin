package aoc24

import "../util"
import "core:math"
import "core:strconv"
import "core:strings"

@(private = "file")
Button :: enum {
	A = 0,
	B = 1,
}

@(private = "file")
Axis :: enum {
	X = 0,
	Y = 1,
}

@(private = "file")
P2_OFFSET: f64 = 10000000000000.0

solve_d13 :: proc(part: util.Part, data: string) -> string {

	// doing everything on the stack this time since it's effectively
	// a once pass approach, not a lot of point to the usual rigor.

	coefficient_matrix := [][]f64{{0.0, 0.0}, {0.0, 0.0}}

	prize_point := [Axis]f64 {
		.X = 0,
		.Y = 0,
	}

	result: int = 0

	raw_lines := strings.split_lines(data, allocator = context.temp_allocator)

	for raw_line in raw_lines {

		// not loving this string hack parse approach, but quick & dirty
		// is my approach to this one. This approach relies on the exact formatting
		// of the input more so than the usual approach I feel. Anything off by one
		// char is going to blow this up; but don't care, these linear algebra
		// puzzles are no fun :/

		if strings.contains(raw_line, "Button A") {
			x, _ := strconv.parse_f64(raw_line[12:14])
			y, _ := strconv.parse_f64(raw_line[18:20])
			coefficient_matrix[0][0] = x
			coefficient_matrix[0][1] = y
		}

		if strings.contains(raw_line, "Button B") {
			x, _ := strconv.parse_f64(raw_line[12:14])
			y, _ := strconv.parse_f64(raw_line[18:20])
			coefficient_matrix[1][0] = x
			coefficient_matrix[1][1] = y
		}

		if !strings.contains(raw_line, "Prize:") do continue
		comma := strings.index(raw_line, ",")
		if comma == -1 do panic("error parsing")

		// get the coordinates of the prize
		prize_point[.X], _ = strconv.parse_f64(raw_line[9:comma])
		prize_point[.Y], _ = strconv.parse_f64(raw_line[comma + 4:])

		// only difference in part 2 is the offset added to the prize point location coords
		if part == .p2 {
			prize_point[.X] += P2_OFFSET
			prize_point[.Y] += P2_OFFSET
		}

		factor :=
			1.0 /
			(coefficient_matrix[0][0] * coefficient_matrix[1][1] -
					coefficient_matrix[0][1] * coefficient_matrix[1][0])

		inv_coefficient_matrix := [][]f64{{0.0, 0.0}, {0.0, 0.0}}
		inv_coefficient_matrix[0][0] = factor * coefficient_matrix[1][1]
		inv_coefficient_matrix[1][0] = factor * -coefficient_matrix[1][0]
		inv_coefficient_matrix[0][1] = factor * -coefficient_matrix[0][1]
		inv_coefficient_matrix[1][1] = factor * coefficient_matrix[0][0]

		sub_result: [Button]f64

		sub_result[.A] =
			inv_coefficient_matrix[0][0] * prize_point[.X] +
			inv_coefficient_matrix[1][0] * prize_point[.Y]
		sub_result[.B] =
			inv_coefficient_matrix[0][1] * prize_point[.X] +
			inv_coefficient_matrix[1][1] * prize_point[.Y]

		// Need to consider # of presses CLOSE TO integers! (for whole button presses)
		// because of floats, never getting exact ints!!
		frac: [Button]f64
		_, frac[.A] = math.modf(sub_result[.A])
		_, frac[.B] = math.modf(sub_result[.B])

		if (frac[.B] < 0.001 || frac[.B] > 0.999) && (frac[.A] < 0.001 || frac[.A] > 0.999) {
			result += int(math.round(sub_result[.A])) * 3 + int(math.round(sub_result[.B]))
		}
	}
	return util.to_str(result)
}

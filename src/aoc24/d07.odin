package aoc24

import "../util"
import "core:strconv"
import "core:strings"

@(private = "file")
Puz :: struct {
	answers:    []u128,
	term_lists: [][]u128,
}

@(private = "file")
Operator :: enum {
	PLUS,
	TIMES,
}

solve_d07 :: proc(part: util.Part, data: string) -> string {
	switch part {
	case .p1:
		return solve(data, false)
	case .p2:
		return solve(data, true)
	}
	return ""

}

@(private = "file")
parse :: proc(data: string) -> Puz {
	raw_lines := strings.split_lines(data, context.temp_allocator)

	puz := Puz {
		answers    = make_slice([]u128, len(raw_lines)),
		term_lists = make_slice([][]u128, len(raw_lines)),
	}

	for raw_line, line_idx in raw_lines {
		parts := strings.split(raw_line, ": ", context.temp_allocator)
		puz.answers[line_idx] = u128(strconv.atoi(parts[0]))

		raw_terms := strings.split(parts[1], " ", context.temp_allocator)
		puz.term_lists[line_idx] = make_slice([]u128, len(raw_terms))

		for raw_term, term_idx in raw_terms {
			puz.term_lists[line_idx][term_idx] = u128(strconv.atoi(raw_term))
		}
	}
	return puz
}

@(private = "file")
solve :: proc(data: string, check_concat: bool) -> string {
	puz := parse(data)
	defer {
		delete(puz.answers)
		for term in puz.term_lists {
			delete(term)
		}
		delete(puz.term_lists)
	}

	total := u128(0)
	for expected, idx in puz.answers {
		total += has_solution(expected, puz.term_lists[idx], check_concat) ? expected : 0
	}
	return util.to_str(total)
}

has_solution :: proc(
	expected: u128,
	terms: []u128,
	check_concat: bool = false,
	indent: int = 0,
) -> bool {
	term_len := len(terms)
	if term_len == 1 {
		if terms[0] == expected do return true
		return false
	}

	last_term := u128(terms[len(terms) - 1])
	if (expected % last_term == 0) {
		// last term can be mult w/ expected for the result
		ok := has_solution(expected / last_term, terms[:len(terms) - 1], check_concat, indent + 3)
		if ok do return true
	}
	ta := context.temp_allocator
	if check_concat {
		expected_str := util.to_str(expected, ta)
		last_term_str := util.to_str(last_term, ta)
		if strings.ends_with(expected_str, last_term_str) {
			new_expected_str := expected_str[:len(expected_str) - len(last_term_str)]
			new_expected := u128(strconv.atoi(new_expected_str))
			ok := has_solution(new_expected, terms[:len(terms) - 1], check_concat, indent + 3)
			if ok do return true
		}
	}

	return has_solution(expected - last_term, terms[:len(terms) - 1], check_concat, indent + 3)
}

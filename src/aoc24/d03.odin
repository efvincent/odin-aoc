package aoc24

import "../util"
import "core:fmt"
import "core:log"
import "core:strconv"
import "core:strings"
import "core:testing"

solve_d03 :: proc(part: util.Part, data: string) -> string {
	switch part {
	case .p1:
		return solve1(data)
	case .p2:
		return solve2(data)
	}
	return ""
}

@(private = "file")
TokenType :: enum {
	JUNK,
	MUL,
	DO,
	DONT,
	NUM,
	OPEN_PAREN,
	CLOSE_PAREN,
	COMMA,
	EOF,
}

@(private = "file")
Token :: struct {
	type:  TokenType,
	start: int,
	len:   int,
}

@(private = "file")
Scanner :: struct {
	orig:  []u8,
	start: int,
	cur:   int,
}

// initialize a scanner from the slice of a rune array. Note that the
// scanner will maintain it's own slices of the rune array that it
// doesn't own.
@(private = "file")
initScannerFromString :: proc(source: string) -> Scanner {
	source_slice := transmute([]u8)source
	scanner := Scanner {
		orig  = source_slice,
		start = 0,
		cur   = 0,
	}
	return scanner
}

@(private = "file")
interpret :: proc(tkns: []Token, scn: Scanner, use_do_state: bool = false) -> int {
	// do we have a mul?
	tot := 0
	enabled := true
	for offset := 0; offset < len(tkns); {
		if check_tokens(offset, tkns, {.DO, .OPEN_PAREN, .CLOSE_PAREN}) {
			enabled = true
		}
		if check_tokens(offset, tkns, {.DONT, .OPEN_PAREN, .CLOSE_PAREN}) {
			enabled = !use_do_state || false
		}
		if check_tokens(offset, tkns, {.MUL, .OPEN_PAREN, .NUM, .COMMA, .NUM, .CLOSE_PAREN}) {
			// we have a mul...
			// extract the values of interest
			n1 := strconv.atoi(lexeme_of(tkns[offset + 2], scn))
			n2 := strconv.atoi(lexeme_of(tkns[offset + 4], scn))
			if enabled {
				tot += n1 * n2
			}
			offset += 6
		} else {
			offset += 1
		}
	}
	return tot
}

@(private = "file")
check_tokens :: proc(offset: int, tkns: []Token, candidates: []TokenType) -> bool {
	for candidate, idx in candidates {
		if idx + offset >= len(tkns) do return false
		if candidate != tkns[idx + offset].type do return false
	}
	return true
}

@(private = "file")
scan :: proc(tkns: ^[dynamic]Token, scn: ^Scanner) -> bool {
	prev := Token {
		type  = .JUNK,
		start = 0,
	}
	for {
		tkn, ok := scan_token(scn)
		if !ok do return false
		append(tkns, tkn)
		if tkn.type == .EOF do return true
	}
	return true
}

@(private = "file")
scan_token :: proc(scn: ^Scanner) -> (tkn: Token, ok: bool) {
	scn.start = scn.cur
	if isEOF(scn^) do return make_token(scn^, .EOF), true
	c := advance(scn) or_return

	switch c {
	case '(':
		return make_token(scn^, .OPEN_PAREN), true
	case ')':
		return make_token(scn^, .CLOSE_PAREN), true
	case ',':
		return make_token(scn^, .COMMA), true
	case 'm':
		if match(scn, "ul") {
			return make_token(scn^, .MUL), true
		}
	case 'd':
		if match(scn, "on't") {
			return make_token(scn^, .DONT), true
		}
		if match(scn, "o") {
			return make_token(scn^, .DO), true
		}
	case:
		if isDigit(c) do return number(scn)
	}
	return make_token(scn^, .JUNK), true
}

@(private = "file")
match :: proc(scn: ^Scanner, expected: string) -> bool {
	max_expected_idx := len(expected) - 1
	skip_count := 0
	for idx := scn.cur; idx < len(scn.orig) && idx - scn.cur <= max_expected_idx; idx += 1 {
		if scn.orig[idx] != u8(expected[idx - scn.cur]) do return false
		skip_count += 1
	}
	advance(scn, skip_count)
	return true
}

// determine if scanner is current pointed at a number. Assumes the first
// digit has already been read and known to be a digit. For AoC24d3 the numbers
// can only be 1-3 digits long
@(private = "file")
number :: proc(scn: ^Scanner) -> (tkn: Token, ok: bool) {
	if isEOF(scn^) do return make_token(scn^, .NUM), true

	// max 3 digit number. We already read one. check that only the next 2 max
	// are digits. More than that and nope.
	for i := 1; i <= 2; i += 1 {
		if checkCurrent(scn^, isDigit) do advance(scn) or_return
	}

	return make_token(scn^, .NUM), true
}

@(private = "file")
advance :: proc(scn: ^Scanner, count: int = 1) -> (u8, bool) {
	if isEOF(scn^, count - 1) {
		return 0, false
	}
	scn.cur += count
	return scn.orig[scn.cur - count], true
}

@(private = "file")
checkCurrent :: proc(scn: Scanner, predicate: (proc(_: u8) -> bool)) -> bool {
	return scn.cur <= (len(scn.orig) - 1) && predicate(scn.orig[scn.cur])
}

@(private = "file")
isAlpha :: proc(char: u8) -> bool {
	return char >= 'a' && char <= 'z' || char >= 'A' && char <= 'Z' || char == '\''
}

@(private = "file")
isDigit :: proc(char: u8) -> bool {
	return char >= '0' && char <= '9'
}

@(private = "file")
isEOF :: proc(scn: Scanner, extra: int = 0) -> bool {
	return scn.cur + extra >= len(scn.orig)
}

@(private = "file")
make_token :: proc(scn: Scanner, tt: TokenType) -> Token {
	lex := scn.orig[scn.start:scn.cur]
	token := Token {
		type  = tt,
		len   = len(lex),
		start = scn.start,
	}
	return token
}

@(private = "file")
lexeme_of :: proc(token: Token, scanner: Scanner) -> string {
	return string(scanner.orig[token.start:token.start + token.len])
}

@(private = "file")
solve1 :: proc(data: string) -> string {
	scn := initScannerFromString(data)
	tkns, err := make([dynamic]Token, context.temp_allocator)
	defer delete(tkns)
	scan(&tkns, &scn)
	ans := interpret(tkns[:], scn, false)
	return util.to_str(ans)
}

@(private = "file")
solve2 :: proc(data: string) -> string {
	scn := initScannerFromString(data)
	tkns, err := make([dynamic]Token, context.temp_allocator)
	defer delete(tkns)
	scan(&tkns, &scn)
	ans := interpret(tkns[:], scn, true)
	return util.to_str(ans)
}

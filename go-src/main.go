package main

import (
	"fmt"
	"math/rand"
	"syscall/js"
)

func main() {
	done := make(chan struct{})

	js.Global().Set("newGrid", js.FuncOf(newGrid))
	js.Global().Set("newMines", js.FuncOf(newMines))

	<-done
}

func doNotPanicPlease() {
	r := recover()

	if r != nil {
		fmt.Println("Recovered from", r)
	}
}

// Cells:
// 0..8 = An open cell and its number represents how many mines are around.
// 9 = Mine Cell
// 10 = Closed cell.
// 11 = Flag cell.
type Cell = int

// `newGrid(rows_num, cols_num)` expects 2 args: rows_num and cols_num, both need to be ints.
// Can't return a nested array threw WASM (couldn't figure this one out)
// so returns a 1-D array
func newGrid(this js.Value, args []js.Value) any {
	defer doNotPanicPlease()

	rows_num := args[0].Int()
	cols_num := args[1].Int()

	grid := make([]any, 0, rows_num*cols_num)

	for rowI := 0; rowI < rows_num; rowI++ {
		for colI := 0; colI < cols_num; colI++ {
			cell := rand.Intn(12)

			grid = append(grid, cell)

		}
	}

	return grid
}

// newRange(low, high) returns a slice of range from [low, high).
// Panics if high < low!
func newRange(low, high int) []any {
	r := make([]any, 0, (high - low))

	for num := low; num < high; num++ {
		r = append(r, num)
	}

	return r
}

// remove(s, i) removes the item at index `i` from slice `s`.
// ** NOTE: messes up the slice order!
func remove(s []any, i int) []any {
	s[i] = s[len(s)-1]
	return s[:len(s)-1]
}

// newMines(rows_num, cols_num) expects 2 args: rows_num and cols_num, both need to be ints.
// Returns an array of 1-D array indexes that should be mines.
func newMines(this js.Value, args []js.Value) any {
	defer doNotPanicPlease()

	rows_num := args[0].Int()
	cols_num := args[1].Int()

	totalMines := int(rows_num * cols_num / 10)

	locationPool := newRange(0, rows_num*cols_num)
	mines := make([]any, 0, totalMines)

	for a := 0; a < totalMines; a++ {
		locI := rand.Intn(len(locationPool))
		mine := locationPool[locI]

		locationPool = remove(locationPool, locI)
		mines = append(mines, mine)
	}

	return mines
}

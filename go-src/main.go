package main

import (
	"fmt"
	"math/rand"
	"syscall/js"
)

func main() {
	done := make(chan struct{})

	js.Global().Set("getGrid", js.FuncOf(getGrid))
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

const (
	mineCell   Cell = 9
	closedCell      = 10
	flagCell        = 11
)

// convertToSlice(arr) takes a js array and returns a []int, may panic if bad array.
func convertToSlice(arr js.Value) []int {
	arrLen := arr.Length()
	s := make([]int, 0, arrLen)

	for i := 0; i < arrLen; i++ {
		n := arr.Index(i).Int()
		s = append(s, n)
	}

	return s
}

// `getGrid(rowsNum uint, colsNum uint, mines []int, flagged []int, opened []int)`
// Can't return a nested array threw WASM (couldn't figure this one out)
// so returns a 1-D array
func getGrid(this js.Value, args []js.Value) any {
	defer doNotPanicPlease()

	rowsNum := args[0].Int()
	colsNum := args[1].Int()
	mines := convertToSlice(args[2])
	flagged := convertToSlice(args[3])
	opened := convertToSlice(args[4])

	gridArea := rowsNum * colsNum

	grid := make([]any, 0, gridArea)

	for i := 0; i < gridArea; i++ {
		grid = append(grid, closedCell)
	}

	for _, mineI := range mines {
		grid[mineI] = mineCell
	}

	for _, flagI := range flagged {
		grid[flagI] = flagCell
	}

	for _, openI := range opened {
		// TODO: put the number of mines not 0!
		grid[openI] = 0
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

#!/bin/env python3


###############################################################################
#
# rush_hour_solve.py
#
# Rush Hour puzzle solver
# (C) 2019 Norbert Zeh (nzeh@cs.dal.ca)
#
###############################################################################


"""This module provides all the boiler plate code of the puzzle solver.  This
includes processing of command line arguments, loading of the specified puzzle
from the database, and printing of the computed solution to stdout."""


import sys
from rush_hour import solver


def usage():
    """Print a usage message and exit when incorrect command line arguments
    were given."""
    print("USAGE: {} <puzzle number>".format(sys.argv[0]))
    sys.exit(1)


def load_puzzle(number):
    """Load the puzzle with the given number from the database and return
    its 36-character representation loaded from the database."""
    count = 0
    with open("../rush_no_walls.txt", "r") as file:
        puzzle = None
        for line in file:
            if count == number:
                fields = line.split()
                return fields[1]
            count += 1
    print("ERROR: There are only {} puzzles".format(count))
    sys.exit(1)


def print_solution(puzzle, solution):
    """Print the initial state and the sequence of moves to the screen"""
    print(puzzle)
    for move in solution:
        pos = move >> 8
        row = pos >> 3
        col = pos & 7
        offset = (move & 0xff) - 4
        print("({},{}){:+}".format(row, col, offset))


def main():
    """Main function"""
    if len(sys.argv) != 2:
        usage()
    try:
        puzzle_number = int(sys.argv[1])
    except ValueError:
        usage()
    puzzle = load_puzzle(puzzle_number)
    solution = solver.run(puzzle)
    if solution:
        print_solution(puzzle, solution)
    else:
        print("This puzzle is unsolvable")


if __name__ == "__main__":
    main()

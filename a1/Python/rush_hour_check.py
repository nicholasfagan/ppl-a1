#!/bin/env python3


###############################################################################
#
# rush_hour_check.py
#
# Rush Hour puzzle solver
# (C) 2019 Norbert Zeh (nzeh@cs.dal.ca)
#
###############################################################################


"""This module provides all the boiler plate code of the solution checker.
This includes processing of command line arguments, parsing the solution file,
and pretty-printing the solution to stdout."""


import re
import sys
import rush_hour.state as st


def usage():
    """Print a usage message and exit when incorrect command line arguments
    were given."""
    print("USAGE: {} <solution file>".format(sys.argv[0]))
    sys.exit(1)


def load_solution(filename):
    """Load a solution from the given file"""
    with open(filename, "r") as file:
        puzzle = next(file)
        if not puzzle:
            print("ERROR: File {} is empty".format(filename))
            sys.exit(1)
        puzzle = puzzle.strip()
        if len(puzzle) != 36:
            print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
            print("!!! THE PUZZLE GIVEN IN THE SOLUTION IS NOT A VALID PUZZLE !!!")
            print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
            sys.exit(1)
        moves = []
        for move in file:
            match = re.match(r"\((\d),(\d)\)([+-]\d)$", move)
            if not match:
                print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
                print("!!! {} IS NOT A VALID MOVE DESCRIPTOR !!!".format(move))
                print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
                sys.exit(1)
            row = int(match[1])
            col = int(match[2])
            pos = (row << 3) + col
            offset = int(match[3])
            moves.append((pos << 8) + offset + 4)
    return puzzle, moves


def load_puzzle_info(puzzle):
    """Load the number of optimal moves and the size of the search space for
    the given puzzle."""
    with open("../rush_no_walls.txt", "r") as file:
        for line in file:
            fields = line.split()
            if fields[1] == puzzle:
                return int(fields[0]), int(fields[2])
    print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
    print("!!! THE PUZZLE GIVEN IN THE SOLUTION IS NOT A VALID PUZZLE !!!")
    print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
    sys.exit(1)


def construct_state_seq(solution):
    """Construct the sequence of states obtained by applying the sequence of
    moves to the given starting state.  Check that all moves are valid and that
    the final state is solved."""
    state = st.from_string_rep(solution[0])
    states = [state]
    for move in solution[1]:
        state = st.apply_move(state, move)
        if state:
            states.append(state)
        else:
            pos = move >> 8
            row = pos >> 3
            col = pos & 7
            offset = (move & 0xff) - 4
            print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
            print("!!! INVALID MOVE ({},{}){:+} !!!".format(row, col, offset))
            print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
            print("State sequence so far:")
            print_solution(states)
            sys.exit(1)
    if not st.is_solved(states[-1]):
        print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
        print("!!! FINAL STATE IS NOT SOLVED !!!")
        print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
        print("State sequence so far:")
        print_solution(states)
        sys.exit(1)
    return states


def print_solution(state_seq):
    """Pretty-print the sequence of board states in a solution sequence to the
    screen, 8 states per row."""
    string_reps = [st.pretty_print(s) for s in state_seq]
    while string_reps:
        row = string_reps[:8]
        string_reps = string_reps[8:]
        for i in range(14):
            for rep in row:
                print(rep[i], "", end="")
            print()
        if string_reps:
            print()


def main():
    """Main function"""
    if len(sys.argv) != 2:
        usage()
    solution = load_solution(sys.argv[1])
    moves, space = load_puzzle_info(solution[0])
    print("Optimal moves     =", moves)
    print("Moves in solution =", len(solution[1]))
    print("Search space size =", space)
    state_seq = construct_state_seq(solution)
    if moves == len(solution[1]):
        print("The computed solution is optimal.")
        print_solution(state_seq)
    else:
        print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
        print("!!! THE COMPUTED SOLUTION IS NOT OPTIMAL !!!")
        print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
        print_solution(state_seq)
        sys.exit(1)


if __name__ == "__main__":
    main()

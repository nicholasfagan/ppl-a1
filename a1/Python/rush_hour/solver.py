###############################################################################
#
# rush_hour/solver.py
#
# Rush Hour puzzle solver
# (C) 2019 Norbert Zeh (nzeh@cs.dal.ca)
#
###############################################################################


"""This module provides the logic to solve a Rush Hour puzzle.  There is
nothing fancy here.  This only applies a breadth-first search of the state
space starting from the initial board state.  In this state space, two states
are neighbours if one of them can be transformed into the other by moving a
single piece."""


import rush_hour.state as st


def run(puzzle):
    """Solve a Rush hour puzzle represented as 36-character string listing the
    6x6 cells of the board in row-major order.  Empty cells are marked with
    "o".  Occupied cells are marked with letters representing pieces.  Cells
    occupied by the same piece carry the same letter."""
    return _Solver(puzzle).run()


class _Solver:
    """The state of the solver"""

    def __init__(self, string_rep):
        start_state = st.from_string_rep(string_rep)
        self._current = [([], start_state)]
        self._next = []
        self._seen = {start_state}

    def run(self):
        """Run the solver from the start state."""
        while True:
            for seq in self._current:
                sol = self._search(seq)
                if sol:
                    return sol
            if self._next:
                self._current = self._next
                self._next = []
            else:
                return None

    def _search(self, path):
        """See whether the given path (sequence of moves) can be extended with
        a single move to obtain a solution.  If so, return this solution.
        Otherwise, return None and, as a side effect, add all extensions of
        this path that end in a previously unexplored state to the frontier to
        be explored at the next BFS level."""
        state = path[1]
        for (next_state, move) in self._moves(state):
            if st.is_solved(next_state):
                return path[0] + [move]
            if next_state not in self._seen:
                self._next.append((path[0] + [move], next_state))
                self._seen.add(next_state)
        return None

    @staticmethod
    def _moves(state):
        """Generate all valid moves from the given state.  This is an iterator
        that yields (new_state, move) pairs where move is a valid move
        applicable to state and new_state is the resulting new state."""
        for pos in range(64):
            if st.is_end(state, pos):
                if st.is_horizontal(state, pos):
                    for k in range(1, 5):
                        new_state = st.horizontal_move(state, pos, k)
                        if not new_state:
                            break
                        yield (new_state, st.make_move(pos, k))
                    for k in range(1, 5):
                        new_state = st.horizontal_move(state, pos, -k)
                        if not new_state:
                            break
                        yield (new_state, st.make_move(pos, -k))
                if st.is_vertical(state, pos):
                    for k in range(1, 5):
                        new_state = st.vertical_move(state, pos, k)
                        if not new_state:
                            break
                        yield (new_state, st.make_move(pos, k))
                    for k in range(1, 5):
                        new_state = st.vertical_move(state, pos, -k)
                        if not new_state:
                            break
                        yield (new_state, st.make_move(pos, -k))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; rush-hour/solver.ss
;;;
;;; Rush Hour puzzle solver
;;; (C) 2019 Norbert Zeh (nzeh@cs.dal.ca)
;;;
;;; Implementation of the search for a shortest move sequence that solves a
;;; given Rush Hour puzzle.
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(library (rush-hour solver)
  (export solve-puzzle)
  (import (rnrs (6))
          (rush-hour state)
         (rush-hour utils))


;loops from start to end, calling (func i)
(define (iter-loop start end func)
	(if (< start end)
			(begin (func start) (iter-loop (+ 1 start) end func))))

;generate all moves from a given state-moves-pair.
(define (moves smp)
	(iter-loop 0 64 (lambda (pos) 
		(if (state-is-end? (car smp) pos)
				(begin 
				(if (state-is-horizontal? (car smp) pos)
						(begin 
						(iter-loop 1 5 (lambda (k)
								(
								 ;check each move is valid state
								 )))
						(iter-loop 1 5 (lambda (k)
								(
								 ;check moving backwards
								 )))))
				(if (state-is-vertical? (car smp) pos)
						(begin 
						(iter-loop 1 5 (lambda (k)
								(
								 ;check each move is valid state
								 )))
						(iter-loop 1 5 (lambda (k)
								(
								 ;check moving backwards
								 )))))
						))))))

(define (moves-outer-loop smp pos lst)
	(if (< pos 65)
		(if (state-is-end? (car smp) pos);1 is k
				(moves-outer-loop smp (+ 1 pos) 
													(moves-vertical-loop smp pos 
																							 (moves-horizontal-loop smp pos lst 1) 1))
				(moves-outer-loop smp (+ 1 pos) lst))
		lst))
(define (moves-horizontal-loop smp pos lst k)
	(if (< k 5)
			()
			lst))


;takes in a list of state-moves pairs and a list of previous states.
;finds all neighboring states
;returns a list of pairs like 
;((state newmove prevmovelist) (state newmove prevmovelist) ... )
; Nick Fagan nfagan@dal.ca
(define (get-new-neighbors prev-neighbors) prev-neighbors );TODO: implement
;map prev to new neighbors
;apply append to get list of list to one list.
;filter by member of solved.


  ;; Solve a Rush Hour puzzle represented as a 36-character string listing the
  ;; 6x6 cells of the board in row-major order.  Empty cells are marked with
  ;; "o".  Occupied cells are marked  with letters representing pieces.  Cells
  ;; occupied by the same piece carry the same letter.
	; Nick Fagan nfagan@dal.ca
  (define (solve-puzzle puzzle)
		(let* ([state (state-from-string-rep puzzle)];get the state
					[visited '()];we havent visited anything yet
					[neighbors (list state)]); we are looking at the starting position
			(next-step visited neighbors));call the main loop with the starting parameters.
		)


(define (get-sol lst-neighbors) 
	(fold-right (lambda (prev smp)
								(if (and smp (state-is solved? (car smp)))
										(cdr smp)
										prev)) 
							#f
							neightbors))

	; main loop for solving. takes in old states and new states.
	; returns list of moves or #f.
	; it is an implementation of a Breadth First Search.
	; Nick Fagan nfagan@dal.ca
	(define (next-step visited neighbors) 
			;check each neighbor.
			(let ([sol (get-sol neighbors)])
				(if sol sol
					(let* ([newvisited  (append visited (map car neighbors))]
								 ;add newly visited (only the state)
						[newneighbors ; all neighboring states
							(filter (lambda (smp) ;smp = state-moves-pair
								(not (member visited (car smp)))) 
								(get-new-neighbors neighbors))]); excluding visited states.
						(next-step newvisited newneighbors))))))

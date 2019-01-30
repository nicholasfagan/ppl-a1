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

(define (moves smp)
	(begin ;(display "moves: ") (newline) (pretty-print (car smp)) (newline) (display (cdr smp)) (newline) (newline)
		(moves-outer-loop smp 0 '())))

(define (moves-outer-loop smp pos lst)
	(begin ;(display "moves-outer-loop ")  (newline) (display (car smp)) (newline) (display (cdr smp)) (display pos) (newline) (display lst) (newline) (newline)
	(if (< pos 64)
			(if (state-is-end? (car smp) pos)
					(moves-outer-loop smp (+ 1 pos) ;cont lst below
						(if (state-is-horizontal? (car smp) pos)
								(moves-horizontal-loop smp pos lst -4)
								(if (state-is-vertical? (car smp) pos)
										(moves-vertical-loop smp pos lst -4)
										lst)))
					(moves-outer-loop smp (+ 1 pos) lst))
			lst)
	))

(define (moves-horizontal-loop smp pos lst offset)
	(begin ;(display "moves-horizontal-loop ") (newline) (display smp) (newline) (display pos) (newline) (display lst) (newline) (display offset) (newline) (newline)
	(if (= 0 offset)
			(moves-horizontal-loop smp pos lst (+ 1 offset))
			(if (< offset 5)
					(if (state-horizontal-move (car smp) pos offset)
							(moves-horizontal-loop smp pos 
								(cons 
									(cons 
										(state-horizontal-move (car smp) pos offset) 
										(cons 
											(state-make-move pos offset) 
											(cdr smp))) 
									lst) 
								(+ 1 offset))
							(moves-horizontal-loop smp pos lst (+ 1 offset)))
					lst))))

(define (moves-vertical-loop smp pos lst offset)
	(begin ;(display "moves-vertical-loop ") (display smp) (newline) (display pos) (newline) (display lst) (newline) (display offset) (newline) (newline)
	(if (= 0 offset)
			(moves-vertical-loop smp pos lst (+ 1 offset))
			(if (< offset 5)
					(if (state-vertical-move (car smp) pos offset)
							(moves-vertical-loop smp pos 
								(cons 
									(cons 
										(state-vertical-move (car smp) pos offset) 
										(cons 
											(state-make-move pos offset) 
											(cdr smp))) 
									lst) 
								(+ 1 offset))
							(moves-vertical-loop smp pos lst (+ 1 offset)))
					lst))))

;takes in a list of state-moves pairs and a list of previous states.
;finds all neighboring states
;returns a list of pairs like 
;((state newmove prevmovelist) (state newmove prevmovelist) ... )
; Nick Fagan nfagan@dal.ca
(define (get-new-neighbors visited neighbors) 
	(begin ;(display "get-new-neighbors ") (newline) (display visited)  (newline) (display neighbors) (newline) (newline)
		(map (lambda (smp) (hashtable-set! visited (car smp) #t)) neighbors)
		(remp (lambda (smp) (hashtable-contains? visited (car smp)))
			(apply append
				(map moves neighbors)))))
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
					[visited (make-hashtable equal-hash equal? 1000)];we havent visited anything yet
					[neighbors (list (list state ))]); list of smp, since smp is a list, and we have no moves, this is a list of a list of state
			(next-step visited neighbors));call the main loop with the starting parameters.
		)




;this function may need re-thinking
(define (get-sol neighbors)
	(if (null? neighbors)
			#f
			(if (state-is-solved? (caar neighbors))
					(car neighbors); the smp
					(get-sol (cdr neighbors)))))

	; main loop for solving. takes in old states and new states.
	; returns list of moves or #f.
	; it is an implementation of a Breadth First Search.
	; Nick Fagan nfagan@dal.ca
	(define (next-step visited neighbors) 
			;check each neighbor.
			(let ([sol (get-sol neighbors)])
				(if sol 
					(begin ;(display "Solution: ") (pretty-print (car sol)) (newline)
						(reverse (cdr sol)))
					(begin
						;(display "Current Neighbors: ")  (for-each pretty-print (map car neighbors)) (newline)
						;(display "Current Visited: ") (display (hashtable-keys visited)) (newline)
						;(newline)
						(next-step visited (get-new-neighbors visited neighbors))
					))))
	
	); ending 'library' tag

#!/bin/env scheme-script


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; rush_hour_solve.ss
;;;
;;; Rush Hour puzzle solver
;;; (C) 2019 Norbert Zeh (nzeh@cs.dal.ca)
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(import (rnrs (6))
        (rush-hour utils)
        (rush-hour solver))


;; Print a usage message and exit when incorrect command line arguments were
;; given.
(define (usage)
  (let ([progname (car (command-line))])
    (println "USAGE: " progname " <puzzle number>")
    (exit 1)))


;; Load the puzzle with the given number from the database and return its
;; 36-character representation loaded from the database.
(define (load-puzzle number)
  (call-with-input-file "../rush_no_walls.txt"
    (lambda (file)
      (let loop ([count 0])
        (let ([line (get-line file)])

          (cond [(eof-object? line)
                 (println "ERROR: There are only " count " puzzles")
                 (exit 1)]

                [(= count number)
                 (cadr (string-split line))]

                [else
                 (loop (+ count 1))]))))))


;; Print the solution in the output format expected by ./rush_hour_check.py
(define (print-solution puzzle solution)
  (println puzzle)
  (for move in solution
    (let* ([pos    (bitwise-arithmetic-shift-right move 8)]
           [row    (bitwise-arithmetic-shift-right pos 3)]
           [col    (bitwise-and pos 7)]
           [offset (- (bitwise-and move #xff) 4)])
      (println "(" row "," col ")"
               (if (< offset 0) "-" "+")
               (abs offset)))))


;; The main function
(define (main)
  (let ([args (command-line)])

    (if (not (= (length args) 2))
        (usage))

    (let ([number (string->number (cadr args))])

      (if (not (and (integer? number)
                    (exact? number)))
          (usage))

      (let* ([puzzle   (load-puzzle number)]
             [solution (solve-puzzle puzzle)])
        (if solution
            (print-solution puzzle solution)
            (println "This puzzle is unsolvable"))))))


;; Start the main function
(main)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; rush-hour/state.ss
;;;
;;; Rush Hour puzzle solver
;;; (C) 2019 Norbert Zeh (nzeh@cs.dal.ca)
;;;
;;; Primitives for manipulating the state of a Rush Hour board.
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(library (rush-hour state)
  (export state-from-string-rep pretty-print
          state-is-occupied? state-is-horizontal? state-is-vertical?
          state-is-end? state-is-solved?
          state-make-move state-horizontal-move state-vertical-move)
  (import (rnrs (6))
          (rush-hour utils))


  ;; Construct a board state from its string representation
  (define (state-from-string-rep str)
    (let ([grid (grid-from-string-rep str)])
      (let-values ([(horiz h-ends) (find-horiz-pieces grid)]
                   [(vert  v-ends) (find-vert-pieces  grid)])
        (let ([occupied (bitwise-ior horiz  vert)]
              [ends     (bitwise-ior h-ends v-ends)])
          (vector occupied horiz vert ends)))))


  ;; Construct a grid from its string representation
  (define (grid-from-string-rep str)
    (call-with-string-output-port
      (lambda (grid)
        (put-string grid "oooooooo")
        (for i from 0 to 35 step 6
          (put-char grid #\o)
          (put-string grid str i 6)
          (put-char grid #\o))
        (put-string grid "oooooooo"))))


  ;; Find all vertical pieces in the given grid
  (define (find-vert-pieces grid)
    (let ([transposed-grid (transpose-grid grid)])
      (let-values ([(bits ends) (find-horiz-pieces transposed-grid)])
        (values (transpose-bits bits)
                (transpose-bits ends)))))


  ;; Find the horizontal pieces in the given grid
  (define (find-horiz-pieces grid)
    (let-values ([(bits ends) (unzip (map-for i from 0 to 63
                                       (horiz-bits grid i)))])
      (values (fold-left bitwise-ior #xff000000000000ff bits)
              (fold-left bitwise-ior 0                  ends))))


  ;; Find the bits representing one cell
  (define (horiz-bits grid pos)
    (let ([cell (string-ref grid pos)])
      (if (char=? cell #\o)
          (list 0 0)
          (let ([pred (string-ref grid (- pos 1))]
                [succ (string-ref grid (+ pos 1))]
                [true (bitwise-arithmetic-shift 1 pos)])
            (cond [(char=? cell succ) (list true 0)]
                  [(char=? cell pred) (list true true)]
                  [else               (list 0    0)])))))


  ;; Transpose a character grid
  (define (transpose-grid grid)
    (call-with-string-output-port
      (lambda (transposed)
        (for row from 0 to 7
          (for pos from row to 63 step 8
            (put-char transposed (string-ref grid pos)))))))


  ;; Transpose a bit string
  (define (transpose-bits bits)
    (define (trans bits shift-mask)
      (let ([t (bitwise-and (bitwise-xor bits
                                         (bitwise-arithmetic-shift
                                           bits (car shift-mask)))
                            (cdr shift-mask))])
        (bitwise-xor bits t (bitwise-arithmetic-shift
                              t (- (car shift-mask))))))
    (fold-left trans bits '((7  . #x5500550055005500)
                            (14 . #x3333000033330000)
                            (28 . #x0f0f0f0f00000000))))


  ;; Pretty-print a given state
  (define (pretty-print state)
    (let* ([rows (map-for row from 8 to 55 step 8
                   (map-for col from 1 to 6
                     (format-cell state (+ row col))))]
           [lines (apply append
                         (map-for row in rows
                           (let-values ([(upper lower) (unzip row)])
                             (list (apply append upper)
                                   (apply append lower)))))]
           [numbered-lines (zip '(1 2 3 4 5 6 7 8 9 10 11 12) lines)])
      (println "██████████████")
      (for (num line) in lines
        (println #\█ (list->string line)
                 (if (or (= num 5) (= num 6)) #\space #\█)))
      (println "██████████████")))
  

  ;; Return a 2x2 list of the characters used to display a given board cell.
  (define (format-cell state pos)
    (cond [(not (state-is-occupied? state pos)) '((#\space #\space)
                                                  (#\space #\space))]
          [(state-is-horizontal? state pos)
           (transpose (list (cond [(or (not (state-is-horizontal? state (- pos 1)))
                                       (state-is-end? state (- pos 1)))
                                   '(#\▗ #\▝)]
                                  [else '(#\▄ #\▀)])
                            (cond [(or (not (state-is-horizontal? state (+ pos 1)))
                                       (state-is-end? state pos))
                                   '(#\▖ #\▘)]
                                  [else '(#\▄ #\▀)])))]
          [else
           (list (cond [(or (not (state-is-vertical? state (- pos 8)))
                            (state-is-end? state (- pos 8)))
                        '(#\▗ #\▖)]
                       [else '(#\▐ #\▌)])
                 (cond [(or (not (state-is-vertical? state (+ pos 8)))
                            (state-is-end? state pos))
                        '(#\▝ #\▘)]
                       [else '(#\▐ #\▌)]))]))


  ;; Check whether the the given position in the grid is occupied
  (define (state-is-occupied? state pos)
    (not (= 0 (bitwise-and (vector-ref state 0) (bitwise-arithmetic-shift 1 pos)))))


  ;; Check whether the the given position in the grid is occupied by a
  ;; horizontal piece
  (define (state-is-horizontal? state pos)
    (not (= 0 (bitwise-and (vector-ref state 1) (bitwise-arithmetic-shift 1 pos)))))


  ;; Check whether the the given position in the grid is occupied by a vertical
  ;; piece
  (define (state-is-vertical? state pos)
    (not (= 0 (bitwise-and (vector-ref state 2) (bitwise-arithmetic-shift 1 pos)))))


  ;; Check whether the the given position in the grid is the rightmost position
  ;; of a horizontal piece or the bottommost position of a vertical piece
  (define (state-is-end? state pos)
    (not (= 0 (bitwise-and (vector-ref state 3) (bitwise-arithmetic-shift 1 pos)))))


  ;; Check whether the given state is a solved state
  (define (state-is-solved? state)
    (state-is-horizontal? state 30))


  ;; Create a move "object" from the position of the moved piece and the offset
  ;; by which it is moved.
  (define (state-make-move pos offset)
    (bitwise-ior (bitwise-arithmetic-shift pos 8)
                 (+ offset 4)))


  ;; Try to move a vertical piece by offset positions.  A negative offset means
  ;; move up.  A positive offset means move down.  Return the new state on success.
  ;; Return #f on failure.
  (define (state-vertical-move state pos offset)
    (and (state-is-end? state pos)
         (state-is-vertical? state pos)
         (state-move state pos offset
                     (bitwise-and (vector-ref state 0)
                                  (bitwise-not (vector-ref state 1))
                                  (bitwise-not (vector-ref state 3)))
                     8
                     #x0101010101010101)))


  ;; Try to move a horizontal piece by offset positions.  A negative offset means
  ;; move left.  A positive offset means move right.  Return the new state on success.
  ;; Return #f on failure.
  (define (state-horizontal-move state pos offset)
    (and (state-is-end? state pos)
         (state-is-horizontal? state pos)
         (state-move state pos offset
                     (bitwise-and (vector-ref state 0)
                                  (bitwise-not (vector-ref state 2))
                                  (bitwise-not (vector-ref state 3)))
                     1
                     #xffffffffffffffff)))


  ;; The worker that implements both horizontal and vertical moves
  (define (state-move state pos offset stop skip mask)
    (let* ([piece       (state-find-piece stop pos skip)]
           [new-piece   (bitwise-arithmetic-shift piece (* offset skip))]
           [left-piece  (min piece new-piece)]
           [right-piece (max piece new-piece)]
           [new-pos     (+ pos (* offset skip))]
           [left-pos    (min pos new-pos)]
           [right-pos   (max pos new-pos)])
      (and (not (or (< left-pos (+ 9 skip))
                    (> right-pos 54)))
           (let* ([left-mask  (bitwise-ior left-piece
                                           (bitwise-arithmetic-shift
                                             mask left-pos))]
                  [right-mask (bitwise-ior right-piece
                                           (bitwise-arithmetic-shift-right
                                             mask
                                             (- 64 right-pos skip)))]
                  [swath      (bitwise-xor
                                (bitwise-and left-mask right-mask)
                                piece)])
             (and (= 0 (bitwise-and (vector-ref state 0)
                                    swath))
                  (let ([piece-delta (bitwise-xor piece new-piece)]
                        [ends-delta  (bitwise-ior (bitwise-arithmetic-shift 1 pos)
                                                  (bitwise-arithmetic-shift 1 new-pos))])
                    (if (= skip 1)
                        (vector (bitwise-xor (vector-ref state 0) piece-delta)
                                (bitwise-xor (vector-ref state 1) piece-delta)
                                (vector-ref state 2)
                                (bitwise-xor (vector-ref state 3) ends-delta))
                        (vector (bitwise-xor (vector-ref state 0) piece-delta)
                                (vector-ref state 1)
                                (bitwise-xor (vector-ref state 2) piece-delta)
                                (bitwise-xor (vector-ref state 3) ends-delta)))))))))


  ;; Find the positions occupied by a given piece
  (define (state-find-piece stop pos skip)
    (let ([start (bitwise-arithmetic-shift 1 pos)])
      (let loop ([piece start]
                 [bit   (bitwise-arithmetic-shift-right start skip)])
        (if (= 0 (bitwise-and stop bit))
            piece
            (loop (bitwise-ior piece bit)
                  (bitwise-arithmetic-shift-right bit skip)))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; rush-hour/utils.ss
;;;
;;; Rush Hour puzzle solver
;;; (C) 2019 Norbert Zeh (nzeh@cs.dal.ca)
;;;
;;; A library of utility functions such list and string splitting functions,
;;; print helpers, and macros to express maps over number ranges more
;;; elegantly.
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(library (rush-hour utils)
  (export print println
          string-split is-space
          drop-while take-while split flatten zip unzip transpose
          compose partial flip id
          for map-for)
  (import (rnrs (6)))


  ;; A print function that prints all its arguments.  `display` accepts only
  ;; one argument.  `print` takes an arbitrary number of arguments.
  (define (print . args)
    (for-each display args))


  ;; A version of `print` that adds a newline to the end of the output.
  (define (println . args)
    (apply print args)
    (newline))


  ;; A helper function to split a string into words.  Sadly, Scheme doesn't
  ;; have this built-in.
  (define (string-split str)
    (let loop ([words '()]
               [str   (drop-while is-space (string->list str))])
      (if (null? str)
          (reverse words)
          (let-values ([(word rest) (split is-space str)])
            (loop (cons (list->string word) words)
                  (drop-while is-space rest))))))


  ;; A predicate that tests whether a given character is a space
  (define (is-space chr)
    (char=? chr #\space))


  ;; A helper function to drop all elements matching a predicate from a list
  ;; until the first element not matching the predicate is found
  (define (drop-while pred lst)
    (let-values ([(_ suffix) (split (compose not pred) lst)])
      suffix))


  ;; A helper function to take all elements matching a predicate from a list
  ;; until the first element not matching the predicate is found
  (define (take-while pred lst)
    (let-values ([(prefix _) (split (compose not pred) lst)])
      prefix))


  ;; A helper function that splits a list into a prefix and a suffix so that the
  ;; prefix has maximum length and all elements in the prefix fail the given
  ;; predicate.
  (define (split pred lst)
    (let loop ([prefix '()]
               [suffix lst])
      (if (or (null? suffix)
              (pred (car suffix)))
          (values (reverse prefix) suffix)
          (loop (cons (car suffix) prefix)
                (cdr suffix)))))


  ;; Flatten a list
  (define (flatten lst)
    (apply append (map (lambda (sublst)
                         (if (list? sublst)
                             (flatten sublst)
                             (list sublst)))
                       lst)))


  ;; A zip function
  (define (zip . lsts)
    (apply map list lsts))


  ;; An unzip function
  (define (unzip lst)
    (apply values (transpose lst)))


  ;; Transpose a matrix represented as a list of lists.  Does the same as
  ;; unzip but returns a list of lists as opposed to multiple return values.
  (define (transpose lst)
    (apply zip lst))


  ;; Compose two or more functions
  (define (compose . funs)
    (lambda (arg)
      (fold-right (lambda (f x) (f x)) arg funs)))


  ;; Partial function application
  (define (partial fun . args)
    (lambda rest
      (apply fun (append args rest))))


  ;; Flip the argument order of a two-argument function
  (define (flip fun)
    (lambda (x y)
      (fun y x)))


  ;; The identity function
  (define (id x) x)


  ;; A simple for-loop
  (define-syntax for
    (syntax-rules (in from to downto step)
      [(for (var1 var2 ...) in lst body1 body2 ...)
       (for-each (lambda (args)
                   (let-values ([(var1 var2 ...) (apply values args)])
                     body1 body2 ...)) lst)]
      [(for x in lst body1 body2 ...)
       (for-each (lambda (x) body1 body2 ...) lst)]
      [(for x from start to end step inc body1 body2 ...)
       (let ([final end]
             [delta inc])
         (let loop ([x start])
           (if (<= x final)
               (begin body1 body2 ... (loop (+ x delta))))))]
      [(for x from start downto end step dec body1 body2 ...)
       (let ([final end]
             [delta dec])
         (let loop ([x start])
           (if (>= x final)
             (begin body1 body2 ... (loop (- x delta))))))]
      [(for x from start to end body1 body2 ...)
       (for x from start to end step 1 body1 body2 ...)]
      [(for x from start downto end body1 body2 ...)
       (for x from start downto end step 1 body1 body2 ...)]))


  ;; A simple for-loop that collects its arguments
  (define-syntax map-for
    (syntax-rules (in from to downto step)
      [(map-for (var1 var2 ...) in lst body1 body2 ...)
       (map (lambda (args)
              (let-values ([(var1 var2 ...) (apply values args)])
                body1 body2 ...)) lst)]
      [(map-for x in lst body1 body2 ...)
       (map (lambda (x) body1 body2 ...) lst)]
      [(map-for x from start to end step inc body1 body2 ...)
       (let ([final end]
             [delta inc])
         (let loop ([x start]
                    [results '()])
           (if (<= x final)
               (loop (+ x delta) (cons (begin body1 body2 ...) results))
               (reverse results))))]
      [(map-for x from start downto end step dec body1 body2 ...)
       (let ([final end]
             [delta dec])
         (let loop ([x start]
                    [results '()])
           (if (>= x final)
               (loop (- x delta) (cons (begin body1 body2 ...) results))
               (reverse results))))]
      [(map-for x from start to end body1 body2 ...)
       (map-for x from start to end step 1 body1 body2 ...)]
      [(map-for x from start downto end body1 body2 ...)
       (map-for x from start downto end step 1 body1 body2 ...)])))

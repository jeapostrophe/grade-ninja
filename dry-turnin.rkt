#lang racket/base
(require racket/cmdline
         racket/match
         "data.rkt"
         "compile.rkt")

(define-values (dir num optional)
  (command-line
   #:program "turnin"
   #:args (assignment)
   (match assignment
     [(regexp #rx"^([0-9]+)(opt)?$" (list dir num opt))
      (values dir (string->number num) (not (not opt)))]
     [else 
      (printf "~a is not a valid assignment\n" assignment)
      (exit)])))

(printf "Dry turnin of assignment ~a\n\n" dir)

(compile-files dir #f (exercise-seq num optional))
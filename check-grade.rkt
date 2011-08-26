#lang racket/base
(require racket/cmdline
         racket/match
         "data.rkt")

(define-values (dir num optional)
  (command-line
   #:program "turnin"
   #:args assignment
   (match assignment
     [(list (regexp #rx"^([0-9]+)(opt)?$" (list dir num opt)))
      (values dir (string->number num) (not (not opt)))]
     [(list) 
      (values #f #f #f)]
     [else 
      (printf "~a is not a valid assignment\n" assignment)
      (exit)])))

(cond
  [(and num (assignment-graded? (string->path dir)))
   (display (format-assignment-grade current-student-dir num optional (num-exercises num optional)))]
  [dir
   (printf "Assignment ~a hasn't been graded yet." dir)]
  [else
   (display (format-course-grade current-student-dir))])
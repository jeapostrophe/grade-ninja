#lang racket/base
(require racket/cmdline
         racket/match
         "data.rkt")

(define-values (num optional)
  (command-line
   #:program "turnin"
   #:args assignment
   (match assignment
     [(list (regexp #rx"^([0-9]+)(opt)?$" (list _ num opt)))
      (values (string->number num) (not (not opt)))]
     [(list) 
      (values #f #f)]
     [else 
      (printf "~a is not a valid assignment\n" assignment)
      (exit)])))

(cond
  [(and num (assignment-graded? num))
   (display (format-assignment-grade current-student-dir num optional (num-exercises num optional)))]
  [num
   (printf "Assignment ~a hasn't been graded yet." num)]
  [else
   (display (format-course-grade current-student-dir))])
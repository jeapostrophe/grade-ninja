#!/usr/bin/env racket
#lang racket/base
(require racket/cmdline
         racket/match
         racket/file
         racket/list
         racket/string
         "data.rkt")

(command-line #:program "final-grades")

(define (format-name name)
  (define split-names (filter (λ (v) (not (string=? v ""))) (regexp-split #rx" +" name)))
  (define-values (first last) (split-at split-names (sub1 (length split-names))))
  (format "~a, ~a" (car last) (string-join first " ")))

(define grades
  (for/list ([username (in-list (directory-list (students-dir)))])
    (define student-dir (build-path (students-dir) username))
    (define course-grade (calculate-course-grade (fill-grades (get-current-grades student-dir) 0 0)))
    (list
     (format-name (file->string (build-path student-dir ".name")))
     (real->decimal-string (* 100 course-grade) 2)
     (grade->letter course-grade))))

(for-each (match-lambda 
            [(list name grade letter) 
             (printf "~a: ~a (~a)\n" name grade letter)])
          (sort grades #:key car string<?))
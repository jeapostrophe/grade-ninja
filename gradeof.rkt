#!/usr/bin/env racket
#lang racket/base
(require racket/cmdline
         racket/match
         "data.rkt")

(define-values (username dir num optional)
  (command-line
   #:program "gradeof"
   #:args args
   (match args
     [(list username (regexp #rx"^([0-9]+)(opt)?$" (list dir num opt)))
      (values username dir (string->number num) (not (not opt)))]
     [(list username) 
      (values username #f #f #f)]
     [else 
      (printf "invalid arguments ~a\n" args)
      (exit)])))

(define student-dir (build-path (students-dir) username))
(cond
  [(not (directory-exists? student-dir)) 
   (printf "~a is not a valid student username.\n" username)]
  [(and dir (assignment-graded? (build-path student-dir dir)))
   (display (format-assignment-grade student-dir num optional))]
  [dir
   (printf "Assignment ~a hasn't been graded yet.\n" dir)]
  [else
   (display (format-course-grade student-dir))])

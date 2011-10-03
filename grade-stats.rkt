#!/usr/bin/env racket
#lang racket/base
(require racket/cmdline
         racket/match
         "stats.rkt"
         "data.rkt")

(define-values (an-assignment)
  (command-line
   #:program "grade-stats"
   #:args args
   (match args
     [(list (regexp #rx"^([0-9]+)(opt)?$" (list dir num opt)))
      (assignment dir (string->number num) (not (not opt)))]
     [else 
      #f])))

(cond
  [an-assignment (display (format-assignment-stats an-assignment))]
  [else (void)])
#!/usr/bin/env racket
#lang racket/base
(require racket/runtime-path
         unstable/file
         "util.rkt"
         (for-syntax racket/base
                     "util.rkt"))
(define-runtime-path user-dir (format "../students/~a" (username)))
(make-directory*/ignore-exists-exn user-dir)
(define name (combined-command-line))
(with-output-to-file (build-path user-dir ".name") (λ () (printf "~a" name)) #:exists 'truncate)
(printf "Name saved as ~a.\n" name)
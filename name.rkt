#!/usr/bin/env racket
#lang racket/base
(require racket/runtime-path
         unstable/file
         "util.rkt")
(make-directory*/ignore-exists-exn current-student-dir)
(file-or-directory-permissions current-student-dir #o700)
(define name (combined-command-line))
(define dot-name (build-path current-student-dir ".name"))
(with-output-to-file dot-name (λ () (printf "~a" name)) #:exists 'truncate)
(file-or-directory-permissions dot-name #o600)
(printf "Name saved as ~a.\n" name)
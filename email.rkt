#!/usr/bin/env racket
#lang racket/base
(require racket/runtime-path
         unstable/file
         "util.rkt"
         "data.rkt")

(make-directory*/ignore-exists-exn current-student-dir)
(file-or-directory-permissions current-student-dir #o700)
(define email (combined-command-line))
(define dot-email (build-path current-student-dir ".email"))
(with-output-to-file dot-email (λ () (printf "~a" email)) #:exists 'truncate)
(file-or-directory-permissions dot-email #o600)
(printf "Email saved as ~a.\n" email)
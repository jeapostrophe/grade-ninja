#!/usr/bin/env racket
#lang racket/base
(require racket/runtime-path
         unstable/file
         "util.rkt"
         (for-syntax racket/base
                     "util.rkt"))
(define-runtime-path user-dir (format "../students/~a" (username)))
(make-directory*/ignore-exists-exn user-dir)
(file-or-directory-permissions user-dir #o700)
(define name (combined-command-line))
(define dot-name (build-path user-dir ".name"))
(with-output-to-file dot-name (λ () (printf "~a" name)) #:exists 'truncate)
(file-or-directory-permissions dot-name #o600)
(printf "Name saved as ~a.\n" name)
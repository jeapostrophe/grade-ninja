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
(define email (combined-command-line))
(define dot-email (build-path user-dir ".email"))
(with-output-to-file dot-email (λ () (printf "~a" email)) #:exists 'truncate)
(file-or-directory-permissions dot-email #o600)
(printf "Email saved as ~a.\n" email)
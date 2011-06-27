#lang racket/base
(require racket/runtime-path
         racket/file
         racket/cmdline
         "util.rkt"
         (for-syntax racket/base
                     "util.rkt"))
(define num
  (command-line
   #:program "turnin"
   #:args (num)
   num))
(define-runtime-path user-dir (format "../students/~a" (username)))
(define num-dir (build-path user-dir num))
(copy-directory/files num num-dir)
(fold-files (λ (file-path type _)
              (case type
                [(file) (file-or-directory-permissions file-path #o600)]
                [(dir) (file-or-directory-permissions num-dir #o700)])) (void) num-dir)

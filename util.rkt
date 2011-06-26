#lang racket/base
(require ffi/unsafe
         racket/string)
(define username (get-ffi-obj "getlogin" #f (_fun -> _string)))
(define (backup-file file)
  (when (or (file-exists? file) (link-exists? file))
    (define-values (base name _) (split-path file))
    (define backup-path (build-path base (string-append (path->string name) "~")))
    (rename-file-or-directory file backup-path)))

(define (replace-file old new #:permissions [p #f])
  (when (file-exists? old)
    (delete-file old))
  (copy-file new old)
  (when p
    (file-or-directory-permissions old p)))

(define (combined-command-line)
  (string-join (vector->list (current-command-line-arguments)) " "))

(provide username
         backup-file
         replace-file
         combined-command-line)

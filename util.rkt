#lang racket/base
(require racket/string
         racket/runtime-path
         racket/list)

(provide backup-file
         replace-file
         combined-command-line)

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
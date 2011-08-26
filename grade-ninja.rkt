#!/usr/bin/env racket
#lang racket/base
(require racket/runtime-path
         racket/file
         unstable/file
         racket/system
         "util.rkt")
(define-runtime-path install-rkt "install.rkt")
(define-runtime-path util-rkt "util.rkt")
(define-runtime-path data-rkt "data.rkt")
(define-runtime-path compile-rkt "compile.rkt")
(define-runtime-path username-rkt "username.rkt")
(define-runtime-path name-rkt "name.rkt")
(define-runtime-path email-rkt "email.rkt")
(define-runtime-path turnin-rkt "turnin.rkt")
(define-runtime-path dry-turnin-rkt "dry-turnin.rkt")
(define-runtime-path grade-rkt "grade.rkt")
(define-runtime-path check-grade-rkt "check-grade.rkt")
(define-runtime-path emacs-el "env/.emacs.el")
(when (directory-exists? "scripts")
  (delete-directory/files "scripts"))
(make-directory*/ignore-exists-exn "scripts")
(file-or-directory-permissions "scripts" #o711)
(make-directory*/ignore-exists-exn "env")
(file-or-directory-permissions "env" #o711)
(make-directory*/ignore-exists-exn "students")
(file-or-directory-permissions "students" #o700)
(replace-file "scripts/install.rkt" install-rkt #:permissions #o755)
(replace-file "scripts/util.rkt" util-rkt #:permissions #o644)
(replace-file "scripts/data.rkt" data-rkt #:permissions #o644)
(replace-file "scripts/compile.rkt"compile-rkt #:permissions #o644)
(replace-file "scripts/username.rkt" username-rkt #:permissions #o644)
(replace-file "scripts/grade.rkt" grade-rkt #:permissions #o700)

(define (compile-replace-script existing-file name)
  (define script-file (format "scripts/~a.rkt" name))
  (copy-file existing-file script-file)
  (system (format "raco exe ~a" script-file))
  (file-or-directory-permissions (format "scripts/~a" name) #o6755)
  (delete-file script-file))

;todo: replace with function
(compile-replace-script name-rkt "name")
(compile-replace-script email-rkt "email")
(compile-replace-script turnin-rkt "turnin")
(compile-replace-script dry-turnin-rkt "dry-turnin")
(compile-replace-script check-grade-rkt "check-grade")

(with-output-to-file "install" #:exists 'truncate (λ () (printf "#!/bin/sh\n~a -t $(dirname $0)/scripts/install.rkt" (path->complete-path (find-system-path 'exec-file)))))
(file-or-directory-permissions "install" #o755)


(replace-file "env/.emacs.el" emacs-el #:permissions #o644)

(printf "students should run:\n~a\n" (build-path (current-directory) "install"))
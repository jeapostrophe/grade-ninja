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
(define-runtime-path gradeof-rkt "gradeof.rkt")
(define-runtime-path grade-stats-rkt "grade-stats.rkt")
(define-runtime-path stats-rkt "stats.rkt")
(define-runtime-path assignments-rkt "assignments.rkt")
(define-runtime-path check-grade-rkt "check-grade.rkt")
(define-runtime-path get-graded-dir-rkt "get-graded-dir.rkt")
(define-runtime-path emacs-el "env/.emacs.el")
(define-runtime-path get-graded "get-graded")
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
(replace-file "scripts/stats.rkt" stats-rkt #:permissions #o644)
(replace-file "scripts/compile.rkt"compile-rkt #:permissions #o644)
(replace-file "scripts/username.rkt" username-rkt #:permissions #o644)
(replace-file "scripts/grade.rkt" grade-rkt #:permissions #o700)
(replace-file "scripts/gradeof.rkt" gradeof-rkt #:permissions #o700)
(replace-file "scripts/grade-stats.rkt" grade-stats-rkt #:permissions #o700)

(define (compile-replace-script existing-file name)
  (define script-file (format "scripts/~a.rkt" name))
  (copy-file existing-file script-file)
  (system (format "raco exe ~a" script-file))
  (file-or-directory-permissions (format "scripts/~a" name) #o6755)
  (delete-file script-file))

(compile-replace-script name-rkt "name")
(compile-replace-script email-rkt "email")
(compile-replace-script turnin-rkt "turnin")
(compile-replace-script dry-turnin-rkt "dry-turnin")
(compile-replace-script check-grade-rkt "check-grade")
(compile-replace-script get-graded-dir-rkt "get-graded-dir")
(compile-replace-script assignments-rkt "assignments")

(define exec-file (find-system-path 'exec-file))
(define racket-path
  (if (equal? exec-file (string->path "racket"))
      (find-executable-path exec-file)
      (path->complete-path exec-file)))

(with-output-to-file "install" #:exists 'truncate (λ () (printf "#!/bin/sh\n~a -t $(dirname $0)/scripts/install.rkt" racket-path)))
(file-or-directory-permissions "install" #o755)


(replace-file "env/.emacs.el" emacs-el #:permissions #o644)
(replace-file "scripts/get-graded" get-graded #:permissions #o755)

(printf "Grade Ninja requires:
\tassignments.rktd: file with metadata about assignments.
\t.email: email address grades get sent from.
students should run:\n~a\n" (build-path (current-directory) "install"))
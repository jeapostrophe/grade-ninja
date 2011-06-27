#!/usr/bin/env racket
#lang racket/base
(require racket/runtime-path
         unstable/file
         racket/system
         "util.rkt")
(define-runtime-path install-rkt "install.rkt")
(define-runtime-path util-rkt "util.rkt")
(define-runtime-path name-rkt "name.rkt")
(define-runtime-path email-rkt "email.rkt")
(define-runtime-path turnin-rkt "turnin.rkt")
(define-runtime-path install "install")
(define-runtime-path emacs-el "env/.emacs.el")
(make-directory*/ignore-exists-exn "scripts")
(file-or-directory-permissions "scripts" #o711)
(make-directory*/ignore-exists-exn "env")
(file-or-directory-permissions "env" #o711)
(make-directory*/ignore-exists-exn "students")
(file-or-directory-permissions "students" #o700)
(replace-file "scripts/install.rkt" install-rkt #:permissions #o755)
(replace-file "scripts/util.rkt" util-rkt #:permissions #o644)

;todo: replace with function
(copy-file name-rkt "scripts/name.rkt")
(void (system (format "raco exe scripts/name.rkt")))
(file-or-directory-permissions "scripts/name" #o6711)
(delete-file "scripts/name.rkt")

(copy-file email-rkt "scripts/email.rkt")
(void (system (format "raco exe scripts/email.rkt")))
(file-or-directory-permissions "scripts/email" #o6711)
(delete-file "scripts/email.rkt")

(copy-file turnin-rkt "scripts/turnin.rkt")
(void (system (format "raco exe scripts/turnin.rkt")))
(file-or-directory-permissions "scripts/turnin" #o6711)
(delete-file "scripts/turnin.rkt")


(replace-file "install" install #:permissions #o755)
(replace-file "env/.emacs.el" emacs-el #:permissions #o644)

(printf "students should run:\n~a\n" (build-path (current-directory) "install"))
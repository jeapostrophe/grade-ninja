#lang racket/base
(require racket/runtime-path
         "util.rkt")
(define-runtime-path emacs-el-path "../env/.emacs.el")
(define-runtime-path scripts-path ".")

(define home-dir (find-system-path 'home-dir))
(define home-emacs-el (build-path home-dir ".emacs.el"))
(define home-profile (build-path home-dir ".profile"))

(backup-file home-emacs-el)
(backup-file home-profile)

(make-file-or-directory-link (simplify-path emacs-el-path) home-emacs-el)

(with-output-to-file home-profile (λ () (printf "export PATH=~a:$PATH\n" (simplify-path scripts-path))))


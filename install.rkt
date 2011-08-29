#lang racket/base
(require racket/runtime-path
         "util.rkt")
(define-runtime-path emacs-el-path "../env/.emacs.el")
(define-runtime-path scripts-path ".")

(define home-dir (find-system-path 'home-dir))
(define home-emacs-el (build-path home-dir ".emacs.el"))
(define home-profile (build-path home-dir ".profile"))
(define home-bashrc (build-path home-dir ".bashrc"))

(backup-file home-emacs-el)
(backup-file home-profile)
(backup-file home-bashrc)

(make-file-or-directory-link (simplify-path emacs-el-path) home-emacs-el)

(define (print-path)
  (printf "export PATH=~a:$PATH\nexport PS1='\\u@\\h:\\W $ '" (simplify-path scripts-path)))

(with-output-to-file home-profile print-path)
(with-output-to-file home-bashrc print-path)


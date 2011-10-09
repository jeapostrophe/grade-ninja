#lang racket
(require racket/runtime-path
         (planet neil/html-parsing)
         (planet clements/sxml2))

(define-runtime-path dest "imgs")

(define file "BYU - Contact Class Roll -.html")

(define src (html->xexp (file->string file)))

(for ([s (in-list
          ((sxpath `(// (span (@ (equal? (class "data80"))))))
           src))])
     (define img (second (first ((sxpath `(// img @ src)) s))))
     (define student (first ((sxpath `(// a *text*)) s)))

     (copy-file img
                (build-path dest (format "~a.jpg" student))))

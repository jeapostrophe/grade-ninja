#lang racket
(require racket/cmdline)

(command-line
 #:program "gw-helper"
 #:args (port file-pth)

 (define-values (from to) (tcp-connect "localhost" (string->number port)))

 (write file-pth to)
 (flush-output to)

 (read from))

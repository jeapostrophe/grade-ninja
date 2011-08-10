#lang racket/base
(require ffi/unsafe)

(provide username)

(define username (get-ffi-obj "getlogin" #f (_fun -> _string)))
         

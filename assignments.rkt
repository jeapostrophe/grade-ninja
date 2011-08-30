#lang racket/base
(require racket/list 
         racket/string
         "data.rkt")

(define (identify-assignment num optional)
  (define dir (format "~a~a" num (if optional "opt" "")))
  (define assignment-dir (build-path current-student-dir dir))
  (cond
    [(assignment-graded? assignment-dir)
     (cons 'graded dir)]
    [(directory-exists? assignment-dir)
     (cons 'turned-in dir)]
    [(after? (due-date num optional))
     (cons 'cant-turnin dir)]
    [else
     (cons 'can-turnin dir)]))

(define (update-assignments assignments assignment-info)
  (hash-update assignments (car assignment-info) (λ (v) (cons (cdr assignment-info) v)) empty))

(define assignments
  (for/fold ([assignments (hasheq)]) 
    ([i (in-range (num-assignments) 0 -1)])
    (define assignment-info (identify-assignment i #f))
    (define opt-assignment-info (identify-assignment i #t))
    (update-assignments (update-assignments assignments opt-assignment-info) assignment-info)))

(printf "Graded:\n\t~a\nTurned in, but not yet graded:\n\t~a\nCannot be turned in:\n\t~a\nCan be turned in:\n\t~a\n"
        (string-join (hash-ref assignments 'graded empty) " ")
        (string-join (hash-ref assignments 'turned-in empty) " ")
        (string-join (hash-ref assignments 'cant-turnin empty) " ")
        (string-join (hash-ref assignments 'can-turnin empty) " "))
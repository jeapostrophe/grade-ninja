#lang racket/base
(require racket/string
         racket/runtime-path
         racket/list
         "username.rkt"
         (for-syntax racket/base
                     "username.rkt"))

(provide current-student-dir
         student-dir
         backup-file
         replace-file
         combined-command-line
         after?
         due-date
         num-exercises
         num-assignments)

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

(define-runtime-path student-dir "../students")
(define-runtime-path current-student-dir (format "../students/~a" (username)))
(define-runtime-path assignments-file "../assignments.rktd")

; after?: Integer -> Boolean
; Checks whether or not the argument is after the current time
(define (after? time)
  (> (current-seconds) time))

; due-date: Integer Boolean -> Integer
; Returns the due date in seconds of the specified assignment
(define (due-date num optional)
  (assignment-due-date (lookup-assignment num optional)))

; num-exercises: Integer Boolean -> Integer
; Returns the number of exercises in the specified assignment
(define (num-exercises num optional)
  (assignment-num-exercises (lookup-assignment num optional)))

; num-assignments: -> Integer
; Returns the total number of assignments
(define (num-assignments)
  (length (assignments)))

(struct assignment (num-exercises due-date))

(define (assignments)
  (with-input-from-file assignments-file read))

; lookup-assignment: Integer Boolean -> assignment
; Finds the specified assignment information in the assignments file
; todo: memoize
(define (lookup-assignment num optional)
  (define assignment-list (assoc num (assignments)))
  (if optional
      (assignment (fourth assignment-list) (fifth assignment-list))
      (assignment (second assignment-list) (third assignment-list))))

(define (final-grade num-assignments scores totals opt-grades)
  (/ (for/sum ([i (in-range num-assignments)])
              (assignment-grade i scores totals opt-grades))
     (sub1 num-assignments)))

(define (assignment-grade num scores totals opt-grades)
  (/ (assignment-score num scores totals opt-grades) (list-ref totals num)))

(define (assignment-score num scores totals opt-grades)
  (cond
    [(= 0 num)
     (fill-in (first scores) (first totals) opt-grades)]
    [else
     (assignment-score (sub1 num) 
                       (rest scores) 
                       (rest totals) 
                       (rest (use-optional (- (first totals) (first scores)) opt-grades)))]))

(define (fill-in score total opt-grades)
  (define available (foldl + 0 opt-grades))
  (min (+ score available) total))

(define (use-optional needed opt-grades)
  (cond
    [(empty? opt-grades) empty]
    [(> (first opt-grades) needed) (cons (- (first opt-grades) needed) (rest opt-grades))]
    [else (cons 0 (use-optional (- needed (first opt-grades)) (rest opt-grades)))]))
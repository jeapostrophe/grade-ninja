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
  (length (with-input-from-file assignments-file read)))

(struct assignment (num-exercises due-date))

; lookup-assignment: Integer Boolean -> assignment
; Finds the specified assignment information in the assignments file
; todo: memoize
(define (lookup-assignment num optional)
  (define assignments (with-input-from-file assignments-file read))
  (define assignment-list (assoc num assignments))
  (if optional
      (assignment (fourth assignment-list) (fifth assignment-list))
      (assignment (second assignment-list) (third assignment-list))))

#!/usr/bin/env racket
#lang racket/base
(require racket/function 
         racket/system
         racket/sequence
         racket/list
         racket/file
         net/sendmail
         "data.rkt")

(define (exercise-graded? file)
  (call-with-input-file* file (curry regexp-match grade-regexp)))

(define assignments (sequence-append (sequence-map number->string (in-range 1 (add1 (num-assignments))))
                                     (sequence-map (λ (n) (string-append (number->string n) "opt")) 
                                                   (in-range 1 (add1 (num-assignments))))))


(define (find-ungraded-assignment)
  (let/ec return
    (for ([assignment assignments])
      (for ([user-dir (in-list (directory-list students-dir))])
        (define assignment-dir (build-path students-dir user-dir assignment))
        (when (directory-exists? assignment-dir)
          (unless (assignment-graded? assignment-dir)
            (return assignment-dir)))))
    #f))


(define assignment-dir (find-ungraded-assignment))

(unless assignment-dir
  (printf "No more assignments to grade.\n")
  (exit))

(define (find-ungraded-exercises assignment-dir)
  (for/list ([exercise-file (in-directory assignment-dir)] #:when (exercise-graded? exercise-file))
    exercise-file))

(define (edit file)
  (void (system (format "$EDITOR ~a" file))))

(printf "I expect a grade line like: ~v\n" grade-regexp)

(define ungraded-exercises (find-ungraded-exercises))

(unless (empty? ungraded-exercises)
  (edit (first ungraded-exercises)))

(define (completely-graded? dir)
  (for/and ([exercise-file (in-directory dir)])
    (exercise-graded? exercise-file)))
    
(define (mark-graded dir)
  (define graded-file (build-path dir ".graded"))
  (with-output-to-file graded-file (λ () (void)))
  (file-or-directory-permissions graded-file #o600))

(when (completely-graded? assignment-dir)
  (mark-graded assignment-dir)
  (define-values (base name must-be-dir) (split-path assignment-dir))
  (define-values (num optional) (parse-assignment-dir assignment-dir))
  (send-mail-message (system-email) (format "[CS142] Assignment ~a graded" name) (list (file->string (build-path base ".email"))) empty empty
                     (list (format "~a," (file->string (build-path base ".name"))) (format-assignment-grade base num optional (num-exercises num optional)))))

(define (num-ungraded-assignments)
  (for*/fold ([num 0])
    ([user-dir (in-list (directory-list students-dir))]
     [assignment-dir (in-list (directory-list (build-path students-dir user-dir)))])
    (define p (build-path students-dir user-dir assignment-dir))
    (if (or (file-exists? p) (assignment-graded? p)) num (add1 num))))

(printf "There are ~a assignments to grade.\n" (num-ungraded-assignments))
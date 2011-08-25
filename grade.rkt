#!/usr/bin/env racket
#lang racket/base
(require racket/function 
         racket/system
         racket/sequence
         "util.rkt"
         "data.rkt")

(define (exercise-graded? file)
  (call-with-input-file* file (curry regexp-match #rx"// Grade")))

(define assignments (sequence-append (sequence-map number->string (in-range (num-assignments)))
                                     (sequence-map (λ (n) (string-append (number->string n) "opt")) 
                                                   (in-range (num-assignments)))))

(define (find-ungraded-file)
  (let/ec return
    (for ([assignment assignments])
      (for ([user-dir (in-list (directory-list students-dir))])
        (define assignment-dir (build-path students-dir user-dir assignment))
        (unless (assignment-graded? assignment-dir)
          (for ([exercise-file (in-directory assignment-dir)])
            (unless (exercise-graded? exercise-file)
              (return exercise-file))))))
    #f))



(define (edit file)
  (system (format "emacs ~a" file)))

(define ungraded-file (find-ungraded-file))

(unless ungraded-file
  (printf "No more assignments to grade.\n")
  (exit))

(edit ungraded-file)

(define (base-dir file)
  (define-values (base name must-be-dir?) (split-path file))
  base)

(define assignment-dir (base-dir ungraded-file))

(define (completely-graded? dir)
  (for/and ([exercise-file (in-directory dir)])
    (exercise-graded? exercise-file)))
    
(define (mark-graded dir)
  (define graded-file (build-path dir ".graded"))
  (with-output-to-file graded-file (λ () (void)))
  (file-or-directory-permissions graded-file #o600))

(define (num-ungraded-assignments)
  (for*/fold ([num 0])
    ([user-dir (in-list (directory-list student-dir))]
     [assignment-dir (in-list (directory-list (build-path student-dir user-dir)))])
    (define p (build-path student-dir user-dir assignment-dir))
    (if (or (file-exists? p) (assignment-graded? p)) num (add1 num))))

(when (completely-graded? assignment-dir)
  (mark-graded assignment-dir)
  ; todo: email grade to student
  )
(printf "There are ~a assignments to grade.\n" (num-ungraded-assignments))
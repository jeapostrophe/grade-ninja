#lang racket/base
(require racket/cmdline
         racket/match
         racket/file
         "data.rkt"
         "compile.rkt"
         "username.rkt")

(define-values (dir num optional)
  (command-line
   #:program "get-graded"
   #:args (assignment)
   (match assignment
     [(regexp #rx"^([0-9]+)(opt)?$" (list dir num opt))
      (values dir (string->number num) (not (not opt)))]
     [else 
      (printf "~a is not a valid assignment\n" assignment)
      (exit)])))

(define turnin-dir (build-path current-student-dir dir))

(unless (assignment-graded? turnin-dir)
  (printf "Assignment ~a hasn't been graded yet.\n" dir)
  (exit))

(define graded-dir (format "graded-~a-~a-~a" (username) dir (current-seconds)))
(define tmp-dir (build-path "/tmp" graded-dir))
(copy-directory/files turnin-dir tmp-dir)
(file-or-directory-permissions tmp-dir #o777)
(for ([file (in-directory tmp-dir)])
  (file-or-directory-permissions file #o644))

(eprintf "Graded files for assignment ~a are in ~a\n" dir graded-dir)
(printf "~a\n" tmp-dir)
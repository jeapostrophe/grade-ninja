#lang racket/base
(require racket/cmdline
         racket/match
         racket/file
         "data.rkt"
         "compile.rkt")

(define-values (dir num optional)
  (command-line
   #:program "turnin"
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

(define graded-dir (format "/tmp/graded-~a-~a" dir (current-seconds)))
(copy-directory/files turnin-dir graded-dir)
(for ([file (in-directory graded-dir)])
  (file-or-directory-permissions file #o311))

(eprintf "Graded files for assignment ~a are in ~a\n" dir graded-dir)
(printf "~a\n" graded-dir)
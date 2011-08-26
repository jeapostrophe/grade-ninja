#lang racket/base
(require racket/cmdline
         racket/match
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

(unless (and (file-exists? (build-path current-student-dir ".email"))
             (file-exists? (build-path current-student-dir ".name")))
  (printf "You must enter your name and email address before turning in assignments.\n")
  (exit))

(when (after? (due-date num optional))
  (printf "The assignment is late and will not be graded.\n")
  (exit))

(define turnin-dir (build-path current-student-dir dir))

(when (directory-exists? turnin-dir)
  (printf "The assignment was already turned in.\n")
  (exit))

(printf "Turning in assignment ~a\n\n" dir)

(make-directory turnin-dir)
(file-or-directory-permissions turnin-dir #o700)

(compile-files dir turnin-dir (num-exercises num optional))

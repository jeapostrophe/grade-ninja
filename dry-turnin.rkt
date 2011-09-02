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

(unless (directory-exists? dir)
  (printf "Cannot find a directory for assignment ~a, make sure you are in the right directory\n\t(the right directory is normally ~~/142)\n\t(which you get to by \"cd ~~/142\")\n\t(right now you are in ~a).\n" dir (current-directory))
  (exit))

(when (after? (due-date num optional))
  (printf "The assignment is late and will not be graded.\n")
  (exit))

(define missing?
  (for/fold ([missing? #f])
    ([i (exercise-seq num optional)])
    (if (file-exists? (build-path dir (format "~a.cc" i)))
        missing?
        (begin
          (printf "Exercise ~a is missing.\n" i)
          (or missing? #t)))))
(when missing? 
  (exit))

(printf "Dry turnin of assignment ~a\n\n" dir)

(compile-files dir #f (exercise-seq num optional))
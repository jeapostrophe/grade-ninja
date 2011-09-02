#lang racket/base
(require racket/cmdline
         racket/match
         "data.rkt"
         "compile.rkt")

(define-values (dir num optional incomplete?)
  (command-line
   #:program "turnin"
   #:args args
   (match args
     [(list (regexp #rx"^([0-9]+)(opt)?$" (list dir num opt)))
      (values dir (string->number num) (not (not opt)) #f)]
     [(list (regexp #rx"^([0-9]+)(opt)?$" (list dir num opt)) "incomplete")
      (values dir (string->number num) (not (not opt)) #t)]
     [else 
      (printf "~a is not a valid assignment\n" args)
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

(define turnin-dir (build-path current-student-dir dir))

(when (directory-exists? turnin-dir)
  (printf "The assignment was already turned in.\n")
  (exit))

(unless incomplete?
  (define missing?
    (for/fold ([missing? #f])
      ([i (exercise-seq num optional)])
      (if (file-exists? (build-path dir (format "~a.cc" i)))
          missing?
          (begin
            (printf "Exercise ~a is missing.\n" i)
            (or missing? #t)))))
  (when missing? 
    (printf "To turn the assignment in anyway, run\n\tturnin ~a incomplete\n" dir)
    (exit)))

(printf "Turning in assignment ~a\n\n" dir)

(make-directory turnin-dir)
(file-or-directory-permissions turnin-dir #o700)

(compile-files dir turnin-dir (exercise-seq num optional))

(printf "Assignment ~a has been turned in successfully\n" dir)

#lang racket/base
(require racket/cmdline
         racket/match
         racket/function
         racket/system
         racket/port
         "data.rkt")

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

(when (after? (due-date num optional))
  (printf "The assignment is late and will not be graded.\n")
  (exit))

(define turnin-dir (build-path current-student-dir dir))

(when (directory-exists? turnin-dir)
  (printf "The assignment was already turned in.\n")
  (exit))

(make-directory turnin-dir)
(file-or-directory-permissions turnin-dir #o700)

(define (system/capture-output command out)
  (match-define (list sout sin _ serr proc) (process command))
  (copy-port serr (current-error-port) out)
  (copy-port sout (current-output-port) out) 
  (proc 'wait)
  (close-input-port sout)
  (close-output-port sin)
  (close-input-port serr)
  (proc 'exit-code))

(for ([i (in-range (num-exercises num optional))])
  (define file (format "~a/~a.cc" dir i))
  (when (file-exists? file)
    (when (call-with-input-file* file (curry regexp-match #rx"// Grade"))
      (printf "Files cannot contain // Grade in them.")
      (exit))
    (define output (open-output-bytes))
    (display "/* Compilation output:\n" output)
    (define compile-command (format "g++ ~a -o ~a/~a" file dir i))
    (printf "~a\n" compile-command)
    (define compile-result (system/capture-output compile-command output))
    (display "*/\n" output)
    (when (zero? compile-result)
      (display "/* Program output:\n" output)
      (define run-command (format "~a/~a" dir i))
      (printf "~a\n" run-command)
      (system/capture-output run-command output)
      (display "*/\n" output))
    (define turnin-file (build-path turnin-dir (format "~a.cc" i)))
    (with-output-to-file turnin-file
      (λ ()
        (display (get-output-bytes output))
        (with-input-from-file file 
          (λ () (copy-port (current-input-port) (current-output-port))))))
    (file-or-directory-permissions turnin-file #o600)))

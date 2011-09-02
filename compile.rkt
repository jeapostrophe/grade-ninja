#lang racket/base
(require racket/match
         racket/system
         racket/port
         racket/function)

(provide compile-files)

(define (system/capture-output command out)
  (match-define (list sout sin _ serr proc) (process command))
  (copy-port serr (current-error-port) out)
  (copy-port sout (current-output-port) out) 
  (proc 'wait)
  (close-input-port sout)
  (close-output-port sin)
  (close-input-port serr)
  (proc 'exit-code))

(define (compile-files dir turnin-dir exercises)
  (define success? #t)
  (for ([i exercises])
    (define file (format "~a/~a.cc" dir i))
    (when (file-exists? file)
      (when (call-with-input-file* file (curry regexp-match #rx"// Grade"))
        (printf "Files cannot contain // Grade in them.\n")
        (exit))
      (define output (open-output-bytes))
      (display "/* Compilation output:\n" output)
      (define compile-command (format "g++ ~a -o ~a/~a" file dir i))
      (printf "Compiling exercise ~a: ~a\n" i compile-command)
      (define compile-result (system/capture-output compile-command output))
      (display "*/\n" output)
      (cond
        [(zero? compile-result)
         (display "/* Program output:\n" output)
         (define run-command (format "~a/~a" dir i))
         (printf "Running exercise ~a: ~a\n" i run-command)
         (system/capture-output run-command output)
         (display "*/\n" output)]
        [else (set! success? #f)])
      (printf "\n")
      (when turnin-dir
        (define turnin-file (build-path turnin-dir (format "~a.cc" i)))
        (with-output-to-file turnin-file
          (λ ()
            (display (get-output-bytes output))
            (with-input-from-file file 
              (λ () (copy-port (current-input-port) (current-output-port))))))
        (file-or-directory-permissions turnin-file #o600))))
  success?)
#lang racket
(require racket/runtime-path
         web-server/servlet
         web-server/dispatch
         web-server/formlets
         web-server/servlet-env)

(define PROBLEMS
  '("No credit"
    "Missing header"
    "Incorrect header"
    "No solution"
    "Incorrect solution"
    "Missing contract"
    "Incorrect contract"
    "Missing purpose statement"
    "Missing template"
    "Incorrect template"
    "Disobeyed template"
    "No data definition"
    "Incorrect data definition"
    "No examples"
    "Missing test development (generalization, distinguishing, etc)"
    "Missing tests in main (from test development)"
    "Not enough tests"
    "Missing substitution"
    "Incorrect substitution"
    "Missing store-tracking"
    "Incorrect store-tracking"
    "Used un-covered features of C++"))

(define PRAISE
  '("You are so amazing, this is the best assignment evar"
    "You has a win!!!!!!"
    "Wonderful!"
    "Very good"
    "Fascinating solution"
    "Totally bodacious"
    "Wicked good!"
    "Tubular or was it tubelar?"
    "If you were a statue, you'd be made of marble. This is that good"
    "This is really good / The assignment is correct / This is a haiku"
    "Soooooooooooooooooooo rad"))

(define (random-list-ref l)
  (list-ref l (random (length l))))

(define how-many-more #f)

(define-runtime-path gw-helper-pth "gw-helper.rkt")

(define (show-file pth)
  (define code (file->string pth))
  
  (match-define
   (list exercise assignment netid)
   (map path->string
        (take (reverse (explode-path pth)) 3)))

  (define problem-form
    (formlet ,((multiselect-input #:attributes `([size ,(number->string (length PROBLEMS))]
                                                 [style "width: 100%"])
                                  PROBLEMS) . => . the-probs)
             the-probs))
  
  (define r
    (send/suspend
     (lambda (k-url)
       (define label
         (format "~a > ~a > ~a > ~a"
                 (if how-many-more
                     (number->string how-many-more)
                     "??")
                 netid assignment exercise))
       (response/xexpr
        `(html (head (title ,label)
                     (script ([type "text/javascript"]
                              [src "/sh/sh_main.js"])
                             "")
                     (script ([type "text/javascript"]
                              [src "/sh/lang/sh_cpp.js"])
                             "")
                     (link ([rel "stylesheet"]
                            [type "text/css"]
                            [href "/sh/css/sh_nedit.css"])
                           "")
                     (link ([type "text/css"]
                            [src "/sh/css/sh_nedit.css"])
                           "")
                     )
               (body ([onload "sh_highlightDocument();"])
                (div ([style "width: 20%; position: fixed; top:30px; right: 5px;"] [valign "top"])
                     (span ,label)
                     (form ([action ,k-url])
                           ,@(formlet-display problem-form) (br)
                           (input ([type "submit"]))))
                (pre ([class "sh_cpp"] [style "width: 80%; white-space: pre-wrap;"])
                     ,code)))))))

  (define probs
    (formlet-process problem-form r))

  (define grade-line
    (match probs
      [(list)
       (format "// Grade 1, ~a" (random-list-ref PRAISE))]
      [(list x)
       (format "// Grade 1, ~a" x)]
      [_
       (format "// Grade 0, ~a" (apply string-append (add-between probs ", ")))]))

  (with-output-to-file
      pth
    #:exists 'replace
    (lambda ()
      (printf "~a\n" grade-line)
      (displayln code))))

(define grade-pth "/users/faculty/jay/courses/2011/fall/142/scripts/grade.rkt")
(define port (+ 9000 (random 100)))
(define l (tcp-listen port 4 #t #f))
(define (start req)
  (putenv "EDITOR" (format "racket -t ~a -- ~a"
                           gw-helper-pth
                           port))
  (define-values (sp stdout stdin stderr)
    (subprocess #f #f #f
                "/users/faculty/jay/local/racket/bin/racket"
                "-t"
                grade-pth))

  (sync
   (handle-evt
    sp
    (lambda _
      (response/xexpr
       `(html (head (title "No assignments available"))
              (body (h1 "All assignments are currently graded."))))))
   (handle-evt
    (tcp-accept-evt l)
    (match-lambda
     [(list from to)
      (define pth (read from))

      (show-file pth)

      (write #t to)
      (flush-output to)
      (close-input-port from)
      (close-output-port to)

      (subprocess-wait sp)

      (match (third (port->lines stdout))
        [(regexp #rx"There are ([0-9]+) ass" (list _ (app string->number x)))
         (set! how-many-more x)]
        [x
         (eprintf "Got ~v\n" x)])
      
      (redirect-to (->url weird (current-seconds)))]))))

(define (weird req i)
  (start req))

(define-values (dispatch ->url)
  (dispatch-rules
   [("") start]
   [((integer-arg)) weird]))

(define-runtime-path static "static")
(serve/servlet dispatch
               #:extra-files-paths (list static)
               #:launch-browser? #f
               #:servlet-regexp #rx""
               #:port 9000)

(tcp-close l)

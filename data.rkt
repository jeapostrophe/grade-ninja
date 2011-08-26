#lang racket/base
(require racket/runtime-path
         racket/list
         racket/contract
         racket/contract/region
         racket/match
         racket/function
         (prefix-in 19: srfi/19)
         "username.rkt"
         (for-syntax racket/base 
                     "username.rkt"))

(provide (struct-out assignment-info)
         (struct-out exercise-grade)
         assignment-graded?
         format-assignment-grade
         format-course-grade
         current-student-dir
         num-exercises
         num-assignments
         grade-regexp
         parse-assignment-dir
         students-dir
         current-student-name
         current-student-email
         system-email
         after?
         due-date)

(struct assignment-info (num-exercises due-date num-opt-exercises opt-due-date) #:transparent)

(struct exercise-grade (num score comment) #:transparent)
(struct assignment-grade (score total) #:transparent)

(define-runtime-path students-dir "../students")
(define-runtime-path current-student-dir (format "../students/~a" (username)))
(define-runtime-path assignments-file "../assignments.rktd")
(define-runtime-path email-file "../.email")

(define grade-regexp #rx"(?m:// Grade (0|1), (.*)$)")

(define (current-student-name)
  (with-input-from-file (build-path current-student-dir ".name") read-line))

(define (current-student-email)
  (with-input-from-file (build-path current-student-dir ".email") read-line))

(define (system-email)
  (with-input-from-file email-file read-line))

(define/contract (read-assignment-infos) (-> (hash/c natural-number/c assignment-info?))
  (let loop ([assignment-infos (hasheq)])
    (define info-list (read))
    (cond
      [(eof-object? info-list)
       assignment-infos]
      [else
       (loop (hash-set assignment-infos (first info-list) (assignment-info (second info-list) (vector->date (third info-list)) (fourth info-list) (vector->date (fifth info-list)))))])))

(define (after? date)
  (19:time>? (19:current-time) (19:date->time-utc date)))

(define assignment-infos (box #f))

(define/contract (get-assignment-infos file) (path? . -> . (hash/c natural-number/c assignment-info?))
  (define infos (unbox assignment-infos))
  (if infos infos (with-input-from-file file read-assignment-infos)))

(define/contract (num-exercises num optional) (natural-number/c boolean? . -> . natural-number/c)
  (define infos (get-assignment-infos assignments-file))
  ((if optional assignment-info-num-opt-exercises assignment-info-num-exercises) (hash-ref infos num)))

(define/contract (num-assignments) (-> natural-number/c)
  (hash-count (get-assignment-infos assignments-file)))

(define/contract (due-date num optional) (natural-number/c boolean? . -> . 19:date?)
  (define infos (get-assignment-infos assignments-file))
  ((if optional assignment-info-due-date assignment-info-opt-due-date) (hash-ref infos num)))

(define/contract (vector->date v) (vector? . -> . 19:date?)
  (call-with-values (λ () (vector->values v 1)) 19:make-date))

(define/contract (format-assignment num optional) (natural-number/c boolean? . -> . string?)
  (format "~a~a" num (if optional "opt" "")))

(define/contract (assignment-graded? assignment-dir) (path? . -> . boolean?)
  (file-exists? (build-path assignment-dir ".graded")))

(define/contract (format-assignment-grade student-dir num optional num-exercises) (path? natural-number/c boolean? natural-number/c . -> . string?)
  (define assignment-dir (build-path student-dir (format-assignment num optional)))
  (define exercise-grades (get-assignment-exercise-grades assignment-dir num-exercises))
  (format "For assignment ~a, you got\n~a\nTotal:~a/~a" (format-assignment num optional) (foldl format-exercise-grade "" exercise-grades) (calculate-assignment-score exercise-grades) num-exercises))

(define/contract (format-exercise-grade grade prefix) (exercise-grade? string? . -> . string?)
  (match-define (exercise-grade num score comment) grade)
  (format "~a~a: ~a, ~a\n" prefix num score comment))

(define/contract (calculate-assignment-score exercise-grades) ((listof exercise-grade?) . -> . natural-number/c)
  (foldl (λ (grade total) (+ (exercise-grade-score grade) total)) 0 exercise-grades))

(define/contract (format-course-grade student-dir) (path? . -> . string?)
  (define current-grades (get-current-grades student-dir))
  (define perfect-grades (fill-grades current-grades 1))
  (define perfect-course-grade (calculate-course-grade perfect-grades))
  (define bad-grades (fill-grades current-grades 0))
  (define bad-course-grade (calculate-course-grade bad-grades))
  (format "Current grade if 100% on all future assignments:\n\n~a% (~a)\n\nCurrent grade if 0% on all future assignments:\n\n~a% (~a)\n" 
          (grade->percent perfect-course-grade) 
          (grade->letter perfect-course-grade) 
          (grade->percent bad-course-grade)
          (grade->letter bad-course-grade)))

(define/contract (get-current-grades student-dir) (path? . -> . (hash/c string? assignment-grade?))
  (for/hash ([assignment-dir (in-list (directory-list student-dir))] #:when (directory-exists? (build-path student-dir assignment-dir)))
    (values (path->string assignment-dir) (get-assignment-grade assignment-dir))))

(define (parse-assignment-dir assignment-dir)
  (match (path->string assignment-dir) 
    [(regexp #rx"([0-9]+)(opt)?/?$" (list _ num opt))
     (values (string->number num) (not (not opt)))]))

(define/contract (get-assignment-grade assignment-dir) (path? . -> . assignment-grade?)
  (define-values (num optional) (parse-assignment-dir assignment-dir))
  (define total (num-exercises num optional))
  (assignment-grade (calculate-assignment-score (get-assignment-exercise-grades assignment-dir total)) total)) 

(define/contract (add-grade grades num optional grade) ((hash/c string? assignment-grade?) natural-number/c boolean? number? . -> . (hash/c string? assignment-grade?))
  (define dir (format "~a~a" num (if optional "opt" "")))
  (define total (num-exercises num optional))
  (hash-set grades dir (assignment-grade (if (after? (due-date num optional)) 0 (* grade total)) total)))

(define/contract (fill-grades current-grades grade) ((hash/c string? assignment-grade?) number? . -> . (hash/c string? assignment-grade?))
  (for/fold ([result current-grades])
    ([i (in-range 1 (add1 (num-assignments)))])
    (define dir (number->string i))
    (define opt-dir (string-append dir "opt"))
    (cond
      [(and (hash-has-key? result dir) (hash-has-key? result opt-dir)) 
       result]
      [(hash-has-key? result dir)
       (add-grade result i #t 0)]
      [(hash-has-key? result opt-dir)
       (add-grade result i #f grade)]
      [else 
       (add-grade (add-grade result i #t 0) i #f grade)])))

(define/contract (calculate-course-grade grades) ((hash/c string? assignment-grade?) . -> . number?)
  (define-values (total-score _)
    (for/fold ([total-score 0]
               [extra 0])
      ([i (in-range (num-assignments) 0 -1)])
      (define dir (number->string i))
      (define opt-dir (string-append dir "opt"))
      (match-define (assignment-grade score total) (hash-ref grades dir))
      (match-define (assignment-grade opt-score opt-total) (hash-ref grades opt-dir))
      (define new-extra (+ opt-score extra))
      (cond
        [(< score total) (values (+ total-score (min total (+ score new-extra))) (max 0 (- new-extra (- total score))))]
        [else (values (+ total-score score) new-extra)])))
  (/ total-score (sub1 (num-assignments))))

(define/contract (grade->percent grade) (number? . -> . number?)
  (/ (round (* 1000 grade)) 100))

(define/contract (grade->letter grade) (number? . -> . string?)
  (cond
    [(>= grade 0.96) "A+"]
    [(>= grade 0.93) "A"]
    [(>= grade 0.90) "A-"]
    [(>= grade 0.86) "B+"]
    [(>= grade 0.83) "B"]
    [(>= grade 0.80) "B-"]
    [(>= grade 0.76) "C+"]
    [(>= grade 0.73) "C"]
    [(>= grade 0.70) "C-"]
    [(>= grade 0.66) "D+"]
    [(>= grade 0.63) "D"]
    [(>= grade 0.60) "D-"]
    [else "E"]))
   
(define/contract (get-assignment-exercise-grades assignment-dir num-exercises) (path? natural-number/c . -> . (listof exercise-grade?)) 
  (for/list ([i (in-range 1 (add1 num-exercises))])
    (get-exercise-grade assignment-dir i)))

(define/contract (get-exercise-grade assignment-dir num) (path? natural-number/c . -> . exercise-grade?)
  (define exercise-file (build-path assignment-dir (format "~a.cc" num)))
  (cond
    [(file-exists? exercise-file)
     (match (call-with-input-file* exercise-file (curry regexp-match grade-regexp))
       [(list _ score-byte-string comment) (exercise-grade num (string->number (bytes->string/utf-8 score-byte-string)) (bytes->string/utf-8 comment))]
       [else 
        (printf "exercise ~a isn't graded\n" num)
        (exit)])]
    [else
     (exercise-grade num 0 "exercise not turned in")]))
     
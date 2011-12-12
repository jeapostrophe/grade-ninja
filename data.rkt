#lang racket/base
(require racket/runtime-path
         racket/list
         racket/contract
         racket/contract/region
         racket/match
         racket/function
         racket/string
         (prefix-in 19: srfi/19)
         "username.rkt"
         (for-syntax racket/base 
                     "username.rkt"))

(provide (struct-out assignment-info)
         (struct-out assignment-grade)
         (struct-out exercise-grade)
         assignment-graded?
         format-assignment-grade
         format-course-grade
         current-student-dir
         num-exercises
         get-assignment-infos
         exercise-seq
         num-assignments
         grade-regexp
         parse-assignment-dir
         students-dir
         current-student-name
         current-student-email
         system-email
         after?
         due-date
         toplevel-dir
         get-current-grades
         calculate-course-grade
         fill-grades
         expected-grade
         mean
         median
         mode
         grade->letter)

(struct assignment-info (num-exercises due-date num-opt-exercises opt-due-date) #:transparent)

(struct exercise-grade (num score comment) #:transparent)
(struct assignment-grade (score total) #:transparent)

(define-runtime-path toplevel-runtime-path "..")
(define toplevel-dir (make-parameter toplevel-runtime-path))

(define (students-dir)
  (build-path (toplevel-dir) "students"))

(define (assignments-file)
  (build-path (toplevel-dir) "assignments.rktd"))

;(define-runtime-path students-dir "../students")
(define-runtime-path current-student-dir (format "../students/~a" (username)))
(define-runtime-path email-file "../.email")


(define (mean lst)
  (if (empty? lst)
      0
      (/ (foldl + 0 lst)
         (length lst))))

(define (median lst)
  (list-ref (sort lst <) (quotient (length lst) 2)))

(define (mode lst)
  (car (argmax cdr (hash->list (foldl (λ (v h) (hash-update h v add1 0)) (hasheq) lst)))))

(define grade-regexp #rx"(?m:// Grade ([^,]*), (.*)$)")

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

(define/contract (get-assignment-infos) (-> (hash/c natural-number/c assignment-info?))
  (define infos (unbox assignment-infos))
  (if infos infos (with-input-from-file (assignments-file) read-assignment-infos)))

(define/contract (num-exercises num optional) (natural-number/c boolean? . -> . natural-number/c)
  ((if optional 
       assignment-info-num-opt-exercises 
       assignment-info-num-exercises) (hash-ref (get-assignment-infos) num)))

(define/contract (num-assignments) (-> natural-number/c)
  (hash-count (get-assignment-infos)))

(define/contract (due-date num optional) (natural-number/c boolean? . -> . 19:date?)
  (define infos (get-assignment-infos))
  ((if optional assignment-info-opt-due-date assignment-info-due-date) (hash-ref infos num)))

(define/contract (vector->date v) (vector? . -> . 19:date?)
  (call-with-values (λ () (vector->values v 1)) 19:make-date))

(define/contract (format-assignment num optional) (natural-number/c boolean? . -> . string?)
  (format "~a~a" num (if optional "opt" "")))

(define/contract (assignment-graded? assignment-dir) (path? . -> . boolean?)
  (file-exists? (build-path assignment-dir ".graded")))

(define/contract (format-assignment-grade student-dir num optional) (path? natural-number/c boolean? . -> . string?)
  (define assignment-dir (build-path student-dir (format-assignment num optional)))
  (define exercise-grades (get-assignment-exercise-grades assignment-dir (exercise-seq num optional)))
  (format "For assignment ~a, you got\n~a\nTotal:~a/~a\n" 
          (format-assignment num optional) 
          (foldl format-exercise-grade "" exercise-grades) 
          (calculate-assignment-score exercise-grades) 
          (num-exercises num optional)))

(define/contract (format-exercise-grade grade prefix) (exercise-grade? string? . -> . string?)
  (match-define (exercise-grade num score comment) grade)
  (format "~aExercise ~a: ~a, ~a\n" prefix num score comment))

(define/contract (calculate-assignment-score exercise-grades) ((listof exercise-grade?) . -> . number?)
  (foldl (λ (grade total) (+ (exercise-grade-score grade) total)) 0 exercise-grades))


(define (assignment<? a b)
  (define-values (a-num a-opt) (parse-assignment-dir a))
  (define-values (b-num b-opt) (parse-assignment-dir b))
  (if (= a-num b-num)
      (and (not a-opt) b-opt)
      (< a-num b-num)))

(define (format-grades grades)
  (string-join 
   (map (match-lambda
          [(cons dir (assignment-grade score total))
           (format "\tAssignment ~a: ~a/~a" dir score total)])
        (sort (hash->list grades) assignment<? #:key car))
  "\n"))

(define (expected-grade grades)
  (mean 
   (filter-map (match-lambda 
                 [(cons (regexp #rx"[0-9]+") (assignment-grade score total))
                  (/ score total)]
                 [else #f])
               (hash->list grades))))
  
(define/contract (format-course-grade student-dir) (path? . -> . string?)
  (define current-grades (get-current-grades student-dir))
  (define perfect/opt-grades (fill-grades current-grades 1 1))
  (define perfect/opt-course-grade (calculate-course-grade perfect/opt-grades))
  (define perfect-grades (fill-grades current-grades 1 0))
  (define perfect-course-grade (calculate-course-grade perfect-grades))
  (define expected (expected-grade current-grades))
  (define expected-grades (fill-grades current-grades expected 0))
  (define expected-course-grade (calculate-course-grade expected-grades))
  (define bad-grades (fill-grades current-grades 0 0))
  (define bad-course-grade (calculate-course-grade bad-grades))
  (format "Current assignment grades:\n~a

Current grade if 100% on all future assignments (including optional assignments):\n\n\t~a% (~a)

Current grade if 100% on all future assignments (NOT including optional assignments):\n\n\t~a% (~a)

Current grade if ~a% (your current average) on all future assignments:\n\n\t~a% (~a) 

Current grade if 0% on all future assignments:\n\n\t~a% (~a)\n" 
          (format-grades current-grades)
          (real->decimal-string (* 100 perfect/opt-course-grade) 2) 
          (grade->letter perfect/opt-course-grade) 
          (real->decimal-string (* 100 perfect-course-grade) 2) 
          (grade->letter perfect-course-grade) 
          (real->decimal-string (* 100 expected) 2)
          (real->decimal-string (* 100 expected-course-grade) 2)
          (grade->letter expected-course-grade)          
          (real->decimal-string (* 100 bad-course-grade) 2)
          (grade->letter bad-course-grade)))

(define/contract (get-current-grades student-dir) (path? . -> . (hash/c string? assignment-grade?))
  (for/hash ([assignment-dir (in-list (directory-list student-dir))] #:when (assignment-graded? (build-path student-dir assignment-dir)))
    (values (path->string assignment-dir) (get-assignment-grade (build-path student-dir assignment-dir)))))

(define (parse-assignment-dir assignment-dir)
  (match (if (path? assignment-dir) (path->string assignment-dir) assignment-dir) 
    [(regexp #rx"([0-9]+)(opt)?/?$" (list _ num opt))
     (values (string->number num) (not (not opt)))]))

(define (exercise-seq num optional)
  (if optional 
      (in-range (add1 (num-exercises num #f)) (+ 1 (num-exercises num #f) (num-exercises num #t)))
      (in-range 1 (add1 (num-exercises num #f)))))

(define/contract (get-assignment-grade assignment-dir) (path? . -> . assignment-grade?)
  (define-values (num optional) (parse-assignment-dir assignment-dir))
  (define total (num-exercises num optional))
  (assignment-grade (calculate-assignment-score (get-assignment-exercise-grades assignment-dir (exercise-seq num optional))) total)) 

(define/contract (add-grade grades num optional grade) ((hash/c string? assignment-grade?) natural-number/c boolean? number? . -> . (hash/c string? assignment-grade?))
  (define dir (format "~a~a" num (if optional "opt" "")))
  (define total (num-exercises num optional))
  (hash-set grades dir (assignment-grade (if (after? (due-date num optional)) 0 (* grade total)) total)))

(define/contract (fill-grades current-grades grade opt-grade) ((hash/c string? assignment-grade?) number? number? . -> . (hash/c string? assignment-grade?))
  (for/fold ([result current-grades])
    ([i (in-range 1 (add1 (num-assignments)))])
    (define dir (number->string i))
    (define opt-dir (string-append dir "opt"))
    (cond
      [(and (hash-has-key? result dir) (hash-has-key? result opt-dir)) 
       result]
      [(hash-has-key? result dir)
       (add-grade result i #t opt-grade)]
      [(hash-has-key? result opt-dir)
       (add-grade result i #f grade)]
      [else 
       (add-grade (add-grade result i #t opt-grade) i #f grade)])))

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
      
      (define effective-score
        (if (< score total)
            (min total (+ score new-extra))
            score))
      (define extra-after-grace
        (- new-extra
           (- effective-score score)))
      
      (values (+ total-score
                 (/ effective-score
                    total))
              extra-after-grace)))
  (/ total-score (sub1 (num-assignments))))

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
   
(define/contract (get-assignment-exercise-grades assignment-dir exercises) (path? sequence? . -> . (listof exercise-grade?)) 
  (for/list ([i exercises])
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
     

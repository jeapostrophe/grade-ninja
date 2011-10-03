#lang racket/base
(require racket/list
         racket/function
         racket/match
         racket/file
         racket/string
         (except-in "data.rkt" assignment-graded? num-exercises))

(provide format-assignment-stats
         parse-exercise-grade
         assignment-score
         assignment-scores
         format-assignment-exercise-stats
         assignment-exercise-grades
         (struct-out assignment))

(struct assignment (dir num opt) #:transparent)



(define (format-assignment-stats assignment)
  (define scores (assignment-scores assignment))
  (if (empty? scores)
      (format "Statistics for Assignment ~a:
\tTurned in:\t~a/~a
\tGraded:\t\t~a/~a

\tPossible:\t~a\n"
      (assignment-dir assignment)
      (num-turned-in assignment)
      (num-students)
      (num-graded assignment)
      (num-turned-in assignment)
      (num-exercises assignment))        
  (format 
   "Statistics for Assignment ~a:
\tTurned in:\t~a/~a
\tGraded:\t\t~a/~a

\tPossible:\t~a
\tMean:\t\t~a
\tMedian:\t\t~a
\tMode:\t\t~a
\tMin:\t\t~a
\tMax:\t\t~a

~a
" 
 (assignment-dir assignment)
 (num-turned-in assignment)
 (num-students)
 (num-graded assignment)
 (num-turned-in assignment)
 (num-exercises assignment)
 (mean scores)
 (median scores)
 (mode scores)
 (argmin values scores)
 (argmax values scores)
 (format-assignment-exercise-stats assignment)
 )))

(define (mean lst)
  (/ (foldl + 0 lst)
     (length lst)))

(define (median lst)
  (list-ref (sort lst <) (quotient (length lst) 2)))

(define (mode lst)
  (car (argmax cdr (hash->list (foldl (λ (v h) (hash-update h v add1 0)) (hasheq) lst)))))

(define (num-turned-in assignment)
  (count (λ (student) (directory-exists? (build-path (students-dir) student (assignment-dir assignment)))) (students)))

(define (num-students)
  (length (students)))

(define (students)
  (directory-list (students-dir)))

(define (num-graded assignment)
  (count (curry assignment-graded? assignment) (students))) 

(define (assignment-scores assignment)
  (map (curry assignment-score assignment) (filter (curry assignment-graded? assignment) (students))))

(define (assignment-score assignment student)
  (foldl + 0 (exercise-scores assignment student)))

(define (assignment-graded? assignment student)
  (file-exists? (build-path (students-dir) student (assignment-dir assignment) ".graded")))

(define (exercise-scores assignment student)
  (map exercise-grade-score (exercise-grades assignment student)))

(define (exercise-grades assignment student)
  (for/list ([exercise (in-exercises assignment)])
    (parse-exercise-grade exercise (build-path (students-dir) student (assignment-dir assignment) (format "~a.cc" exercise)))))

(define (in-exercises an-assignment)
  (define-values (count opt-count) (both-num-exercises an-assignment))
  (match-define (assignment dir num opt?) an-assignment)
  (if opt? 
      (in-range (add1 count) (+ count opt-count 1))
      (in-range 1 (add1 count))))
    
(define (parse-exercise-grade num path)
  (cond
    [(file-exists? path)
     (match (file->string path)
       [(regexp grade-regexp (list _ score-string comment)) (exercise-grade num (string->number score-string) comment)]
       [else (error 'parse-exercise-grade "Couldn't find a grade in ~a" path)])]
    [else
     (exercise-grade num 0 "exercise not turned in")]))

(define (num-exercises an-assignment)
  (match-define (assignment dir num optional?) an-assignment)
  (define-values (n opt-n) (both-num-exercises an-assignment))
  (if optional? opt-n n))

(define (both-num-exercises an-assignment)
  (match-define (assignment dir num optional?) an-assignment)
  (match-define (assignment-info num-exercises _ num-opt-exercises _) (hash-ref (get-assignment-infos) num))
  (values num-exercises num-opt-exercises))

(define (assignment-exercise-grades assignment)
  (map (curry exercise-grades assignment) (filter (curry assignment-graded? assignment) (students))))

(define (transpose mat)
  (apply map list mat))

(define (format-assignment-exercise-stats assignment)
  (define grades (assignment-exercise-grades assignment))
  (define exercise-nums (map exercise-grade-num (first grades)))
  (define exercise-grades (transpose grades))
  (string-join (map format-exercise-stats exercise-nums exercise-grades) "\n\n"))

(define (format-exercise-stats num exercise-grades)
  (format "Exercise ~a:\n\tMean: ~a\n\tCommon Comments: ~a" 
          num 
          (mean (map exercise-grade-score exercise-grades)) 
          (common-comments (map exercise-grade-comment exercise-grades))))

; todo: ask Jay about filtering out the good comments
(define (common-comments comments)
  (string-join (top-n (flatten (map (curry regexp-split #rx", *") comments)) 2) ", "))

(define (top-n lst n)
  (define sorted (map car (sort (hash->list (foldl (λ (v h) (hash-update h v add1 0)) (hash) lst)) > #:key cdr)))
  (if (> (length sorted) n)
      (take sorted n)
      sorted))
  
  


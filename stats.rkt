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
         (struct-out assignment)
         format-course-stats)

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

Students who didn't turn in the assignment: 

~a
" 
 (assignment-dir assignment)
 (num-turned-in assignment)
 (num-students)
 (num-graded assignment)
 (num-turned-in assignment)
 (num-exercises assignment)
 (real->decimal-string (mean scores))
 (real->decimal-string (median scores))
 (real->decimal-string (mode scores))
 (real->decimal-string (argmin values scores))
 (real->decimal-string (argmax values scores))
 (format-assignment-exercise-stats assignment)
 (format-not-turned-in assignment)
 )))

(define (format-not-turned-in assignment)
  (define not-turned-in (filter (λ (student) (not (directory-exists? (build-path (students-dir) student (assignment-dir assignment))))) (students)))
  (string-join (map name/email not-turned-in) "\n"))

(define (name/email student)
  (format "\"~a\" <~a>" 
          (file->string/unknown (build-path (students-dir) student ".name"))
          (file->string/unknown (build-path (students-dir) student ".email"))))

(define (file->string/unknown path)
  (if (file-exists? path)
      (file->string path)
      "Unknown"))

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
          (real->decimal-string (mean (map exercise-grade-score exercise-grades)) 3) 
          (common-comments (map exercise-grade-comment exercise-grades))))

(define (common-comments comments)
  (string-join (top-n (flatten (map (curry regexp-split #rx", *") comments)) 2) ", "))

(define (top-n lst n)
  (define sorted (map car (sort (hash->list (foldl (λ (v h) (hash-update h v add1 0)) (hash) lst)) > #:key cdr)))
  (if (> (length sorted) n)
      (take sorted n)
      sorted))



(define (current-course-grades)
  (define grades (map (λ (student) (get-current-grades (build-path (students-dir) student))) (students)))
  (define ((course-grade score opt-score) assignment-grades)
    (calculate-course-grade (fill-grades assignment-grades score opt-score)))
  
  (define perfect/opt-grades (map (course-grade 1 1) grades))
  (define perfect-grades (map (course-grade 1 0) grades))
  (define expecteds (map expected-grade grades))
  (define expected-grades (map (λ (student-grades expected) ((course-grade expected 0) student-grades)) grades expecteds))
  (define bad-grades (map (course-grade 0 0) grades))
  (values perfect/opt-grades perfect-grades expected-grades bad-grades))

(define (percentage n)
  (string-append (real->decimal-string (* 100 n)) "%"))

(define (format-course-stats/grades label grades)
  (format "~a:\n\tMin: ~a\tMean: ~a\tMedian: ~a\tMax: ~a"
          label
          (percentage (argmin values grades))
          (percentage (mean grades))
          (percentage (median grades))
          (percentage (argmax values grades))))

(define (format-course-stats)
  (define-values (perfect/opt-grades perfect-grades expected-grades bad-grades) (current-course-grades))
  (format "~a\n\n~a\n\n~a\n\n~a\n" 
          (format-course-stats/grades "Perfect (with optional)" perfect/opt-grades)
          (format-course-stats/grades "Perfect" perfect-grades)
          (format-course-stats/grades "Expected" expected-grades)
          (format-course-stats/grades "None" bad-grades)))
          
  
  
  


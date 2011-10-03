#lang racket/base
(require tests/eli-tester)
(require "stats.rkt"
         "data.rkt")

(error-print-width 2048)

(parameterize ([toplevel-dir "test"])
  (test 
   (format-assignment-stats (assignment "1" 1 #f))
   =>
"Statistics for Assignment 1:
\tTurned in:\t10/17
\tGraded:\t\t6/10

\tPossible:\t6
\tMean:\t\t7/6
\tMedian:\t\t1
\tMode:\t\t0
\tMin:\t\t0
\tMax:\t\t4

Exercise 1:
\tMean: 1/2
\tCommon Comments: exercise not turned in, you win

Exercise 2:
\tMean: 1/3
\tCommon Comments: exercise not turned in, you win again

Exercise 3:
\tMean: 1/6
\tCommon Comments: exercise not turned in, you win

Exercise 4:
\tMean: 1/6
\tCommon Comments: exercise not turned in, you win

Exercise 5:
\tMean: 0
\tCommon Comments: exercise not turned in

Exercise 6:
\tMean: 0
\tCommon Comments: exercise not turned in
"

(parse-exercise-grade 1 "test/students/blake/1/1.cc") =>
(exercise-grade 1 1 "you win")


(assignment-score (assignment "1" 1 #f) "blake") =>
4

(assignment-scores (assignment "1" 1 #f)) =>
'(4 1 2 0 0 0)

(format-assignment-exercise-stats (assignment "1" 1 #f)) =>
"Exercise 1:\n\tMean: 1/2\n\tCommon Comments: exercise not turned in, you win

Exercise 2:\n\tMean: 1/3\n\tCommon Comments: exercise not turned in, you win again

Exercise 3:\n\tMean: 1/6\n\tCommon Comments: exercise not turned in, you win

Exercise 4:\n\tMean: 1/6\n\tCommon Comments: exercise not turned in, you win

Exercise 5:\n\tMean: 0\n\tCommon Comments: exercise not turned in

Exercise 6:\n\tMean: 0\n\tCommon Comments: exercise not turned in"))
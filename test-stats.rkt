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
\tGraded:\t\t8/10

\tPossible:\t6
\tMean:\t\t0.88
\tMedian:\t\t0.00
\tMode:\t\t0.00
\tMin:\t\t0.00
\tMax:\t\t4.00

Exercise 1:
\tMean: 0.375
\tCommon Comments: exercise not turned in, you win

Exercise 2:
\tMean: 0.250
\tCommon Comments: exercise not turned in, you win again

Exercise 3:
\tMean: 0.125
\tCommon Comments: exercise not turned in, you win

Exercise 4:
\tMean: 0.125
\tCommon Comments: exercise not turned in, you win

Exercise 5:
\tMean: 0.000
\tCommon Comments: exercise not turned in

Exercise 6:
\tMean: 0.000
\tCommon Comments: exercise not turned in
"

(parse-exercise-grade 1 "test/students/blake/1/1.cc") =>
(exercise-grade 1 1 "you win")


(assignment-score (assignment "1" 1 #f) "blake") =>
4

(assignment-scores (assignment "1" 1 #f)) =>
'(4 1 2 0 0 0 0 0)


(format-course-stats) =>

"Perfect (with optional):\nMin: 105.26%\tMean: 105.26%\tMedian 105.26%\tMax: 105.26%\n\nPerfect:\nMin: 68.42%\tMean: 68.94%\tMedian 68.42%\tMax: 74.56%\n\nNone:\nMin: 0.00%\tMean: 0.83%\tMedian 0.00%\tMax: 11.40%\n"

))
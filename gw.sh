#!/bin/sh

scp gw* y:local/grade-ninja && \
ssh -t -x -L 8080:localhost:8080 y "racket -t ~/local/grade-ninja/gw.rkt"

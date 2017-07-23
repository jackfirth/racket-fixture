#lang info
(define collection "fixture")
(define scribblings
  '(("scribblings/main.scrbl" () (library) "fixture")))
(define version "0.1")
(define deps
  '("fancy-app"
    "rackunit-lib"
    "base"
    "disposable"))
(define build-deps
  '("racket-doc"
    "rackunit-doc"
    "scribble-lib"))

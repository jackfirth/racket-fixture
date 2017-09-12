#lang info
(define collection "fixture")
(define scribblings
  '(("scribblings/main.scrbl" () (library) "fixture")))
(define version "0.1")
(define deps
  '("reprovide-lang"
    "fancy-app"
    ("rackunit-lib" #:version "1.8")
    "base"
    ("disposable" #:version "0.2")))
(define build-deps
  '("doc-coverage"
    "racket-doc"
    "rackunit-doc"
    "scribble-lib"))

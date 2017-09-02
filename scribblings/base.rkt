#lang racket/base

(provide (for-label (all-from-out disposable
                                  disposable/example
                                  disposable/file
                                  fixture
                                  fixture/base
                                  fixture/rackunit
                                  racket/base
                                  racket/contract
                                  racket/function
                                  rackunit))
         fixture-examples)

(require (for-label disposable
                    disposable/example
                    disposable/file
                    fixture
                    fixture/base
                    fixture/rackunit
                    racket/base
                    racket/contract
                    racket/function
                    rackunit)
         scribble/example
         syntax/parse/define
         "util.rkt")

(require "util.rkt")

(define-tech-helpers
  fixture-tech "fixture"
  info-tech "fixture info"
  disposable-tech "disposable" disposable/scribblings/main
  parameter-tech "parameter" scribblings/guide/guide)

(define (make-fixture-eval)
  (make-base-eval #:lang 'racket/base
                  '(require disposable
                            disposable/example
                            disposable/file
                            fixture
                            racket/function
                            rackunit)))

(define-simple-macro (fixture-examples example:expr ...)
  (examples #:eval (make-fixture-eval) example ...))

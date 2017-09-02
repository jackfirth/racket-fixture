#lang racket/base

(require racket/contract/base)

(provide test-begin/fixture
         test-case/fixture)

(require (for-syntax racket/base)
         racket/function
         rackunit
         syntax/parse/define
         "base.rkt")


(define (fixture->check-info fix)
  (make-check-info (fixture-name fix) (fixture-info fix)))

(define (call/infos fixs thnk)
  (with-check-info (['fixtures (nested-info (map fixture->check-info fixs))])
    (thnk)))

(define (call/fixtures fixs thnk)
  ((for/fold ([thnk thnk])
             ([fix (in-list fixs)])
     (thunk (call/fixture fix thnk)))))

(define (around/fixtures fixs thnk)
  (call/fixtures fixs (thunk (call/infos fixs thnk))))

(define (call/test-case-around/fixtures fixs thnk)
  (define old-around (current-test-case-around))
  (define (around thnk) (old-around (thunk (around/fixtures fixs thnk))))
  (parameterize ([current-test-case-around around]) (thnk)))
  
(define-simple-macro
  (test-begin/fixture (~seq (~seq #:fixture fixture:expr) ...) body:expr ...+)
  (call/test-case-around/fixtures (list fixture ...)
                                  (thunk (test-begin body ...))))

(define-simple-macro
  (test-case/fixture name:str
    (~seq (~seq #:fixture fixture:expr) ...)
    body:expr ...+)
  (call/test-case-around/fixtures (list fixture ...)
                                  (thunk (test-case name body ...))))

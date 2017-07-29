#lang racket/base

(require racket/contract/base)

(provide
 test-begin/fixture
 test-case/fixture
 (contract-out
  [call/test-fixture (-> fixture? (-> any) any)]))

(require (for-syntax racket/base
                     "private/syntax.rkt")
         racket/function
         rackunit
         syntax/parse/define
         "base.rkt")

(define fixture-infos (make-parameter '()))

(define (call/fixture-info fix thunk)
  (define new-info (make-check-info (fixture-name fix) (fixture-info fix)))
  (parameterize ([fixture-infos (cons new-info (fixture-infos))])
    (with-check-info (['fixtures (nested-info (fixture-infos))])
      (thunk))))

(define (call/test-fixture fix thnk)
  (define old-around (current-test-case-around))
  (define (fixture-around test-thnk)
    (old-around
     (thunk (call/fixture fix (thunk (call/fixture-info fix test-thnk))))))
  (parameterize ([current-test-case-around fixture-around])
    (thnk)))

(define-simple-macro (with-test-fixture fix:expr body:expr ...+)
  (call/test-fixture fix (thunk body ...)))

(define-syntax-parser with-test-fixture*
  [(_ () body:expr ...+) #'(let () body ...)]
  [(_ (fix:expr rest:expr ...) body:expr ...+)
   #'(with-test-fixture fix (with-test-fixture* (rest ...) body ...))])

(define-simple-macro
  (test-begin/fixture (~seq fixture:fixture-clause ...) body:expr ...+)
  (with-test-fixture* (fixture.id ...) (test-begin body ...)))

(define-simple-macro
  (test-case/fixture name:str (~seq fixture:fixture-clause ...) body:expr ...+)
  (with-test-fixture* (fixture.id ...) (test-case name body ...)))

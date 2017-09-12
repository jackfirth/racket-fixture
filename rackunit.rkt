#lang racket/base

(require racket/contract/base)

(provide test-begin/fixture
         test-case/fixture)

(require (for-syntax racket/base)
         racket/function
         racket/list
         rackunit
         syntax/parse/define
         "base.rkt")


(define (fixture->check-info fix)
  (make-check-info (fixture-name fix) (fixture-info fix)))

(define current-test-fixtures (make-parameter '()))

(define (call/test-fixtures fixs thnk)
  (parameterize ([current-test-fixtures (append (current-test-fixtures) fixs)])
    (thnk)))

(define (compute-infos)
  (nested-info (map fixture->check-info (current-test-fixtures))))

(define (call/test-fixtures-info thnk)
  (if (empty? (current-test-fixtures))
      (with-check-info (['fixtures (dynamic-info compute-infos)]) (thnk))
      (thnk)))

(define (test-case-around/fixtures fixs thnk)
  ((for/fold ([thnk thnk])
             ([fix (in-list fixs)])
     (thunk (call/fixture fix thnk)))))

;; Everything needed to properly call a test case with fixtures
(define (call/test-fixture-context fixs test-thnk)
  (define old-around (current-test-case-around))
  (define (new-around thnk)
    (test-case-around/fixtures fixs (thunk (old-around thnk))))
  (define (test-thnk*)
    (parameterize ([current-test-case-around new-around])
      (test-thnk)))
  (call/test-fixtures-info (thunk (call/test-fixtures fixs test-thnk*))))

(begin-for-syntax
  (define-splicing-syntax-class fixtures
    (pattern (~seq (~seq #:fixture fixture:expr) ...)
             #:with list #'(list fixture ...))))

(define-simple-macro
  (test-begin/fixture fixs:fixtures body:expr ...+)
  (call/test-fixture-context fixs.list (thunk (test-begin body ...))))

(define-simple-macro
  (test-case/fixture name:str fixs:fixtures body:expr ...+)
  (call/test-fixture-context fixs.list (thunk (test-case name body ...))))

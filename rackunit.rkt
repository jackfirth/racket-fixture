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
      (with-check-info (['fixture (dynamic-info compute-infos)]) (thnk))
      (thnk)))

(define (test-case-around/fixtures old-around fixs thnk)
  (old-around
   (thunk
    ((for/fold ([thnk thnk])
               ([fix (in-list (current-test-fixtures))])
       (thunk (call/fixture fix thnk)))))))

(define-simple-macro
  (test-begin/fixture (~seq (~seq #:fixture fixture:expr) ...) body:expr ...+)
  #:with (fix-id ...) (generate-temporaries #'(fixture ...))
  (let* ([fix-id fixture] ...
         [all-fixs (list fix-id ...)]
         [old-around (current-test-case-around)])
    (call/test-fixtures-info
     (thunk
      (call/test-fixtures
       all-fixs (thunk
                 (test-case-around/fixtures
                  old-around all-fixs (thunk (test-begin body ...)))))))))


(define-simple-macro
  (test-case/fixture name:str
    (~seq (~seq #:fixture fixture:expr) ...)
    body:expr ...+)
  #:with (fix-id ...) (generate-temporaries #'(fixture ...))
  (let* ([fix-id fixture] ...
         [all-fixs (list fix-id ...)]
         [old-around (current-test-case-around)])
    (call/test-fixtures-info
     (thunk
      (call/test-fixtures
       all-fixs (thunk
                 (test-case-around/fixtures
                  old-around all-fixs (thunk (test-case name body ...)))))))))

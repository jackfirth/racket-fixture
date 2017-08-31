#lang racket/base

(require disposable
         disposable/testing
         doc-coverage
         fixture
         fixture/base
         fixture/rackunit
         racket/function
         racket/list
         rackunit
         "util.rkt")


(define item/log (disposable/event-log (sequence->disposable '(1 2 3))))

(test-case "test-begin/fixture"
  (with-disposable ([item+log item/log])
    (define-fixture item (first item+log))
    (define (item-evts) (event-log-events (second item+log)))
    (test-begin/fixture
      #:fixture item
      (check-equal? (item) 1)
      (test-case "first-nested" (check-equal? (item) 2))
      (test-case "second-nested" (check-equal? (item) 3))
      (check-equal? (item) 1)
      (define expected-log
        '((alloc 1) (alloc 2) (dealloc 2) (alloc 3) (dealloc 3)))
      (check-equal? (item-evts) expected-log))))

(test-case "test-begin/fixture multiple"
  (define-fixture foo-fix (disposable-pure 'foo))
  (define-fixture bar-fix (disposable-pure 'bar))
  (test-begin/fixture
    #:fixture foo-fix
    #:fixture bar-fix
    (check-equal? (foo-fix) 'foo)
    (check-equal? (bar-fix) 'bar)))

(define-fixture foo-fix (disposable-pure 'foo))
(test-case/fixture "test-case/fixture"
  #:fixture foo-fix
  (check-equal? (foo-fix) 'foo)
  (check-equal? (current-test-name) "test-case/fixture"))

(test-case "fixture constructor"
  (check-pred fixture? (fixture 'foo (disposable-pure 'foo)))
  (check-pred fixture?
              (fixture 'bar (disposable-pure 'bar) #:info-proc symbol->string)))

(test-case "define-fixture contracts"
  (check-equal? ((def->thunk (define foo 1))) (void))
  (check-exn exn:fail:contract? (def->thunk (define-fixture foo 5)))
  (check-exn exn:fail:contract?
             (def->thunk
               (define-fixture foo (disposable-pure 'foo) #:info-proc 5)))
  (define (no-args) (void))
  (check-equal? (no-args) (void))
  (check-exn exn:fail:contract?
             (def->thunk
               (define-fixture foo (disposable-pure 'foo) #:info-proc no-args))))

(test-case "documentation"
  (check-all-documented 'fixture)
  (check-all-documented 'fixture/base)
  (check-all-documented 'fixture/rackunit))

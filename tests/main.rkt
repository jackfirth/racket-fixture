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
         rackunit/meta
         "util.rkt")


(define item/log (disposable/event-log (sequence->disposable '(1 2 3))))

(test-case "test-begin/fixture"
  (with-disposable ([item+log item/log])
    (define-fixture item (first item+log))
    (define (item-evts) (event-log-events (second item+log)))
    (test-begin/fixture
      #:fixture item
      (check-equal? (current-item) 1)
      (test-case "first-nested" (check-equal? (current-item) 2))
      (test-case "second-nested" (check-equal? (current-item) 3))
      (check-equal? (current-item) 1)
      (define expected-log
        '((alloc 1) (alloc 2) (dealloc 2) (alloc 3) (dealloc 3)))
      (check-equal? (item-evts) expected-log))))

(test-case "test-begin/fixture multiple"
  (define-fixture foo-fix (disposable-pure 'foo))
  (define-fixture bar-fix (disposable-pure 'bar))
  (test-begin/fixture
    #:fixture foo-fix
    #:fixture bar-fix
    (check-equal? (current-foo-fix) 'foo)
    (check-equal? (current-bar-fix) 'bar)))

(test-case "test-begin/fixture nested"
  (define-fixture foo (sequence->disposable '(1 2 3)))
  (define-fixture bar (sequence->disposable '(a b c)))
  (test-begin/fixture
    #:fixture foo
    (check-equal? (current-foo) 1)
    (test-begin/fixture
      #:fixture bar
      (check-equal? (current-foo) 2)
      (check-equal? (current-bar) 'a))
    (check-equal? (current-foo) 1)))

(test-case "test-begin/fixture info"
  (define-fixture foo (disposable-pure 'foo))
  (define (failing-test)
    (test-begin/fixture
      #:fixture foo
      (check-equal? 1 2)))
  (define failure
    (parameterize ([current-test-case-around (λ (thnk) (thnk))]
                   [current-check-around (λ (thnk) (thnk))])
      (with-handlers ([exn:test:check? values])
        (failing-test))))
  (define (is-fixtures-info? info)
    (equal? (check-info-name info) 'fixtures))
  (define (has-fixtures? stack) (ormap is-fixtures-info? stack))
  (define stack (exn:test:check-stack failure))
  (check-pred has-fixtures? stack)
  (check-pred dynamic-info? (check-info-value (findf is-fixtures-info? stack))))

(define-fixture foo-fix (disposable-pure 'foo))
(test-case/fixture "test-case/fixture"
  #:fixture foo-fix
  (check-equal? (current-foo-fix) 'foo)
  (check-equal? (current-test-name) "test-case/fixture"))

(test-case "fixture constructor"
  (check-pred fixture? (fixture 'foo (disposable-pure 'foo)))
  (check-pred fixture?
              (fixture 'bar (disposable-pure 'bar) #:info-proc symbol->string)))

(test-case "fixture-initialized?"
  (define-fixture foo (disposable-pure 'foo))
  (check-false (fixture-initialized? foo))
  (call/fixture foo
    (thunk (check-true (fixture-initialized? foo))
           (call/fixture foo
             (thunk (check-true (fixture-initialized? foo)))))))

(test-case "fixture-info"
  (define-fixture foo (disposable-pure 'foo) #:info-proc symbol->string)
  (call/fixture foo
    (thunk (check-equal? (fixture-info foo) "foo"))))

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
               (define-fixture foo (disposable-pure 'foo)
                 #:info-proc no-args)))
  (define-fixture foo (disposable-pure 'foo) #:accessor-name get-foo)
  (check-exn exn:fail:contract? get-foo))

(test-case "documentation"
  (check-all-documented 'fixture)
  (check-all-documented 'fixture/base)
  (check-all-documented 'fixture/rackunit))

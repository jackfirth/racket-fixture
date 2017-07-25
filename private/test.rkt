#lang racket/base

(module+ test
  (require disposable
           disposable/testing
           doc-coverage
           fixture
           fixture/base
           fixture/rackunit
           rackunit))

(module+ test
  (test-case "test-begin/fixture"
    (define-values (seq log)
      (disposable/event-log (sequence->disposable '(1 2 3))))
    (define-fixture item seq)
    (test-begin/fixture
      #:fixture item
      (check-equal? (item) 1)
      (test-case "first-nested" (check-equal? (item) 2))
      (test-case "second-nested" (check-equal? (item) 3))
      (check-equal? (item) 1))
    (define expected-log
      '((alloc 1) (alloc 2) (dealloc 2) (alloc 3) (dealloc 3) (dealloc 1)))
    (check-equal? (log) expected-log))
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
  (test-case "documentation"
    (check-all-documented 'fixture)
    (check-all-documented 'fixture/base)
    (check-all-documented 'fixture/rackunit)))

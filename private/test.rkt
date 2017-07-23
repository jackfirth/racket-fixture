#lang racket/base

(module+ test
  (require disposable
           disposable/testing
           fixture
           rackunit))

(module+ test
  (test-case "test-begin/fixture"
    (define-values (seq log)
      (disposable/event-log (sequence->disposable '(1 2 3))))
    (define item (fixture seq))
    (test-begin/fixture
      #:fixture item
      (check-equal? (item) 1)
      (test-case "first-nested" (check-equal? (item) 2))
      (test-case "second-nested" (check-equal? (item) 3))
      (check-equal? (item) 1))
    (define expected-log
      '((alloc 1) (alloc 2) (dealloc 2) (alloc 3) (dealloc 3) (dealloc 1)))
    (check-equal? (log) expected-log))
  (test-case "test-begin/fixture #:as"
    (test-begin/fixture
      #:fixture (fixture (disposable-pure 'foo)) #:as foo
      (check-equal? (foo) 'foo)))
  (test-case "test-begin/fixture multiple"
    (define foo-fix (fixture (disposable-pure 'foo)))
    (test-begin/fixture
      #:fixture foo-fix
      #:fixture (fixture (disposable-pure 'bar)) #:as bar-fix
      (check-equal? (foo-fix) 'foo)
      (check-equal? (bar-fix) 'bar)))
  (define foo-fix (fixture (disposable-pure 'foo)))
  (test-case/fixture "test-case/fixture"
    #:fixture foo-fix
    #:fixture (fixture (disposable-pure 'bar)) #:as bar-fix
    (check-equal? (foo-fix) 'foo)
    (check-equal? (bar-fix) 'bar)
    (check-equal? (current-test-name) "test-case/fixture")))

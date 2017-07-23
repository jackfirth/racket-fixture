#lang racket/base

(require racket/contract/base)

(provide
 with-test-fixture
 test-begin/fixture
 test-case/fixture
 (contract-out
  [fixture (-> disposable? fixture?)]
  [fixture? predicate/c]
  [call/fixture (-> fixture? (-> any) any)]
  [call/test-fixture (-> fixture? (-> any) any)]))

(require (for-syntax racket/base)
         disposable
         disposable/file
         disposable/testing
         fancy-app
         racket/function
         racket/promise
         rackunit
         syntax/parse/define)


(struct fixture (disp param)
  #:constructor-name make-fixture
  #:omit-define-syntaxes
  #:property prop:procedure (λ (self) ((fixture-param self))))

(define fixture (make-fixture _ (make-parameter #f)))
(define testdir (fixture (disposable-file)))

(define (call/fixture fix thnk)
  (with-disposable ([v (fixture-disp fix)])
    (parameterize ([(fixture-param fix) v]) (thnk))))

(define (call/test-fixture fix thnk)
  (define old-around (current-test-case-around))
  (define (fixture-around test-thnk)
    (old-around (thunk (call/fixture fix test-thnk))))
  (parameterize ([current-test-case-around fixture-around]) (thnk)))

(define-simple-macro (with-test-fixture fix:expr body:expr ...+)
  (call/test-fixture fix (thunk body ...)))

(begin-for-syntax
  (define-splicing-syntax-class fixture-clause
    #:attributes ([unsplice 1] expr id)
    (pattern (~seq #:fixture expr:expr #:as id:id)
             #:attr [unsplice 1] (syntax->list #'(#:fixture expr #:as id)))
    (pattern (~seq #:fixture id:id)
             #:with expr #'id
             #:attr [unsplice 1] (syntax->list #'(#:fixture id)))))

(define-syntax-parser test-case/fixture
  [(_ name:str (~seq fixture:fixture-clause rest:fixture-clause ...)
      body:expr ...+)
   #'(let ([fixture.id fixture.expr])
       (with-test-fixture fixture.id
         (test-case/fixture name rest.unsplice ... ... body ...)))]
  [(_ name:str body:expr ...+) #'(test-case name body ...)])

(define-syntax-parser test-begin/fixture
  [(_ (~seq fixture:fixture-clause rest:fixture-clause ...) body:expr ...+)
   #'(let ([fixture.id fixture.expr])
       (with-test-fixture fixture.id
         (test-begin/fixture rest.unsplice ... ... body ...)))]
  [(_ body:expr ...+) #'(test-begin body ...)])

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

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

(require (for-syntax racket/base
                     "private/syntax.rkt")
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

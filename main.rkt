#lang racket/base

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
    (parameterize ([(fixture-param fix) v])
      (thnk))))

(define (call/test-fixture fix thnk)
  (parameterize ([current-test-case-around (call/fixture fix _)]) (thnk)))

(define-syntax-parser with-fixtures
  [(_ (fix:expr rest:expr ...) body ...+)
   #'(call/test-fixture fix (thunk (with-fixtures (rest ...) body ...)))]
  [(_ () body ...+) #'(let () body ...)])

(define seqlease
  (acquire-global
   (disposable-pool (sequence->disposable '(1 2 3 4 5)) #:max 5)))

(define item (fixture seqlease))

(with-fixtures (item)
  (test-case "outer"
    (displayln (item))
    (displayln (test-case "blah" (item)))
    (displayln (test-case "bloo" (item)))
    (displayln (item))))

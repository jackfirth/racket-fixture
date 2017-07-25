#lang racket/base

(require racket/contract/base)

(provide
 define-fixture
 (contract-out
  [fixture (-> symbol? disposable? fixture?)]
  [fixture? predicate/c]
  [call/fixture (-> fixture? (-> any) any)]))

(require disposable
         racket/function
         syntax/parse/define)


(struct fixture (name disp param)
  #:constructor-name make-fixture
  #:omit-define-syntaxes
  #:property prop:procedure (λ (self) ((fixture-param self))))

(define (fixture name disp) (make-fixture name disp (make-parameter #f)))

(define-simple-macro (define-fixture id:id disp:expr)
  (define id (fixture 'id disp)))

(define (call/fixture fix thnk)
  (with-disposable ([v (fixture-disp fix)])
    (parameterize ([(fixture-param fix) v]) (thnk))))

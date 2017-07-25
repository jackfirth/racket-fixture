#lang racket/base

(require racket/contract/base)

(provide
 (contract-out
  [fixture (-> disposable? fixture?)]
  [fixture? predicate/c]
  [call/fixture (-> fixture? (-> any) any)]))

(require disposable
         racket/function)


(struct fixture (disp param)
  #:constructor-name make-fixture
  #:omit-define-syntaxes
  #:property prop:procedure (λ (self) ((fixture-param self))))

(define (fixture disp) (make-fixture disp (make-parameter #f)))

(define (call/fixture fix thnk)
  (with-disposable ([v (fixture-disp fix)])
    (parameterize ([(fixture-param fix) v]) (thnk))))

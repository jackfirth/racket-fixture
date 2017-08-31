#lang racket/base

(require racket/contract/base)

(provide
 define-fixture
 (contract-out
  [fixture (->* (symbol? disposable?)
                (#:info-proc (-> any/c any/c))
                fixture?)]
  [fixture? predicate/c]
  [fixture-name (-> fixture? symbol?)]
  [fixture-info (-> fixture? any/c)]
  [call/fixture (-> fixture? (-> any) any)]))

(require (for-syntax racket/base)
         disposable
         racket/function
         syntax/parse/define)


(struct fixture (name disp info-proc param)
  #:constructor-name make-fixture
  #:omit-define-syntaxes
  #:property prop:procedure (λ (self) ((fixture-param self))))

(define (fixture name disp #:info-proc [info-proc values])
  (make-fixture name disp info-proc (make-parameter #f)))

(define (fixture-info fix) ((fixture-info-proc fix) (fix)))

(define-simple-macro
  (define-fixture id:id disp
    (~optional (~seq #:info-proc info-proc) #:defaults ([info-proc.c #'values])))
  #:declare disp (expr/c #'disposable? #:name "disposable argument")
  #:declare info-proc (expr/c #'(-> any/c any/c) #:name "info-proc argument")
  (define id (fixture 'id disp.c #:info-proc info-proc.c)))

(define (call/fixture fix thnk)
  (with-disposable ([v (fixture-disp fix)])
    (parameterize ([(fixture-param fix) v]) (thnk))))

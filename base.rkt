#lang racket/base

(require racket/contract/base)

(provide
 define-fixture
 (contract-out
  [fixture (->* (symbol? disposable?)
                (#:info-proc (-> any/c any/c))
                fixture?)]
  [fixture? predicate/c]
  [fixture-value (-> fixture? any/c)]
  [fixture-name (-> fixture? symbol?)]
  [fixture-info (-> fixture? any/c)]
  [call/fixture (-> fixture? (-> any) any)]))

(require (for-syntax racket/base
                     racket/syntax)
         disposable
         syntax/parse/define)


(struct fixture (name disp info-proc param)
  #:constructor-name make-fixture
  #:omit-define-syntaxes)

(define (fixture-value fix) ((fixture-param fix)))

(define (fixture name disp #:info-proc [info-proc values])
  (make-fixture name disp info-proc (make-parameter #f)))

(define (fixture-info fix) ((fixture-info-proc fix) (fixture-value fix)))

(begin-for-syntax
  (define (format-accessor id-stx)
    (format-id id-stx "current-~a" (syntax-e id-stx) #:source id-stx)))

(define-simple-macro
  (define-fixture id:id disp
    (~alt (~optional (~seq #:info-proc info-proc)
                     #:defaults ([info-proc.c #'values]))
          (~optional (~seq #:accessor-name accessor-id)
                     #:defaults ([accessor-id (format-accessor #'id)])))
    ...)
  #:declare disp (expr/c #'disposable? #:name "disposable argument")
  #:declare info-proc (expr/c #'(-> any/c any/c) #:name "info-proc argument")
  (begin
    (define id (fixture 'id disp.c #:info-proc info-proc.c))
    (define (accessor-id) (fixture-value id))))

(define (call/fixture fix thnk)
  (with-disposable ([v (fixture-disp fix)])
    (parameterize ([(fixture-param fix) v]) (thnk))))

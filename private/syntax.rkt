#lang racket/base

(provide fixture-clause)

(require syntax/parse)


(define-splicing-syntax-class fixture-clause
  #:attributes ([unsplice 1] id)
  (pattern (~seq #:fixture id:id)
           #:attr [unsplice 1] (syntax->list #'(#:fixture id))))

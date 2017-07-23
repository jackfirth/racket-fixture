#lang racket/base

(provide fixture-clause)

(require syntax/parse)


(define-splicing-syntax-class fixture-clause
  #:attributes ([unsplice 1] expr id)
  (pattern (~seq #:fixture expr:expr #:as id:id)
           #:attr [unsplice 1] (syntax->list #'(#:fixture expr #:as id)))
  (pattern (~seq #:fixture id:id)
           #:with expr #'id
           #:attr [unsplice 1] (syntax->list #'(#:fixture id))))

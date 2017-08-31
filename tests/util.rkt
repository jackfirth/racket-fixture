#lang racket/base

(provide def->thunk)

(require racket/function)

(define-syntax-rule (def->thunk def) (thunk def (void)))

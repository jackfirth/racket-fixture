# racket-fixture [![Build Status](https://travis-ci.org/jackfirth/racket-fixture.svg?branch=master)](https://travis-ci.org/jackfirth/racket-fixture) [![codecov](https://codecov.io/gh/jackfirth/racket-fixture/branch/master/graph/badge.svg)](https://codecov.io/gh/jackfirth/racket-fixture)
An experimental Racket library providing *test fixtures*, resources that are automatically created and destroyed for each RackUnit test case.

```racket
(define-fixture tmpdir (disposable-directory))
(define-fixture tmpfile (disposable-file))

(test-case/fixture "tests"
  #:fixture tmpdir
  #:fixture tmpfile
  (test-case "some-test"
    ... use tmpdir and tmpfile ...)
  (test-case "other-test"
    ... use different tmpdir and tmpfile ...))
```

Available from the [Racket package catalog](https://pkgd.racket-lang.org/pkgn/package/fixture). To install:

```bash
raco pkg install fixture
```

# racket-fixture
An experimental Racket library providing fixtures, test-case-specific disposables with automatic setup and teardown

```racket
(test-case/fixture "tests"
  #:fixture (directory-fixture) #:as tmpdir
  #:fixture (file-fixture #:parent-dir (tmpdir)) #:as tmpfile
  (test-case "some-test"
    ... use tmpdir and tmpfile ...)
  (test-case "other-test"
    ... use a different tmpdir and tmpfile ...))
```

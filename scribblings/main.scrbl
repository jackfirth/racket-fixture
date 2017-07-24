#lang scribble/manual
@(require "base.rkt")

@(define source-url "https://github.com/jackfirth/racket-fixture")
@(define license-url
   "https://github.com/jackfirth/racket-fixture/blob/master/LICENSE")

@title{Test Fixtures for RackUnit}
@defmodule[fixture]
@author[@author+email["Jack Firth" "jackhfirth@gmail.com"]]

This library defines @fixture-tech{fixtures}, resources used in test cases that
are automatically created and destroyed at the beginning and end of each test
case. Fixtures are built on top of @racketmodname[rackunit] test cases and the
@racketmodname[disposable] library; familiarity with the two is assumed in this
document.

@(racketblock
  (test-case/fixture "tests"
    #:fixture (directory-fixture) #:as tmpdir
    #:fixture (file-fixture #:parent-dir (tmpdir)) #:as tmpfile
    (test-case "some-test"
      ... use tmpdir and tmpfile ...)
    (test-case "other-test"
      ... use a different tmpdir and tmpfile ...)))

Source code for this library is available @hyperlink[source-url]{on Github} and
is provided under the terms of the @hyperlink[license-url]{Apache License 2.0}.

@bold{Warning!} This library is @emph{experimental}; it may change in backwards
incompatible ways without notice. As such, now is the best time for feedback and
suggestions so feel free to open a repository issue or reach out to me directly.

@section{Overview of Collections and Modules}

This package provides several modules, all in the @racketmodname[fixture]
collection:

@itemlist[
 @item{@racketmodname[fixture] - Everything and the kitchen sink.}
 @item{@racketmodname[fixture/base] - Base definitions of
  @fixture-tech{fixtures} and all testing framework agnostic forms.}
 @item{@racketmodname[fixture/rackunit] - Tools for using fixtures with
  @racketmodname[rackunit].}]

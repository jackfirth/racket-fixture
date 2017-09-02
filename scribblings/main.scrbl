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
  (define-fixture tmpdir (disposable-directory))
  (define-fixture tmpfile (disposable-file))

  (test-case/fixture "tests"
    #:fixture tmpdir
    #:fixture tmpfile
    (test-case "some-test"
      ... use (current-tmpdir) and (current-tmpfile) ...)
    (test-case "other-test"
      ... use different (current-tmpdir) and (current-tmpfile) ...)))

Source code for this library is available @hyperlink[source-url]{on Github} and
is provided under the terms of the @hyperlink[license-url]{Apache License 2.0}.

@bold{Warning!} This library is @emph{experimental}; it may change in backwards
incompatible ways without notice. As such, now is the best time for feedback and
suggestions so feel free to open a repository issue or reach out to me directly.

@section{Overview of Collections and Modules}

This package provides several modules, all in the @racketmodname[fixture]
collection:

@itemlist[
 @item{@racketmodname[fixture] - Re-provides the exports of
  @racketmodname[fixture/base] and @racketmodname[fixture/rackunit].}
 @item{@racketmodname[fixture/base] - Base definitions of
  @fixture-tech{fixtures} and all testing framework agnostic forms.}
 @item{@racketmodname[fixture/rackunit] - Tools for using fixtures with
  @racketmodname[rackunit].}]

@section{Data Model}
@defmodule[fixture/base #:no-declare]
@declare-exporting[fixture/base fixture]

A @fixture-tech[#:definition? #t]{fixture} is an external resource that must be
properly initialized and disposed of for a test. Fixtures are essentially a pair
of a @disposable-tech{disposable} defining the external resource and a
@parameter-tech{parameter} that is set for each test to an instance of the
disposable.

Additionally, fixtures may have @info-tech[#:definition? #t]{fixture info};
custom metadata about the current value of the fixture that can be used in test
failure messages. Each fixture defines what info values it provides and there
are no restrictions on the kind of values a fixture may use for info, although
it's expected that calling @racket[write] on them produces something relatively
useful.

@defproc[(fixture? [v any/c]) boolean?]{
 Returns @racket[#t] if @racket[v] is a @fixture-tech{fixture}, returns
 @racket[#f] otherwise.}

@defproc[(fixture [name symbol?]
                  [disp disposable?]
                  [#:info-proc info-proc (-> any/c any/c) values])
         fixture?]{
 Returns a @fixture-tech{fixture} named @racket[name] that provides instances of
 values created with @racket[disp]. The @racket[info-proc] defines the fixture's
 @info-tech{info}, and is called with the current value of the fixture to when
 @racket[fixture-info] is called.

 @(fixture-examples
   (define (example-info n) (format "example value of ~v" n))
   (define ex
     (fixture 'ex example-disposable #:info-proc example-info))
   (fixture-value ex)
   (call/fixture ex
     (thunk
      (displayln (fixture-value ex))
      (displayln (fixture-info ex)))))}

@defform[(define-fixture id disposable-expr fixture-option ...)
         #:grammar ([fixture-option
                     (code:line #:accessor-id accessor-id)
                     (code:line #:info-proc info-proc-expr)])
         #:contracts ([disposable-expr disposable?]
                      [info-proc-expr (-> any/c any/c)])]{
 Binds @racket[id] to a @fixture-tech{fixture} with name @racket['id],
 with @disposable-tech{disposable} @racket[disposable-expr], and with its
 @info-tech{fixture info} defined by @racket[info-proc-expr]. Additionally,
 binds @racket[accessor-id] to a shorthand function that call
 @racket[fixture-value] on @racket[id]. If @racket[accessor-id] is not
 provided, it defaults to @racket[current-]@racket[id]. Each
 @racket[fixture-option] may only be provided once.

 @(fixture-examples
   (define (example-info n) (format "example value of ~v" n))
   (define-fixture ex example-disposable #:info-proc example-info)
   (current-ex)
   (call/fixture ex
     (thunk
      (displayln (current-ex))
      (displayln (fixture-info ex)))))}

@defproc[(fixture-value [fix fixture?]) any/c]{
 Returns the current value of @racket[fix], or @racket[#f] if the fixture has
 not been initialized.}

@defproc[(call/fixture [fix fixture?] [proc (-> any)]) any]{
 Initializes @racket[fix] to a new instance of the fixture's disposable within
 the body of @racket[proc], disposing of the instance of the fixture after
 calling @racket[proc]. Returns whatever values are returned by @racket[proc].

 @(fixture-examples
   (define-fixture ex example-disposable)
   (current-ex)
   (call/fixture ex (thunk (* (current-ex) (current-ex)))))}

@defproc[(fixture-name [fix fixture?]) symbol?]{
 Returns the name of @racket[fix].}

@defproc[(fixture-info [fix fixture?]) any/c]{
 Returns @racket[fix]'s current @info-tech{fixture info} by applying
 @racket[fix]'s fixture info procedure to the current value of the fixture.

 @(fixture-examples
   (struct example-info (value) #:transparent)
   (define-fixture ex example-disposable #:info-proc example-info)
   (call/fixture ex (thunk (fixture-info ex))))}

@section{RackUnit Integration}
@defmodule[fixture/rackunit #:no-declare]
@declare-exporting[fixture/rackunit fixture]

@defform[(test-begin/fixture fixture-clause ... body ...+)
         #:grammar ([fixture-clause (code:line #:fixture fixture-id)])
         #:contracts ([fixture-id fixture?])]{
 Like @racket[test-begin], but with support for @fixture-tech{fixtures}. Within
 the given @racket[body] forms, @racket[current-test-case-around] is
 parameterized to a function that wraps the test in a @racket[call/fixture]
 expression once for each @racket[fixture-id]. Every test found in the
 @racket[body] forms, including the outer @racket[test-begin], is allocated its
 own instance of each fixture. Fixtures are allocated in order from top to
 bottom and deallocated in reverse.

 @(fixture-examples
   (define-fixture ex1 example-disposable)
   (define-fixture ex2 example-disposable)
   (define (ex-sum) (+ (current-ex1) (current-ex2)))
   (test-begin/fixture
     #:fixture ex1
     #:fixture ex2
     (displayln (ex-sum))
     (test-case "nested" (displayln (ex-sum)))))

 Additionally, test failures are augmented with a @racket[check-info] with the
 name @racket['fixtures]. The info's value is a @racket[nested-info] containing
 one check info for each fixture used; that info's name and value correspond to
 the fixture's name and its @info-tech{fixture info} at the time the test
 failure occurred.

 @(fixture-examples
   (define-fixture file1 (disposable-file))
   (define-fixture file2 (disposable-file))
   (test-begin/fixture
     #:fixture file1
     #:fixture file2
     (check-equal? 1 2)))}

@defform[(test-case/fixture name fixture-clause ... body ...+)
         #:grammar ([name string-literal]
                    [fixture-clause (code:line #:fixture fixture-id)])
         #:contracts ([fixture-id fixture?])]{
 Like @racket[test-begin/fixture], but for @racket[test-case] instead of
 @racket[test-begin].}

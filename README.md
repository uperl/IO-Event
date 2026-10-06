# IO::Event ![static](https://github.com/uperl/IO-Event/workflows/static/badge.svg) ![linux](https://github.com/uperl/IO-Event/workflows/linux/badge.svg)

Tied Filehandles for Nonblocking IO with Object Callbacks

# SYNOPSIS

```perl
use IO::Event;
use IO::Event 'emulate_Event';
use IO::Event 'AnyEvent';

my $ioe = IO::Event->new($filehandle);

my $ioe = IO::Event::Socket::INET->new( [ARGS] )

my $ioe = IO::Event::Socket::UNIX->new( [ARGS] )

my $timer = IO::Event->timer(
   [after => $seconds],
   interval => $seconds,
   cb => CODE);

my $idler = IO::Event->idle(
   [min => $seconds], 
   [max => $seconds],
   [reentrant => 0],
   cb => CODE);

IO::Event::loop();

IO::Event::unloop_all();
```

# DESCRIPTION

IO::Event provides a object-based callback system for
handling nonblocking IO.  The design goal is to provide a
system that just does the right thing w/o the user needing
to think about it much.

All APIs are kept as simple as possible yet at the same time,
all functionality is accessible if needed.  Simple things are
easy.  Hard things are possible.

Most of the time file handling syntax will work fine:
`<$filehandle>` and `print $filehandle 'stuff'`.

IO::Event provides automatic buffering of output (with a 
callback to throttle).  It provides automatic line-at-a-time
input.

After initial setup, call `IO::Event::loop()`.  

IO::Event was originally written to use [Event](https://metacpan.org/pod/Event).  IO::Event still 
defaults to using [Event](https://metacpan.org/pod/Event) but it can now use [AnyEvent](https://metacpan.org/pod/AnyEvent) or its
own event loop.

# CHOOSING AN EVENT HANDLER

Until you create your first IO::Event object, you can choose
which underlying event handler to use.  The default is [Event](https://metacpan.org/pod/Event).
To choose an event handler, use one of the following lines,
import `no_emulate_Event`, `emulate_Event`, or `AnyEvent`.

```perl
use IO::Event 'no_emulate_Event'
use IO::Event 'emulate_Event'
use IO::Event 'AnyEvent'
```

The `no_emulate_Event` option means: use [Event](https://metacpan.org/pod/Event).  The `emulate_Event`
option means IO::Event should use its own event loop.

Why?

You should use [AnyEvent](https://metacpan.org/pod/AnyEvent) if you want to have compatibility with
other event loops.  You should use `emulate_Event` if you don't
need compatibility with other event loops and you have missing-event
bugs when using [Event](https://metacpan.org/pod/Event).  You should use [Event](https://metacpan.org/pod/Event) if it works for you.

The APIs are a bit different depending on which event loop you're using.

## [Event](https://metacpan.org/pod/Event)

To use [Event](https://metacpan.org/pod/Event)'s event loop:

```perl
use IO::Event 'no_emulate_Event';
```

or just:

```perl
use IO::Event
```

IO::Event's definition for `loop()`, `timer()`, `idle()` and 
`unloop_all()` all default to the [Event](https://metacpan.org/pod/Event) version unless
`emulate_Event` or `AnyEvent` have been imported.  This allows you to
easily switch back and forth between [Event](https://metacpan.org/pod/Event)'s API and
the others.

## [AnyEvent](https://metacpan.org/pod/AnyEvent)

To use [AnyEvent](https://metacpan.org/pod/AnyEvent)'s select loop, import `AnyEvent`.

```perl
use IO::Event 'AnyEvent';
```

You can use [AnyEvent](https://metacpan.org/pod/AnyEvent)'s API directly or you can use IO::Event's 
emulated APIs: `IO::Event::loop()`, `IO::Event::unloop()`, `IO::Event::timer()`,
and `IO::Event::idle()`.  These behave like [Event](https://metacpan.org/pod/Event)'s routines of the
same name but use [AnyEvent](https://metacpan.org/pod/AnyEvent) underneath.

During testing, using the pure-perl event loop of [AnyEvent::Impl::Perl](https://metacpan.org/pod/AnyEvent::Impl::Perl) from
[AnyEvent](https://metacpan.org/pod/AnyEvent) version 5.271, some read events were dropped.  To work around this, a synthetic 
read-ready event is dispatched for all connected read filehandles every two
seconds.  Turn this off or adjust its frequency by changing 
`$IO::Event::AnyEvent::lost_event_hack`.  A numeric value is the time (in seconds)
between dispatching read events.  A false value turns off this performance-sapping hack.

[AnyEvent](https://metacpan.org/pod/AnyEvent) only provides basic support for idle() events: it promises to invoke
them "every now and then".

## `emulate_Event`

To use IO::Event's own select loop, import `emulate_Event`.

```perl
use IO::Event 'emulate_Event';
```

IO::Event does not provide a complete emulation of everything that
[Event](https://metacpan.org/pod/Event) does.  It provides the full timer API: 

```perl
my $timer = IO::Event::timer( [ARGS] )
```

instead of

```perl
my $timer = Event::timer( [ARGS] )
```

However it does not provide timer events on filehandles, nor does
it provide events for signals, or variable accesses.

Use `IO::Event::loop()` instead of `Event::loop()`.   Use 
`IO::Event::unloop_all()` instead of `Event::unloop_all()`.
Use `IO::Event::idle()` instead of `Event::idle()`.
It does not provide any other methods or functions from
[Event](https://metacpan.org/pod/Event).   If you need them, please send a patch.

# CONSTRUCTORS

- IO::Event->new($filehandle, \[ $handler, \[ $options \]\])

    The basic `new` constructor takes a filehandle and returns
    a pseudo-filehandle.  Treat the IO::Event object as
    a filehandle.  Do not use the original filehandle without
    good reason (let us know if you find a good reason so we
    can fix the problem).

    The handler is the class or object where you provide callback
    functions to handle IO events.  It defaults to the package
    of the calling context. 

    If present, `$options` is a hash reference with the following
    possible keys:

    - description

        A text description of this filehandle.  Used for debugging and
        error messages.

    - read\_only

        Set to true if this is a read-only filehandle.  Do not accept output.

    - write\_only

        Set to true if this is a write-only filehandle.  Do not attempt to read.

    - autoread

        Set to 0 if this should not be an auto-read filehandle.

- IO::Event::Socket::INET->new( \[ARGS\] )

    This constructor uses IO::Socket::INET->new() to create a 
    socket using the ARGS provided.  It returns an 
    IO::Event object.

    The handler defaults as above or can be set with an
    additional pseudo-parameter for IO::Socket::UNIX->new(): 
    `Handler`.  A description for the socket can be provided
    with an additional pseudo-parameter: `Description`.

- IO::Event::Socket::UNIX->new( \[ARGS\] )

    This constructor uses IO::Socket::UNIX->new() to create a 
    socket using the ARGS provided.  It returns an 
    IO::Event object.

    The handler defaults as above or can be set with an
    additional pseudo-parameter for IO::Socket::UNIX->new(): 
    `Handler`.  A description for the socket can be provided
    with an additional pseudo-parameter: `Description`.

# MANDATORY HANDLERS

These handler methods must be available in the handler
object/class if the situation in which they would be
called arises.

- ie\_input($handler, $ioe, $input\_buffer\_reference)

    Invoked when there is fresh data in the input buffer.  The 
    input can be retrieved via directly reading it from
    `$$input_buffer_reference` or via `read()` from the
    $ioe filehandle, or by using a variety of standard
    methods for getting data: 

    ```
    <$ioe>          like IO::Handle
    $ioe->get()     like Data::LineBuffer
    $ioe->read()        like IO::Handle
    $ioe->sysread()     like IO::Handle
    $ioe->getline()     like IO::Handle
    $ioe->getlines()    like IO::Handle
    $ioe->getsome()     see below
    $ioe->ungets()      like FileHandle::Unget
    ```

    At end-of-file, ie\_input will only be invoked once.  There
    may or may not be data in the input buffer.  

- ie\_connection($handler, $ioe)

    Invoked when a listen()ing socket is ready to accept().
    It should call accept:

    ```perl
    sub ie_connection
    {
        my ($pkg, $ioe) = @_;
        my $newfh = $ioe->accept()
    }
    ```

- ie\_read\_ready($handler, $ioe, $underlying\_file\_handle)

    If autoreading is turned off then this will be invoked.

- ie\_werror($handler, $ioe, $output\_buffer\_reference)

    A write error has occurred when trying to drain the write
    buffer.  Provide an empty subroutine if you don't care.

# OPTIONAL HANDLERS

These handler methods will be called if they are defined
but it is not required that they be defined.

- ie\_eof($handler, $ioe, $input\_buffer\_reference)

    This is invoked when the read-side of the filehandle has
    been closed by its source.  

- ie\_output

    This is invoked when data has just been written to the 
    underlying filehandle.

- ie\_outputdone

    This is invoked when all pending data has just been written
    to the underlying filehandle.

- ie\_connected

    This is invoked when a `connect()` completes.

- ie\_connect\_failed($handler, $ioe, $error\_code)

    This is invoked when a `connect()` fails.  For a timeout,
    the error code will be `ETIMEDOUT`.

- ie\_died($handler, $ioe, $method, $@)

    If another handler calls `die` then ie\_died will be called
    with the IO::Event object, the name of the method just
    invoked, and the die string.  If no ie\_died() callback exists
    then execution will terminate.

- ie\_timer

    This is invoked for timer events.  

- ie\_exception

    Invoked when an exceptional condition arises on the 
    underlying filehandle

- ie\_outputoverflow($handler, $ioe, $overflowing, $output\_buffer\_reference)

    Invoked when there is too much output data and the output buffers
    are overflowing.  You can take some action to generate less output.
    This will be invoked exactly once (with $overflowing == 1) when 
    there is too much data in the buffer and then exactly once again
    (with $overflowing == 0) when there is no longer too much data in the
    buffer.

# METHODS

In addition to methods described in detail below, the following
methods behave like their `IO` (mostly `IO::Socket`) counterparts
(except for being mostly non-blocking...):

```
connect
listen
open
read
sysread
syswrite
print
eof
shutdown
```

Through AUTOLOAD (see the SUBSTITUTED METHODS section) methods 
are passed to underlying `Event` objects:

```
loop
unloop
and many more...
```

Through AUTOLOAD (see the SUBSTITUTED METHODS section) methods 
are passed to underlying `IO` objects:

```
fileno
stat
truncate
error
opened
untaint
and many more...
```

IO::Event defines its own methods too:

- ->accept($handler, %options)

    accept() is nearly identical to the normal IO::Socket::accept()
    method except that instead of optionally passing a class
    specifier for the new socket, you optionally pass a 
    handler object or class.   The returned filehandle is an
    IO::Event object.

    Supported options:

    - description

        Sets the description for the new socket

    - autoread

        Set to 0 if you do not want auto-read

- ->can\_read($amount)

    Returns true if `$amount` bytes worth of input is available for
    reading.  Note: this does not return true at EOF so be careful not
    to hang forever at EOF.

- ->getsome($amount)

    Returns `$amount` bytes worth of input or undef if the request
    can't be filled.  Returns what it can at EOF.

- ->get()

    get() is like getline() except that it pre-chomp()s the
    results and assumes the input\_record\_separator is "\\n".
    This is like get() from [Data::LineBuffer](https://metacpan.org/pod/Data::LineBuffer).

- ->unget()

    Push chomp()ed lines back into the input buffer.
    This is like unget() from [Data::LineBuffer](https://metacpan.org/pod/Data::LineBuffer).

- ->ungetline(), ->xungetc(), ->ungets()

    This is what ungetc() should be: it pushes a string back into
    the input buffer.  This is unlike IO::Handle->ungetc which
    takes an ordinal and pushes one character back into the 
    the input buffer.  This is like [FileHandle::Unget](https://metacpan.org/pod/FileHandle::Unget).

- ->handler($new\_handler)

    Sets the handler object/class if $new\_handler is provided.
    Returns the old handler.

- ->filehandle()

    Returns the underlying `IO::Handle`.

- ->event()

    Returns the underling `Event`.

- ->listener($listening)

    Used to note that a filehandle is being used to listen
    for connections (instead of receiving data).  A passed
    parameter of 0 does the opposite.  Returns the old value.
    This is mostly used internally in IO::Event.

- ->input\_record\_separator($new\_sep)

    IO::Handle doesn't allow input\_record\_separator's on a per filehandle
    basis.  IO::Event does.  If you don't ever set a filehandle's input
    record separator, then it continuously defaults to the current value
    of `$/`.  If you set it, then it will use your value and never
    look at `$/` again.

- ->readevents($readevents)

    Get/set listening for read-ready events on the underlying
    filehandle.  This could be used by ie\_outputoverflow to
    control input flows.  

- ->output\_bufsize($output\_bufsize)

    Get/set the size of the output buffer.

- ->autoread($autoread)

    Get/set automatic reading if data when data can be read.
    Without autoread turned on, the input buffer isn't filled
    and none of the read methods will work.  The point of this
    is for working with non-data filehandles.  This is an
    experts-only method that kinda defeats the purpose of
    this module.  This would be necessary using recv() to get
    data.

- ->drain()

    Used to start looking for write-ready events on the underlying
    filehandle.  In normal operation this is handled automatically.
    Deprecated: use `writeevents(1)` instead.

- ->reentrant($reentrant)

    Get/set reentrant callbacks.  By default, IO::Event avoids making
    reentrant callbacks.  This is good because your code is less likely
    to break.  This is bad because you won't learn about things right away.
    For example, you will not learn the the output buffer is overflowing
    during print().  You'll have to wait for the output buffer to begin
    draining to find out.  This could be a problem.

- ->close()

    If there is output buffered, close will be delayed until the output
    buffer drains.

- ->forceclose

    Close close immediately, even if there is output buffered.

- ->ie\_desc(\[new description\])

    Returns (and sets) the text description of the filehandle.  For debugging.

# EVENT LOOP FUNCTIONS

These dispatch to whichever event handler was chosen (see
["CHOOSING AN EVENT HANDLER"](#choosing-an-event-handler)).

- IO::Event::loop()

    Run the event loop.

- IO::Event::unloop()

    Exit the current event loop.

- IO::Event::unloop\_all()

    Exit all running event loops.

- IO::Event->timer( \[ARGS\] )

    Create a timer.  See ["TIMER API"](#timer-api) for the arguments.

- IO::Event->idle( \[ARGS\] )

    Create an idle event.  See ["IDLE API"](#idle-api) for the arguments.

# TIMER API

The following timer construction arguments are supported by IO::Event's
emulated event loop and IO::Event's API on top of [AnyEvent](https://metacpan.org/pod/AnyEvent):

- cb

    A callback to invoke when the timer goes off.  The callback can either be
    a CODE reference or an array reference.  If it's an array reference, the
    array should be a two element tuple: the first element is an object and the
    second object is a method to invoke on the object.  The only argument to
    the method call a reference to the timer object:

    ```perl
    my ($object, $method) = @{$timer->{cb}}
    $object->$method($timer)
    ```

- at

    A time at which to invoke the callback.

- interval

    An interval, in seconds between repeat invocations of the callback.

- after

    The interval until the first invocation of the callback.  After that,
    invoke every _interval_.

The following methods (from [Event](https://metacpan.org/pod/Event)) are supported on timer objects:
start(), again(), now(), stop(), cancel(), is\_cancelled(), is\_running(),
is\_suspended(), pending.

# IDLE API

The following idle construction arguments are supported by IO::Event's
emulated event loop and IO::Event's API on top of [AnyEvent](https://metacpan.org/pod/AnyEvent):

- cb

    A callback to invoke when the event loop is idle.  The callback can either be
    a CODE reference or an array reference.  If it's an array reference, the
    array should be a two element tuple: the first element is an object and the
    second object is a method to invoke on the object.  

    ```perl
    my ($object, $method) = @{$timer->{cb}}
    $object->$method();
    ```

- min

    The minimum time between invocations of the callback.

- max

    The maximum time between invocations of the callback.

The following methods (from [Event](https://metacpan.org/pod/Event)) are supported on idle objects:
start(), again(), now(), stop(), cancel(), is\_cancelled(), is\_running(),
is\_suspended(), pending.

# SUBSTITUTED METHODS

Any method invocations that fail because the method isn't defined
in IO::Event will by tried twice more: once using trying for a
method on the inner (hidden) filehandle and once more trying 
for a method on the Event object that's used to create the select
loop for this module.

This dispatch is now deprecated with the choice of event handlers.

# EXAMPLE SERVER

```perl
# This is a tcp line echo server

my $listener = IO::Event::Socket::INET->new(
    Listen => 10,
    Proto => 'tcp',
    LocalPort => 2821,
);

Event::loop();

sub ie_connection
{
    my ($pkg, $lstnr) = @_;
    my $client = $lstnr->accept();
    printf "accepted connection from %s:%s\n",
        $client->peerhost, $client->peerport;
}

sub ie_input
{
    my ($pkg, $client, $ibufref) = @_;
    print $client <$client>;
}
```

# SYSREAD and EOF

sysread() is incompatible with eof() because eof() uses
getc().  Most of the time this isn't a problem.  In other words,
some of the time this is a problem: lines go missing.

For this reason, IO::Event never uses sysread().  In fact,
if you ask it to do a sysread() it does a read() for you instead.

On the other hand, at the current time no problems with syswrite
have come to light and IO::Event uses syswrite and never any other
form of write/print etc.

# DESTRUCTION

IO::Event keeps copies of all of its registered filehandles.  If
you want to close a filehandle, you'll need to actually call close
on it.

# DATA STRUCTURE

The filehandle object itself is a funny kind of hash reference.
If you want to use it to store your own data, you can.  Please 
don't use hash keys that begin `ie_` or `io_` as those are the
prefixes used by `IO::Event` and `IO::Socket`.  

The syntax is kinda funny:

```
${*$filehandle}{'your_hash_key'}  
```

# SEE ALSO

For a different API on top of IO::Event, 
see [IO::Event::Callback](https://metacpan.org/pod/IO::Event::Callback).  It uses IO::Event but provides 
a simpler and perhaps easier-to-use API.

The following perl modules do something that is kinda similar
to what is being done here:

[AnyEvent::Handle](https://metacpan.org/pod/AnyEvent::Handle),
[AnyEvent::AIO](https://metacpan.org/pod/AnyEvent::AIO),
[IO::AIO](https://metacpan.org/pod/IO::AIO),
[IO::Multiplex](https://metacpan.org/pod/IO::Multiplex),
[IO::NonBlocking](https://metacpan.org/pod/IO::NonBlocking),
[IO::Select](https://metacpan.org/pod/IO::Select)
[Event](https://metacpan.org/pod/Event),
[POE](https://metacpan.org/pod/POE),
[POE::Component::Server::TCP](https://metacpan.org/pod/POE::Component::Server::TCP),
[Net::Socket::NonBlock](https://metacpan.org/pod/Net::Socket::NonBlock),
[Net::Server::Multiplex](https://metacpan.org/pod/Net::Server::Multiplex),
[NetServer::Generic](https://metacpan.org/pod/NetServer::Generic)

The API borrows most heavily from IO::Multiplex.  IO::Event
uses Event.pm and thus can be used in programs that are already
using Event or POE.

Since the original writing of IO::Event, [AnyEvent](https://metacpan.org/pod/AnyEvent) has been
released and now [AnyEvent::AIO](https://metacpan.org/pod/AnyEvent::AIO) and [AnyEvent:Handle](AnyEvent:Handle) should be
considered the only good alternatives to IO::Event.

For an example program using IO::Event, see [IO::Event::rinetd](https://metacpan.org/pod/IO::Event::rinetd)
which used to be included in this package.

# BUGS

The test suite only covers 40% of the code.  The module is used
by its author and seems solid.

# AUTHORS

- David Muir Sharnoff <cpan@dave.sharnoff.org>
- Graham Ollis <plicease@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2002-2026 by David Muir Sharnoff <muir@idiom.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

# !SLIDE
# Abstracting Services in Ruby
#
# * Kurt Stephens
# * Enova Financial
# * 2012/02/21
# * Slides -- "":http://kurtstephens.com/pub/ruby/abstracting_services_in_ruby/asir.slides/
# * Code -- "":http://kurtstephens.com/pub/ruby/abstracting_services_in_ruby/
# * Git -- "":http://github.com/kstephens/abstracting_services_in_ruby
#
# !SLIDE END

# !SLIDE
# Issues
#
# * Problem Domain, Solution Domain
# * Service Middleware Semantics
# * Testing, Debugging, Diagnostics
# * Productivity
#
# !SLIDE END

# !SLIDE
# Problem Domain, Solution Domain
#
# * Client knows too much about infrastructure.
# * Evaluating and switching infrastructures.
#
# !SLIDE END

# !SLIDE
# Service Middleware Semantics
#
# * Directionality: One-way, Two-way
# * Synchronicity: Synchronous, Asynchronous, Delayed, Buffered
# * Distribution: Local Thread, Local Process, Distributed
# * Transport: File, IPC, Pipe, Network
# * Robustness: Retry, Replay, Fallback
# * Encoding: XML, JSON, YAML, Base64, Compression
#
# !SLIDE END

# !SLIDE
# Testing, Debugging, Diagnostics
#
# * Configuration for testing and QA is more complex.
# * Measuring test coverage of remote services.
# * Debugging the root cause of remote service errors.
# * Diagnostic hooks.
#
# !SLIDE END

# !SLIDE
# Objectives
#
# * Simplify service/client definitions and interfaces.
# * Anticipate new encoding, delivery and security requirements.
# * Separate encoding and transport concerns.
# * Composition over Configuration.
# * Elide deployment decisions.
# * Integrate diagnostics and logging.
# * Simplify testing.
#
# !SLIDE END

# !SLIDE
# Foundations of Objects
#
# * Message
# * State
# * Behavior

# !SLIDE
# Messaging
#
# * "Call a Method", "Call a Function" are all the same, in *all* languages.
# ** Decomposed into lookup() and apply().
# * "Send Message", not "Call a Method".
# * Messaging abstracts:
# ** Object use from its implemenation.
# ** Transfer of control (method, function invocation, RPC, etc).

# !SLIDE
# REST
#
# "Roy Fielding - Architectural Styles and the Design of Network-based Software Architectures":http://www.ics.uci.edu/~fielding/pubs/dissertation/top.htm
#
# * Imperative Action .vs. Behavorial Resource
# * REST Connector .vs. REST Component
# * "Generality of connectors leads to middleware..."
# * "Modifiability is about the ease with which a change can be made to an application architecture... broken down into evolvability, extensibility, customizability, configurability, and reusability..."
#
# !SLIDE END

# !SLIDE
# Design
#
# * Nouns -> Objects -> Classes
# * Verbs -> Responsibilities -> Methods
#
# h3. Book: "Designing Object-Oriented Software"
#  * Wirfs-Brock, Wilkerson, Wiener
#
# !SLIDE END

# !SLIDE
# Design: Nouns
#
# * Service -> Object
# * Client -> Just a Ruby caller.
# * Proxy
# * Message -> Just a Ruby message.
# * Result, Exception (two-way) -> Return value or else.
# * Transport -> (file, pipe, http, queue, ActiveResource)
# * Encoder, Decoder -> Coder (Marshal, XML, JSON, ActiveResource)
#
# !SLIDE END

# !SLIDE
# Design: Verbs
#
# * Intercept Message -> Proxy
# * Invoke Message    -> Message
# * Return Result, Invoke Exception  -> Result
# * Send Message, Recieve Message -> Transport
# * Encode Object, Decode Object -> Coder
#
# !SLIDE END

# !SLIDE
# Simple
#
# !IMAGE BEGIN PIC width:800 height:300
#
# box "Client" "(CustomersController" "#send_invoice)" wid 4.0 ht 2.5; arrow;
# ellipse "Send" "Message" "(Ruby message)" wid 4.0 ht 2.5; arrow;
# box "Service" "(Email.send_email)" wid 4.0 ht 2.5;
#
# !IMAGE END
#
# !SLIDE END

# !SLIDE
# Client-Side Message
#
# !IMAGE BEGIN PIC width:800 height:300
# box "Client" wid 2.5 ht 2.5; arrow;
# ellipse "Proxy" wid 2.5 ht 2.5; arrow;
# ellipse "Create" "Message" wid 2.5 ht 2.5; arrow;
# ellipse "Encode" "Message" wid 2.5 ht 2.5; arrow;
# ellipse "Send" "Message" wid 2.5 ht 2.5;
# line; down; arrow;
# !IMAGE END
#
# !SLIDE END

# !SLIDE
# Server-Side
#
# !IMAGE BEGIN PIC width:800 height:300
# down; line; right; arrow;
# ellipse "Receive" "Message" wid 2.5 ht 2.5; arrow;
# ellipse "Decode" "Message" wid 2.5 ht 2.5; arrow;
# ellipse "Message" wid 2.5 ht 2.5;
# line; down; arrow;
# IR: ellipse "Invoke" "Message" wid 2.5 ht 2.5;
# right; move; move;
# Service: box "Service" wid 2.5 ht 2.5 with .w at IR.e + (movewid, 0);
# arrow <-> from IR.e to Service.w;
# move to IR.s; down; line;
# left; arrow;
# ellipse "Create" "Result" wid 2.5 ht 2.5; arrow;
# ellipse "Encode" "Result" wid 2.5 ht 2.5; arrow;
# ellipse "Send" "Result" wid 2.5 ht 2.5;
# line; down; arrow
# !IMAGE END
#
# !SLIDE END

# !SLIDE
# Client-Side Result
#
# !IMAGE BEGIN PIC width:800 height:300
# down; line; left; arrow;
# ellipse "Receive" "Result" wid 2.5 ht 2.5; arrow;
# ellipse "Decode" "Result" wid 2.5 ht 2.5; arrow;
# ellipse "Result" wid 2.5 ht 2.5; arrow;
# ellipse "Proxy" wid 2.5 ht 2.5; arrow;
# box "Client" wid 2.5 ht 2.5;
# !IMAGE END
#
# !SLIDE END

# !SLIDE
# Implementation
#
# * Primary Base classes: Transport, Coder
# * Primary API: Proxy via Client mixix
# * Handful of mixins.
#
# !SLIDE END

# !SLIDE
# Modules and Classes
module ASIR
  # Reusable constants to avoid unnecessary garbage.
  EMPTY_ARRAY = [ ].freeze; EMPTY_HASH =  { }.freeze; EMPTY_STRING = ''.freeze
  MODULE_SEP = '::'.freeze; IDENTITY_LAMBDA = lambda { | x | x }

end
# !SLIDE END

require 'asir/error'
require 'asir/log'
require 'asir/initialization'
require 'asir/additional_data'
require 'asir/object_resolving'
require 'asir/identity'
require 'asir/code_block'
require 'asir/code_more'
require 'asir/message'
require 'asir/result'
require 'asir/client'
require 'asir/coder'
require 'asir/coder/null'
require 'asir/coder/identity'
require 'asir/transport'
require 'asir/channel'
require 'asir/transport/local'

# !SLIDE
# Synopsis
#
# * Services are easy to abstract away.
# * Separation of transport, encoding.
#
# !SLIDE END

# !SLIDE
# Slide Tools
#
# * Riterate -- "":http://github.com/kstephens/riterate
# * Scarlet -- "":http://github.com/kstephens/scarlet
#
# !SLIDE END

# !SLIDE
# Appendix
#
#
# !SLIDE END


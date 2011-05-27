# !SLIDE
# Abstracting Services in Ruby
#
# * Kurt Stephens
# * Enova Financial
# * 2010/12/03
# * Slides -- "":http://kurtstephens.com/pub/ruby/abstracting_services_in_ruby/asir.slides/
# * Code -- "":http://kurtstephens.com/pub/ruby/abstracting_services_in_ruby/
# * Git -- "":http://github.com/kstephens/abstracting_services_in_ruby
# * Tools 
# ** Riterate -- "":http://github.com/kstephens/riterate
# ** Scarlet -- "":http://github.com/kstephens/scarlet
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
# * Synchronicity: Synchronous, Asynchronous
# * Distribution: Local Process, Local Thread, Distributed
# * Robustness: Retry, Replay, Fallback
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
# * Compose encoding and transport concerns.
# * Elide deployment decisions.
# * Integrate diagnostics and logging.
# * Simplify testing.
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
# * Service -> Module
# * Client -> Just a Ruby caller
# * Proxy
# * Request
# * Response, Exception (two-way)
# * Transport -> (file, pipe, http, queue, ActiveResource)
# * Encoder, Decoder -> Coder (Marshal, XML, JSON, ActiveResource)
# * Logging
#
# !SLIDE END

# !SLIDE
# Design: Verbs
#
# * Intercept Request -> Proxy
# * Invoke Request    -> Request
# * Invoke Exception
# * Send Request, Recieve Request -> Transport
# * Encode Object, Decode Object -> Coder
#
# !SLIDE END

# !SLIDE
# Simple
#
# !PIC BEGIN
# 
# box "Client" "(CustomersController" "#send_invoice)"; arrow; 
# ellipse "Send" "Request" "(Ruby message)"; arrow; 
# box "Service" "(Email.send_email)";
#
# !PIC END
#
# !SLIDE END

# !SLIDE
# Client-Side Request
#
# !PIC BEGIN
# box "Client"; arrow; 
# ellipse "Proxy"; arrow; 
# ellipse "Create" "Request"; arrow; 
# ellipse "Encode" "Request"; arrow; 
# ellipse "Send" "Request";
# line; down; arrow;
# !PIC END
#
# !SLIDE END

# !SLIDE
# Server-Side
#
# !PIC BEGIN
# down; line; right; arrow; 
# ellipse "Receive" "Request"; arrow; 
# ellipse "Decode" "Request"; arrow; 
# ellipse "Request"; 
# line; down; arrow; 
# IR: ellipse "Invoke" "Request";
# right; move; move;
# Service: box "Service" with .w at IR.e + (movewid, 0); 
# arrow <-> from IR.e to Service.w;
# move to IR.s; down; line;
# left; arrow; 
# ellipse "Create" "Response"; arrow; 
# ellipse "Encode" "Response"; arrow;
# ellipse "Send" "Response"; 
# line; down; arrow
# !PIC END
#
# !SLIDE END

# !SLIDE
# Client-Side Response
#
# !PIC BEGIN
# down; line; left; arrow;
# ellipse "Receive" "Response"; arrow; 
# ellipse "Decode" "Response"; arrow; 
# ellipse "Response"; arrow; 
# ellipse "Proxy"; arrow; 
# box "Client";
# !PIC END
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
require 'asir/request'
require 'asir/response'
require 'asir/client'
require 'asir/coder'
require 'asir/transport'
require 'asir/channel'
require 'asir/transport/local'

# !SLIDE
# Synopsis
#
# * Services are easy to abstract away.
# * Separation of transport, encoding.
# * 
#
# !SLIDE END



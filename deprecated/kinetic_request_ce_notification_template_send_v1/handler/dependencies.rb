# Require the necessary core libraries.
require 'java'
require 'rexml/document'

# Determine the path to the handler
handler_path = File.expand_path(File.dirname(__FILE__))

# Require the necessary java libraries
require File.join(handler_path, 'kinetic_request_ce_notification_template_send_handler_helper')
require File.join(handler_path, 'lib', 'smtp.jar')
require File.join(handler_path, 'lib', 'mailapi.jar')
require File.join(handler_path, 'lib', 'commons-email-1.2.jar')

# If we are using a Java prior to 1.6, where the necessary files became included
# in the standard library, manually include the activation.jar.
if java.lang.System.getProperty('java.class.version').to_i < 50
  # Require the activation jar
  require File.join(handler_path, 'lib', 'activation.jar')
# If we are using Java 1.6 or later, implement a JRuby classpath fix for Email
else
  # There is a problem with the JRuby classloading when using Java 6 that
  # prevents the proper Mime mappings from being retrieved.  This is a
  # workaround to fix the classpath used by org.apache.commons.mail.HtmlEmail
  # during send.
  org.apache.commons.mail.HtmlEmail.module_eval do
    # Alias the original 'send' method name to 'send_without_jruby_fix'
    alias_method :send_without_jruby_fix, :send
    # Redefine the send method
    def send()
      # Spawn a new thread so that we are not manipulating the current classloader
      thread = Thread.new do
        begin
          # Overwrite the current classloader
          java.lang.Thread.currentThread().setContextClassLoader(java_class.class_loader)
          # Call the old send method
          Thread.current['kinetic/task/KineticRequestCeNotificationTemplateSendV1/result'] = {"success" => true}
          Thread.current['kinetic/task/KineticRequestCeNotificationTemplateSendV1/result']['id'] = send_without_jruby_fix()
        rescue Exception => e
          Thread.current['kinetic/task/KineticRequestCeNotificationTemplateSendV1/result'] = {"success" => false,"exception" => e}
        end
      end
      # Wait for the thread to complete
      thread.join
      # Return the thread result
      return thread['kinetic/task/KineticRequestCeNotificationTemplateSendV1/result']
    end
  end
end

# If the Kinetic Task version is under 4, load the openssl and json libraries
# because they are not included in the ruby version
if KineticTask::VERSION.split(".").first.to_i < 4
  # Load the JRuby Open SSL library unless it has already been loaded.  This
  # prevents multiple handlers using the same library from causing problems.
  if not defined?(Jopenssl)
    # Load the Bouncy Castle library unless it has already been loaded.  This
    # prevents multiple handlers using the same library from causing problems.
    # Calculate the location of this file
    handler_path = File.expand_path(File.dirname(__FILE__))
    # Calculate the location of our library and add it to the Ruby load path
    library_path = File.join(handler_path, "vendor/bouncy-castle-java-1.5.0147/lib")
    $:.unshift library_path
    # Require the library
    require "bouncy-castle-java"
    
    
    # Calculate the location of this file
    handler_path = File.expand_path(File.dirname(__FILE__))
    # Calculate the location of our library and add it to the Ruby load path
    library_path = File.join(handler_path, "vendor/jruby-openssl-0.8.8/lib/shared")
    $:.unshift library_path
    # Require the library
    require "openssl"
    # Require the version constant
    require "jopenssl/version"
  end

  # Validate the the loaded openssl library is the library that is expected for
  # this handler to execute properly.
  if not defined?(Jopenssl::Version::VERSION)
    raise "The Jopenssl class does not define the expected VERSION constant."
  elsif Jopenssl::Version::VERSION != "0.8.8"
    raise "Incompatible library version #{Jopenssl::Version::VERSION} for Jopenssl.  Expecting version 0.8.8"
  end

  # Load the ruby json library unless 
  # it has already been loaded.  This prevents multiple handlers using the same 
  # library from causing problems.
  if not defined?(JSON)
    # Calculate the location of this file
    handler_path = File.expand_path(File.dirname(__FILE__))
    # Calculate the location of our library and add it to the Ruby load path
    library_path = File.join(handler_path, "vendor/json-1.8.0/lib")
    $:.unshift library_path
    # Require the library
    require "json"
  end

  # Validate the the loaded JSON library is the library that is expected for
  # this handler to execute properly.
  if not defined?(JSON::VERSION)
    raise "The JSON class does not define the expected VERSION constant."
  elsif JSON::VERSION.to_s != "1.8.0"
    raise "Incompatible library version #{JSON::VERSION} for JSON.  Expecting version 1.8.0."
  end
end


# Load the ruby Mime Types library unless it has already been loaded.  This prevents
# multiple handlers using the same library from causing problems.
if not defined?(MIME)
  # Calculate the location of this file
  handler_path = File.expand_path(File.dirname(__FILE__))
  # Calculate the location of our library and add it to the Ruby load path
  library_path = File.join(handler_path, "vendor/mime-types-1.19/lib/")
  $:.unshift library_path
  # Require the library
  require "mime/types"
end

# Validate the the loaded Mime Types library is the library that is expected for
# this handler to execute properly.
if not defined?(MIME::Types::VERSION)
  raise "The Mime class does not define the expected VERSION constant."
elsif MIME::Types::VERSION != "1.19"
  raise "Incompatible library version #{MIME::Types::VERSION} for Mime Types.  Expecting version 1.19."
end


# Load the ruby rest-client library (used by the Octokit library) unless
# it has already been loaded.  This prevents multiple handlers using the same
# library from causing problems.
if not defined?(RestClient)
  # Calculate the location of this file
  handler_path = File.expand_path(File.dirname(__FILE__))
  # Calculate the location of our library and add it to the Ruby load path
  library_path = File.join(handler_path, "vendor/rest-client-1.6.7/lib")
  $:.unshift library_path
  # Require the library
  require "rest-client"
end

# Validate the the loaded rest-client library is the library that is expected for
# this handler to execute properly.
if not defined?(RestClient.version)
  raise "The RestClient class does not define the expected VERSION constant."
elsif RestClient.version.to_s != "1.6.7"
  raise "Incompatible library version #{RestClient.version} for rest-client.  Expecting version 1.6.7."
end

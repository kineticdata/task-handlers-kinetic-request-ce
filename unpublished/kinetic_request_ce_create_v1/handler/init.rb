# Require the dependencies file to load the vendor libraries
require File.expand_path(File.join(File.dirname(__FILE__), "dependencies"))

class KineticRequestCeCreateV1
  def initialize(input)
    # Set the input document attribute
    @input_document = REXML::Document.new(input)
    
    # Retrieve all of the handler info values and store them in a hash variable named @info_values.
    @info_values = {}
    REXML::XPath.each(@input_document, "/handler/infos/info") do |item|
      @info_values[item.attributes["name"]] = item.text.to_s.strip
    end

    # Retrieve all of the handler parameters and store them in a hash variable named @parameters.
    @parameters = {}
    REXML::XPath.each(@input_document, "/handler/parameters/parameter") do |item|
      @parameters[item.attributes["name"]] = item.text.to_s.strip
    end
    
    @enable_debug_logging = @info_values['enable_debug_logging'].downcase == 'yes' ||
                            @info_values['enable_debug_logging'].downcase == 'true'
    puts "Parameters: #{@parameters.inspect}" if @enable_debug_logging
  end

  # The execute method gets called by the task engine when the handler's node is processed. It is
  # responsible for performing whatever action the name indicates.
  # If it returns a result, it will be in a special XML format that the task engine expects. These
  # results will then be available to subsequent tasks in the process.
  def execute
    api_username    = URI.encode(@info_values["api_username"])
    api_password    = @info_values["api_password"]
    api_server      = @info_values["api_server"]
    kapp_slug       = @parameters["kapp"]
    space_slug      = @parameters["space_slug"].empty? ? @info_values["space_slug"] : @parameters["space_slug"]
    
    data   = @parameters["data"]
    error_handling  = @parameters["error_handling"]
    mode = @parameters["mode"]
    api_route = ""
    type   = ""
    case @parameters["type"].downcase
    when "space"
      type   = "space"
    when "bridge"
      type   = "bridges"
    when "form"
      type   = "forms"
    when "bridge model"
      type   = "models"
    when "kapp"
      type   = "kapps"
    when "categories"
      type   = "categories"
    when "team"
      type   = "teams"
    when "form type"
      type   = "formTypes"
    when "user"
      type   = "users"
    when "webhook"
      type   = "webhooks"
    else
      error_message = "The entered type was not valid"
      if error_handling == "Raise Error"
        raise error_message
      else
        <<-RESULTS
        <results>
          <result name="Handler Error Message">The entered type was not valid</result>
        </results>
        RESULTS
      end
    end
    
    
    
    if kapp_slug.nil? || kapp_slug == ''
         puts "No kapp slug, building without" if @enable_debug_logging
        api_route = "#{api_server}/#{space_slug}/app/api/v1/#{type}"
    else 
        api_route = "#{api_server}/#{space_slug}/app/api/v1/kapps/#{kapp_slug}/#{type}"
    end
    

    
    puts "API ROUTE: #{api_route}" if @enable_debug_logging

    resource = RestClient::Resource.new(api_route, { :user => api_username, :password => api_password })

    # Post to the API
    response = resource.post(data, { :accept => "json", :content_type => "json" })
    

    parsedResponse = JSON.parse(response)
 
    puts "parsedResponse: #{parsedResponse}" if @enable_debug_logging
    responseType = type.chomp('s')

    puts "Looking for  #{responseType} in response" if @enable_debug_logging
     
    @values = parsedResponse[responseType]  

    answerSetJSON = @values.to_json
    
    puts "answerSetJSON: #{answerSetJSON}" if @enable_debug_logging
    
    # Build the results to be returned by this handler
    results = "<results><result name='Handler Error Message'></result>
               <result name='Full Response'>#{escape(answerSetJSON)}</result>"
    
    @values.each do |fieldName,answer|
      if answer.kind_of?(Array)
        results += "<result name='#{fieldName}'>#{escape(answer.join(" , "))}</result>"
      else
        results += "<result name='#{fieldName}'>#{escape(answer)}</result>"
      end
    end

    results += "</results>"

	  rescue RestClient::Exception => error
      error_message = JSON.parse(error.response)["error"]
      if error_handling == "Raise Error"
        raise error_message
      else
        <<-RESULTS
        <results>
          <result name="Handler Error Message">#{error.http_code}: #{escape(error_message)}</result>
        </results>
        RESULTS
      end
  end

  ##############################################################################
  # General handler utility functions
  ##############################################################################

  # This is a template method that is used to escape results values (returned in
  # execute) that would cause the XML to be invalid.  This method is not
  # necessary if values do not contain character that have special meaning in
  # XML (&, ", <, and >), however it is a good practice to use it for all return
  # variable results in case the value could include one of those characters in
  # the future.  This method can be copied and reused between handlers.
  def escape(string)
    # Globally replace characters based on the ESCAPE_CHARACTERS constant
    string.to_s.gsub(/[&"><]/) { |special| ESCAPE_CHARACTERS[special] } if string
  end
  # This is a ruby constant that is used by the escape method
  ESCAPE_CHARACTERS = {
    "&" => "&amp;",
    "<" => "&lt;",
    ">" => "&gt;",
    "'" => "&#39;",
    '"' => "&quot;",
    "/" => "&#47;",
    "#" => "&#35;",
    " " => "&nbsp;",
    "\\" => "&#92;",
    "\r" => "<br>",
    "\n" => "<br>"
  }
  
  
      # Builds a string that is formatted specifically for the Kinetic Task log file
  # by concatenating the provided header String with each of the provided hash
  # name/value pairs.  The String format looks like:
  #   HEADER
  #       KEY1: VAL1
  #       KEY2: VAL2
  # For example, given:
  #   field_values = {'Field 1' => "Value 1", 'Field 2' => "Value 2"}
  #   format_hash("Field Values:", field_values)
  # would produce:
  #   Field Values:
  #       Field 1: Value 1
  #       Field 2: Value 2
  def format_hash(header, hash)
    # Staring with the "header" parameter string, concatenate each of the
    # parameter name/value pairs with a prefix intended to better display the
    # results within the Kinetic Task log.
    hash.inject(header) do |result, (key, value)|
      result << "\n    #{key}: #{value}"
    end
  end
  
end

  

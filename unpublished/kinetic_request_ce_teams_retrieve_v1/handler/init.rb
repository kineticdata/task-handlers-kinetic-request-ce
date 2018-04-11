# Require the dependencies file to load the vendor libraries
require File.expand_path(File.join(File.dirname(__FILE__), 'dependencies'))

# Require the REXML ruby library.
require 'rexml/document'

class KineticRequestCeTeamsRetrieveV1
  def initialize(input)
    # Set the input document attribute
    @input_document = REXML::Document.new(input)
	
    # Store the info values in a Hash of info names to values.
    @info_values = {}
    REXML::XPath.each(@input_document,"/handler/infos/info") do |item|
      @info_values[item.attributes['name']] = item.text
    end

    # Retrieve all of the handler parameters and store them in a hash attribute named @parameters.
    @parameters = {}
    REXML::XPath.match(@input_document, '/handler/parameters/parameter').each do |node|
      @parameters[node.attribute('name').value] = node.text.to_s.strip
    end

    @enable_debug_logging = @info_values['enable_debug_logging'].downcase == 'yes' ||
                            @info_values['enable_debug_logging'].downcase == 'true'
    puts "Parameters: #{@parameters.inspect}" if @enable_debug_logging
  end

  def execute
  
    space_slug = @parameters["space_slug"].empty? ? @info_values["space_slug"] : @parameters["space_slug"]
	membership = @parameters["membership"].empty? ? "true" : @parameters["membership"].downcase
	if membership != "true" && membership != "false"
	membership = "true"
	end
	attributes = @parameters["attributes"].empty? ? "true" : @parameters["attributes"].downcase
	if attributes != "true" && attributes != "false"
	attributes = "true"
	end
	
    begin
      # API Route
      route = @info_values['server'] + '/' + space_slug + 
                    '/app/api/v1/teams?include=details'
					
	  if membership == "true"
	    route = route + ',memberships'
	  end
	  if attributes == "true"
	    route = route + ',attributes'
	  end

      puts "API ROUTE: #{route}" if @enable_debug_logging

      resource = RestClient::Resource.new(route,
                                          user: @info_values['username'],
                                          password: @info_values['password'])

      # Request to the API
      response = resource.get
	  
	 #puts "response: #{response}" if @enable_debug_logging

	results = JSON.parse(response)["teams"]

	if !@parameters["team_name"].empty?
		requestedteam = {}
		results.each do |team|
			if team["name"] == @parameters["team_name"]
				requestedteam = team
			end
		end
		results = requestedteam
		if results.empty?
			return <<-RESULTS
			  <results>
				<result name="Teams"></result>
				<result name="Handler Error Message">Unable to find team #{escape(@parameters["team_name"])}</result>
			  </results>
			RESULTS
		end
	end
	puts "results: #{results.to_json}" if @enable_debug_logging
	return <<-RESULTS
          <results>
            <result name="Teams">#{escape(results.to_json)}</result>
            <result name="Handler Error Message"></result>
          </results>
        RESULTS


   rescue RestClient::Exception => error
      #error_message = JSON.parse(error.response)["error"]
	  error_message = response
      if @parameters["error_handling"]  == "Raise Error"
        raise error_message
      else
       return <<-RESULTS
        <results>
		  <result name="Teams"></result>
          <result name="Handler Error Message">#{error.http_code}: #{escape(error_message)}</result>
        </results>
        RESULTS
      end
	
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
  ESCAPE_CHARACTERS = {'&'=>'&amp;', '>'=>'&gt;', '<'=>'&lt;', '"' => '&quot;'}
end
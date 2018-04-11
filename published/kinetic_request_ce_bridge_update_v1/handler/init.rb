# Require the dependencies file to load the vendor libraries
require File.expand_path(File.join(File.dirname(__FILE__), "dependencies"))

class KineticRequestCeBridgeUpdateV1
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

  def execute
    begin
      # Initialize variables
      space_slug = @parameters["space_slug"].empty? ? @info_values["space_slug"] : @parameters["space_slug"]
      error_handling  = @parameters["error_handling"]
      error_message = nil

      api_username    = URI.encode(@info_values["api_username"])
      api_password    = @info_values["api_password"]
      api_server      = @info_values["api_server"]
      original_name   = URI.escape(@parameters["original_bridge_name"])

      raise StandardError, "The original bridge name is required." if original_name.empty?

      api_route = "#{api_server}/#{space_slug}/app/api/v1/bridges/#{original_name}"

      resource = RestClient::Resource.new(api_route, { :user => api_username, :password => api_password })

      # Update the bridge data
      data = {}
      data.tap do |json|
        json[:name]   = @parameters["name"]   unless @parameters["name"].empty?
        json[:url]    = @parameters["url"]    unless @parameters["url"].empty?
        json[:status] = @parameters["status"] unless @parameters["status"].empty?
      end

      # PUT to the API
      response = resource.put(data.to_json, { :accept => "json", :content_type => "json" })

    rescue RestClient::Exception => error
      error_message = "#{error.http_code}: #{JSON.parse(error.response)["error"]}"
      raise error_message if error_handling == "Raise Error"
    rescue Exception => error
      error_message = error.inspect
      raise error if error_handling == "Raise Error"
    end

    return <<-RESULTS
    <results>
      <result name="Handler Error Message">#{escape(error_message)}</result>
    </results>
    RESULTS
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

# Require the dependencies file to load the vendor libraries
require File.expand_path(File.join(File.dirname(__FILE__), 'dependencies'))

# Require the REXML ruby library.
require 'rexml/document'

class KineticRequestCeFormUpdateAttributesV1
  def initialize(input)
    # Set the input document attribute
    @input_document = REXML::Document.new(input)

    # Store the info values in a Hash of info names to values.
    @info_values = {}
    REXML::XPath.each(@input_document,"/handler/infos/info") do |item|
      @info_values[item.attributes["name"]] = item.text.to_s.strip
    end

    # Retrieve all of the handler parameters and store them in a hash attribute named @parameters.
    @parameters = {}
    REXML::XPath.match(@input_document, "/handler/parameters/parameter").each do |item|
      @parameters[item.attributes["name"]] = item.text.to_s.strip
    end

    @enable_debug_logging = @info_values['enable_debug_logging'].downcase == 'yes' ||
                            @info_values['enable_debug_logging'].downcase == 'true'
    puts "Parameters: #{@parameters.inspect}" if @enable_debug_logging
  end

  def execute
    space_slug = @parameters["space_slug"].empty? ? @info_values["space_slug"] : @parameters["space_slug"]
    error_handling  = @parameters["error_handling"]
    error_message = nil

    begin

      # API Route
      type = @parameters["form_slug"].empty? ? "multiple" : "single"
      api_route = @info_values["api_server"] +
                    "/" + space_slug + "/app/api/v1/kapps/" +
                    @parameters["kapp_slug"] + "/forms"

      if type == "multiple"
        api_route = api_route + "?include=attributes"
      else
        api_route = api_route + "/" + @parameters["form_slug"] + "?include=attributes"
      end

      puts "API ROUTE TO GET FORM(s): #{api_route}" if @enable_debug_logging
      resource = RestClient::Resource.new(api_route,
                                          user: @info_values["api_username"],
                                          password: @info_values["api_password"])

      # Do Call to get Form(s)
      response = resource.get({ accept: :json, content_type: :json })
      # Parse the Response
      response = JSON.parse(response)
      # Parse Attributes passed as inputs
      new_attributes = JSON.parse(@parameters["attributes"])
      # Build variable for Forms array
      forms = nil
      if type == "multiple"
        forms = response['forms']
      else
        forms = [response['form']]
      end

      # Loop over Each form and update / create it's attributes
      forms.each do |form|
        # Create a Form Update Route
        form_api_route = @info_values["api_server"] + "/" + space_slug + "/app/api/v1/kapps/" + @parameters["kapp_slug"] + "/forms/" + form["slug"]
        # Set variable with current form attributes
        current_attributes = form['attributes']
        # Create a flag if any form attributes were updated
        changeFlag = false
        # Loop over the new attributes to be assigned to the form
        new_attributes.each do |attribute|
          # Determine if the attribute already exists on the form (returns attribute name if it does)
          exists = current_attributes.find_index {|item| item['name'] == attribute['name']}

          if exists.nil?
            # If attribute doesn't exist and we need to create a new one, create the attribute
            if @parameters["create_new"].downcase == "true"
              current_attributes.push(attribute)
              changeFlag = true
            else
              # If the attribute doesn't exist and we shouldn't create a new one, break out of the loop
              break
            end
          # If the attribute DOES exist, and is not the same as the attribute provided in the parameter update it
          elsif current_attributes[exists] != attribute
            current_attributes[exists] = attribute
            changeFlag = true
          # If the attribute DOES exist, but it is the same, break out of the loop
          else
            break
          end
        end

        # If a change was made, update the form
        if changeFlag
          puts "Updating " + form["name"] + " with new attributes" if @enable_debug_logging
          # Build request to be sent for each form that needs to be updated
          data = {}
          data.tap do |json|
            json[:attributes] = current_attributes if !current_attributes.nil?
          end
          formResource = RestClient::Resource.new(form_api_route,
                                            user: @info_values["api_username"],
                                            password: @info_values["api_password"])
          # Update the Form
          formResult = formResource.put(data.to_json, { accept: :json, content_type: :json })
        end
      end
    rescue RestClient::Exception => error
      error_message = "#{error.http_code}: #{JSON.parse(error.response)["error"]}"
      raise error_message if error_handling == "Raise Error"
    rescue Exception => error
      error_message = error.inspect
      raise error if error_handling == "Raise Error"
    end

    # Build the results to be returned by this handler
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

  # This is a sample helper method that illustrates one method for retrieving
  # values from the input document.  As long as your node.xml document follows
  # a consistent format, these type of methods can be copied and reused between
  # handlers.
  def get_info_value(document, name)
    # Retrieve the XML node representing the desired info value
    info_element = REXML::XPath.first(document, "/handler/infos/info[@name='#{name}']")
    # If the desired element is nil, return nil; otherwise return the text value of the element
    info_element.nil? ? nil : info_element.text
  end
end

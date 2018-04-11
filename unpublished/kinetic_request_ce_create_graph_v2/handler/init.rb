# Require the dependencies file to load the vendor libraries
require File.expand_path(File.join(File.dirname(__FILE__), 'dependencies'))

class KineticRequestCeCreateGraphV2
  def initialize(input)
    # Set the input document attribute
    @input_document = REXML::Document.new(input)
	
    # Store the info values in a Hash of info names to values.
    @info_values = {}
    REXML::XPath.each(@input_document,"/handler/infos/info") do |item|
      @info_values[item.attributes["name"]] = item.text.to_s.strip
    end	

    # Retrieve all of the handler parameters and store them in a hash attribute
    # named @parameters.
    @parameters = {}
    REXML::XPath.match(@input_document, "/handler/parameters/parameter").each do |item|
      # Associate the attribute name to the String value (stripping leading and
      # trailing whitespace)
      @parameters[item.attributes["name"]] = item.text.to_s.strip
    end

    @enable_debug_logging = @info_values['enable_debug_logging'].downcase == 'yes' ||
                            @info_values['enable_debug_logging'].downcase == 'true'
    puts "Parameters: #{@parameters.inspect}" if @enable_debug_logging
  end

  def execute
    #Parse/handle data
	@datasets = JSON.parse(@parameters['data'])
	puts("datasets: #{@datasets.inspect}") if @enable_debug_logging
	@legend = []
	if !@parameters['labels'].nil? && !@parameters['labels'].empty?
		@legend = JSON.parse(@parameters['labels'])
	end
	@axiswithlabels = []
	if !@parameters['axiswithlabels'].nil? && !@parameters['axiswithlabels'].empty?
		@axiswithlabels = JSON.parse(@parameters['axiswithlabels'])
	end
	puts("Axes with Labels: #{@axiswithlabels.inspect}") if @enable_debug_logging
	@axislabels = []
	if !@parameters['axislabels'].nil? && !@parameters['axislabels'].empty?
		@axislabels = JSON.parse(@parameters['axislabels'])
	end
	puts("Axes Labels: #{@axislabels.inspect}") if @enable_debug_logging
	
	@legend_position = 'bottom'
	if !@parameters['legend_position'].nil? && !@parameters['legend_position'].empty?
		@legend_position = @parameters['legend_position'].downcase
	end
	puts("Legend Position: #{@legend_position}") if @enable_debug_logging
	
	@title = ''
	if !@parameters['title'].nil? && !@parameters['title'].empty?
		@title = @parameters['title']
	end
	puts("Title: #{@title}") if @enable_debug_logging
		
	tempFileName = Time.now.strftime("%d%m%Y%H%M%S")
		
	@type = @parameters['graph_type'].downcase
	#Build Graph
	if @type != "pie"
	@graph =  Gchart.new( :type => @type,
             :type => @type,
#			 :size => '600x400',
            :title => @title,
            :theme => :thirty7signals,
            :legend => @legend,
            :data => @datasets,
            :filename => tempFileName+".png",
            :stacked => false,
			:bar_width_and_spacing => [30,10],
            :legend_position => @legend_position,
            :axis_with_labels => @axiswithlabels,
            :max_value => @parameters['max_value'].to_f,
            :min_value => @parameters['min_value'].to_f,
            :axis_labels => @axislabels
            )
	else
	@graph =  Gchart.new( :type => @type,
             :type => @type,
#			 :size => '600x400',
            :title => @title,
            :theme => :thirty7signals,
            :legend => @legend,
            :data => @datasets,
            :filename => tempFileName+".png",
            :stacked => false,
			:bar_width_and_spacing => [30,10],
            :legend_position => @legend_position,
            :axis_with_labels => @axiswithlabels,
            :max_value => @parameters['max_value'].to_f,
            :min_value => @parameters['min_value'].to_f,
			:labels => @axislabels
            )
	end

# Record file in filesystem
@graph.file

	
	fileData = File.open(tempFileName+".png", "rb") {|io| io.read}
	
    #attach file to item
    space_slug = @parameters["space_slug"].empty? ? @info_values["space_slug"] : @parameters["space_slug"]
    
    file_content = fileData
    
	if @parameters["save_as"] == "Attachment"
	@file = @parameters["filename"]+".png"
	filename = @parameters["filename"]
    http_client = DefaultHttpClient.new
    httppost = HttpPost.new("#{@info_values["server"]}/#{space_slug}/#{@parameters["kapp_slug"]}/#{@parameters["form_slug"]}/files")
    httppost.setHeader("Authorization", "Basic " + Base64.encode64(@info_values["username"] + ':' + @info_values["password"]).gsub("\n",''))
    httppost.setHeader("Accept", "application/json")
    reqEntity = MultipartEntity.new
    byte = ByteArrayBody.new(file_content.to_java_bytes, "image/png", filename)
    reqEntity.addPart("file", byte)
    httppost.setEntity(reqEntity)
    response = http_client.execute(httppost)
    entity = response.getEntity
    resp = EntityUtils.toString(entity)
	
	#Clean up temp file
	File.delete(tempFileName+".png")
	
	if response.getStatusLine.getStatusCode != 200
      error_message = JSON.parse(resp)["error"]
      if @parameters["error_handling"] == "Raise Error"
        raise resp
      else
       return <<-RESULTS
          <results>
            <result name="Files"></result>
            <result name="Handler Error Message">#{response.getStatusLine.getStatusCode}: #{escape(error_message)}</result>
          </results>
        RESULTS
      end
	else
	@file = resp
    end
	
	else
	#save base 64 value to submission
	submission_id = @parameters["submissionId"]
	fieldname = @parameters["fieldname"]
	@file = fieldname
	answer = "data:image/png;base64,#{Base64.encode64(file_content)}"
	values = {}
	values[fieldname] = answer
	data = {}
	data["values"] = values
	datajson = data.to_json
	
	api_route = "#{@info_values["server"]}/#{space_slug}/app/api/v1/submissions/#{submission_id}"

    puts "API ROUTE: #{api_route}" if @enable_debug_logging

	begin
    resource = RestClient::Resource.new(api_route, { :user => @info_values["username"], :password => @info_values["password"] })
	
	puts "DATA: #{datajson}" if @enable_debug_logging

    # Post to the API
    response = resource.put(datajson, { :accept => "json", :content_type => "json" })


	#Clean up temp file
	File.delete(tempFileName+".png")
	
	rescue RestClient::Exception => error
      #error_message = JSON.parse(error.response)["error"]
	  error_message = response
      if @parameters["error_handling"]  == "Raise Error"
        raise error_message
      else
       return <<-RESULTS
        <results>
		  <result name="Files"></result>
          <result name="Handler Error Message">#{error.http_code}: #{escape(error_message)}</result>
        </results>
        RESULTS
      end
	
	end
	end
	


         
    return <<-RESULTS
      <results>
		<result name="Files">#{escape(@file)}</result>
        <result name="Handler Error Message"></result>
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

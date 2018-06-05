require "base64"

module KineticRequestCeNotificationTemplateSendHandlerHelperV1
  FIELD_TYPE_MAP = javax.activation.MimetypesFileTypeMap.new
  
  def embed(email, htmlbody)
    # Embed linked images into the html body if it is present
    unless htmlbody.nil? || htmlbody.empty?
      # Initialize a hash of image links to embeded values
      embedded_images = {}

      # Iterate over the body and embed necessary images
      htmlbody.scan(/"cid:(.*)"/) do |match|
        # The match variable is an array of Regex groups (specified with
        # parentheses); in this case the first match is the url
        url = match.first
        # Unless we have already embedded this url
        unless embedded_images.has_key?(url)
          cid = email.embed(url, "Embedded image")
          embedded_images[url] = cid
        end
      end

      # Replace the image URLs with their embedded values
      embedded_images.each do |url, cid|
        htmlbody.gsub!(url, cid)
      end

      # Set the HTML message
      email.setHtmlMsg(htmlbody);
    end
  end

  def parse_email(email)
    result = []
    if email.include?('<')
      # Add the address
      result << email.match(/<(.*)>/)[1]
      # Add the name
      result << email.match(/^\s*(.*?)\s*</)[1]
    else
      result << email
    end
    return result
  end

  def set_from(message, from, display_name)
    email, name = parse_email(from)
    name = display_name if !display_name.nil? && !display_name.empty?
    message.setFrom(email, name)
  end

  def add_reply_to(message, reply_to)
    message.addReplyTo(*parse_email(reply_to)) if reply_to
  end

  def add_to(message, to)
    to.each {|recipient| message.addTo(*parse_email(recipient))} if to
  end

  def add_cc(message, cc)
    cc.each {|recipient| message.addCc(*parse_email(recipient))} if cc
  end

  def add_bcc(message, bcc)
    bcc.each {|recipient| message.addBcc(*parse_email(recipient))} if bcc
  end

  def split_recipients(comma_separated_string)
    # Create an array of email addresses by splitting the parameter on any
    # combination of spaces followed by a comma followed by any number of spaces.
    (comma_separated_string || "").split(%r{\s*,\s*})
  end

  def unwrap_email_exception(exception)
    # Obtain the actual email_exception (which is in turn wrapped by Nativeemail_exception)
    email_exception = exception.is_a?(NativeException) ? exception.cause : exception
    # Add the real email_exception string to the stacktrace
    if email_exception.respond_to?('cause') && email_exception.cause
      # Modify the message to include the cause
      raise Exception, "#{exception.message} [#{email_exception.cause.to_s}]", exception.backtrace
      # Otherwise raise the email_exception
    else
      raise exception
    end
  end
end
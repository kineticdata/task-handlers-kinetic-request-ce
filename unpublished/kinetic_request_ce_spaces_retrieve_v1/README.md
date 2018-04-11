== Kinetic Request CE Spaces Retrieve
Retrieves a List of all Spaces on a Kinetic Core Instance and returns a JSON array

=== Parameters
[Error Handling]
    Determine what to return if an error is encountered. available menu choices: Error Message,Raise Error, default: Error Message
[Includes]
  CSV of what to include in the response (sent directly to rest call) (details,attributes,kapps...etc)

=== Sample Configuration
Includes::    attributes,details

=== Results
[Handler Error Message] (if appropriate)
[Spaces JSON]
   JSON array of Spaces

=== Detailed Description
This handler retrieves a list of all spaces in a Kinetic Core Env.
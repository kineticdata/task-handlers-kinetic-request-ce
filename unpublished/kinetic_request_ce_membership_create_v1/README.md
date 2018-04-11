== Kinetic Request CE Membership Create
DEPRECIATED in favor of "Team Membership Create" handler
Creates a membership. Team and user must already exist

=== Parameters
[Error Handling]
  Determine what to return if an error is encountered.
[Space Slug]
  The Space slug to be searched. If this value is not entered, the
  Space slug will default to the one configured in info values.
[Team Slug]
  The name of the team to create the memberhsip in. Must provide either name of slug of team.
[User]
  username to be added to the team

=== Sample Configuration
Error Handling:         Error Message
Space Slug:
Team Name:              Sample Team
Team Slug:              sample-team
User:                   test.user

=== Results
[Handler Error Message]
  Error message if an error was encountered and Error Handling is set to "Error Message".

=== Detailed Description
This handler creates a membership.
-- Used the Tumblr v1 API because it is light-years simpler http://www.tumblr.com/docs/en/api/v1#api_write
--
-- To use this, open it in the AppleScript Editor, change the properties below, 
--  switch to Mail and select the emails with pics attached that you wish to import to tumblr, 
--  switch back to the AppleScript Editor and press Run.
--
--  NOTE: tumblr limits your photo uploads to 75 per day, so plan accordingly.
--
 
property tumblr_email : "---"
property tumblr_password : "----"
property tumblr_group : "---.tumblr.com"

tell application "Finder" to set downloadPath to (path to downloads folder) as string
set downloadPosixPath to POSIX path of downloadPath as string

tell application "Mail"
	set postsCreated to 0
	set postsFailed to 0
	set selectedMessages to selection
	set AppleScript's text item delimiters to ""
	if (count of selectedMessages) is equal to 0 then
		display alert "No Messages Selected" message "Select the message you want to get the raw source of before running this script."
	else
		repeat with eachMessage in selectedMessages
			set message_sent to the date sent of eachMessage
			set {year:y, month:m, day:d, hours:h, minutes:min, seconds:s} to message_sent
			set post_time to y & "-" & m - 0 & "-" & d & " " & h & ":" & min & ":" & s -- TODO: blog's timezone thankfully matches
			set caption to the subject of eachMessage
			set post_data to ""
			set theOutputFolder to the downloadPath
			repeat with eachAttachment in every mail attachment of eachMessage
				set theSavePath to theOutputFolder & name of eachAttachment
				save eachAttachment in theSavePath
				set post_data to post_data & " -F \"data=@" & eachAttachment's name & ";type=" & eachAttachment's MIME type & "\""
			end repeat
			set tumblr_api_script to "cd " & quoted form of downloadPosixPath & ";/usr/bin/curl" & ¬
				" -L" & ¬
				" -F \"email=" & tumblr_email & "\" " & ¬
				" -F \"password=" & tumblr_password & "\" " & ¬
				" -F \"type=photo\" " & ¬
				" -F \"generator=AppleScript\" " & ¬
				" -F \"date=" & post_time & "\" " & ¬
				" -F \"group=" & tumblr_group & "\" " & ¬
				" -F \"send_to_twitter=auto\" " & ¬
				" -F \"caption=" & caption & "\" " & ¬
				post_data & ¬
				" -w \" %{http_code}\" http://www.tumblr.com/api/write "
			
			set upload_response to do shell script tumblr_api_script
			
			repeat with eachAttachment in every mail attachment of eachMessage
				do shell script "rm " & downloadPosixPath & eachAttachment's name
			end repeat
			
			if upload_response contains "201" then
				set postsCreated to postsCreated + 1
			else
				set postsFailed to postsFailed + 1
				log upload_response
			end if
			
		end repeat
		display alert "Posts Created" message "There were " & postsCreated & " posts created on Tumblr and " & postsFailed & " failures."
	end if
end tell

on urlencode(TheTextToEncode)
	return do shell script "/usr/bin/python -c 'import sys, urllib; print urllib.quote(sys.argv[1])' " & quoted form of TheTextToEncode
end urlencode

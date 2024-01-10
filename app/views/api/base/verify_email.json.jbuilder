json.set! :status, 200
json.set! :message, "Email verified successfully."

# Error responses
json.error do
  json.set! :status, 400
  json.set! :message, "Invalid or expired token." # For invalid or non-existing tokens
  json.set! :status, 404
  json.set! :message, "This token has already been used." # For already used tokens
end

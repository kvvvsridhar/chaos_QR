class UsersController < ApplicationController
    protect_from_forgery with: :null_session # For API-like behavior, if needed

    def index
        @users = User.all
    end
  
    # POST /users/update_from_qr
    def update_from_qr
        # Assuming the QR code data is sent as JSON in the request body
        qr_data = params[:qr_data]
    
        # Extract data from the QR code
        name = qr_data[:name]
        age = qr_data[:age]
        id_number = qr_data[:id_number]
        timestamp = qr_data[:last_scan_time] || Time.zone.now
        location = qr_data[:last_scan_location] || fetch_location
    
        # Update or create a user entry in the database
        #   user = User.find_or_initialize_by(id_number: id_number)
        user = User.find_by(id_number: id_number)
        user.update(name: name, age: age, last_scan_time: timestamp, last_scan_location: location)
    
        render json: { success: true, message: "User record updated successfully" }, status: :ok
        rescue => e
        render json: { success: false, message: e.message }, status: :unprocessable_entity
    end
  
    private
  
    # Mock location fetching method
    def fetch_location
        # Use an IP geolocation API or a default placeholder
        "Unknown Location"
    end
  end
  
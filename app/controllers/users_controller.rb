class UsersController < ApplicationController
    protect_from_forgery with: :null_session # For API-like behavior, if needed

    def index
        @users = User.all
    end

    def new
        @user = User.new
    end
    
    def create
        @user = User.new(user_params)
        if @user.save
            redirect_to users_path, notice: 'User was successfully created.'
        else
            flash.now[:alert] = 'Failed to create the user. Please check the input.'
            render :new
        end
    end
  
    # POST /users/update_from_qr
    def update_from_qr
        begin
            # Parse JSON input
            qr_data = JSON.parse(params[:qr_data])
            id_number = qr_data["id_number"]
            
            # Find user by id_number
            user = User.find_by(id_number: id_number)
            
            if user
                # Update the user with the last scan details
                user.update(
                    last_scan_time: Time.current,
                    last_scan_location: params[:location]
                )
                render json: { success: true, message: "User data updated successfully." }, status: :ok
            else
                render json: { success: false, message: "User with id_number '#{id_number}' not found." }, status: :not_found
            end
        rescue JSON::ParserError
            render json: { success: false, message: "Invalid QR code data format." }, status: :unprocessable_entity
        rescue StandardError => e
            render json: { success: false, message: e.message }, status: :internal_server_error
        end
    end

    def qr_code_generator
        @users = User.all
    end
    
    def generate_qr_code
        user = User.find(params[:user_id])
    
        # Prepare the QR data in the specified JSON format
        qr_data = {
          name: user.name,
          age: user.age,
          id_number: user.id_number
        }.to_json

        # Generate the QR code as PNG
        qr_code = RQRCode::QRCode.new(qr_data)
        png = qr_code.as_png(
          size: 300,
          border_modules: 2,
          color: 'black',
          fill: 'white'
        )
    
        # Send the generated QR code back
        send_data png.to_s, type: 'image/png', disposition: 'inline'
    end

    private

    # Mock location fetching method
    def fetch_location
        # Use an IP geolocation API or a default placeholder
        "Unknown Location"
    end

    def user_params
        params.require(:user).permit(:name, :id_number, :age)
    end
end

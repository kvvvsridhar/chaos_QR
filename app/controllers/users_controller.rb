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

    def update_from_qr
        begin
          qr_data = JSON.parse(params[:qr_data])
          id_number = qr_data["id_number"]
          
          user = User.find_by(id_number: id_number)
          
          if user
            user.update(
              last_scan_time: Time.current,
              last_scan_location: params[:location]
            )
            render json: { success: true, message: "Entry scan updated successfully." }, status: :ok
          else
            render json: { success: false, message: "User not found." }, status: :not_found
          end
        rescue JSON::ParserError
          render json: { success: false, message: "Invalid QR data." }, status: :unprocessable_entity
        rescue StandardError => e
          render json: { success: false, message: e.message }, status: :internal_server_error
        end
      end
    
      # Exit Scan (new method)
      def update_exit_from_qr
        begin
          qr_data = JSON.parse(params[:qr_data])
          id_number = qr_data["id_number"]
          
          user = User.find_by(id_number: id_number)
          
          if user
            user.update(
              exit_time: Time.current,
              exit_location: params[:location]
            )
            render json: { success: true, message: "Exit scan updated successfully." }, status: :ok
          else
            render json: { success: false, message: "User not found." }, status: :not_found
          end
        rescue JSON::ParserError
          render json: { success: false, message: "Invalid QR data." }, status: :unprocessable_entity
        rescue StandardError => e
          render json: { success: false, message: e.message }, status: :internal_server_error
        end
      end
  
    def qr_code_generator
      @users = User.all
    end
  
    def generate_qr_code
      user = User.find(params[:user_id])
  
      qr_data = {
        "name": user.name,
        "age": user.age,
        "id_number": user.id_number
      }.to_json
  
      qr_code = RQRCode::QRCode.new(qr_data)
      file_path = Rails.root.join('tmp', "#{user.id_number}_qr.png")
  
      IO.binwrite(file_path, qr_code.as_png(size: 300, border_modules: 2, color: 'black', fill: 'white').to_s)
  
      save_to_excel_with_image(user, qr_data, file_path)
  
      # Clean up temporary QR code file
    #   File.delete(file_path) if File.exist?(file_path)
  
      send_data IO.binread(file_path), type: 'image/png', disposition: 'inline'
    end

    def generate_qr_codes_for_all
        users_without_qr = User.where(qr_code: nil)
    
        users_without_qr.each do |user|
            user.generate_and_save_qr_code
        rescue StandardError => e
            Rails.logger.error "Failed to generate QR code for User ID #{user.id}: #{e.message}"
        end
    
        redirect_to users_path, notice: 'QR codes have been generated for all users without one.'
    end
  
    private
  
    def save_to_excel_with_image(user, qr_data, image_path)
        excel_file_path = Rails.root.join('public', 'qr_codes_with_images.xlsx')
        image_column_index = 3

        # Step 1: Read existing data and recreate the workbook
        existing_data = []
        existing_images = []
        if File.exist?(excel_file_path)
            workbook = Roo::Excelx.new(excel_file_path.to_s)
            sheet = workbook.sheet(0)

            sheet.each_with_index do |row, index|
                next if index.zero? # Skip headers

                # Collect row data
                existing_data << row[0..2]

                # Collect image file paths for existing rows
                # Assuming a naming convention for image files based on ID or index
                id_number = row[1] # Assuming column 1 (ID) stores the unique identifier
                image_file = Rails.root.join('tmp', "#{id_number}_qr.png")
                existing_images << image_file if File.exist?(image_file)
            end
        end

        # Step 2: Create a new workbook and write existing data
        workbook = WriteXLSX.new(excel_file_path.to_s)
        worksheet = workbook.add_worksheet('QR Codes')

        # Add headers
        worksheet.write_row(0, 0, ['Name', 'ID Number', 'QR Data', 'QR Code'])

        # Write existing rows and images
        existing_data.each_with_index do |row, index|
        worksheet.write_row(index + 1, 0, row)

        # Insert existing images
        image_file = existing_images[index]
        if image_file
            worksheet.insert_image(
                index + 1, image_column_index, image_file.to_s,
                { x_scale: 0.5, y_scale: 0.5 }
                )
            end
        end

        # Step 3: Add new data and image
        last_row = existing_data.size + 1
        worksheet.write(last_row, 0, user.name)
        worksheet.write(last_row, 1, user.id_number)
        worksheet.write(last_row, 2, qr_data)

        # Insert new image
        worksheet.insert_image(
            last_row, image_column_index, image_path.to_s,
            { x_scale: 0.5, y_scale: 0.5 }
        )

         # Generate a relative or absolute path to the image for hyperlinking
        # image_url = "/public/#{File.basename(image_path)}"

        # # Add a hyperlink to the image
        # worksheet.write_url(last_row, 4, "file://#{Rails.root.join(image_url)}", nil, 'View QR Code')


        # Save the workbook
        workbook.close
    end

    # def save_to_excel_with_image(user, qr_data, image_path)
    #     excel_file_path = Rails.root.join('public', 'qr_codes_with_images.xlsx')
    #     workbook, worksheet, last_row = initialize_excel_file(excel_file_path)
      
    #     # Add user data to the next available row
    #     worksheet.write(last_row, 0, user.name)
    #     worksheet.write(last_row, 1, user.id_number)
    #     worksheet.write(last_row, 2, qr_data)
      
    #     # Generate a relative or absolute path to the image for hyperlinking
    #     image_url = "/public/#{File.basename(image_path)}"
      
    #     # Add a hyperlink to the image
    #     worksheet.write_url(last_row, 3, "file://#{Rails.root.join(image_url)}", nil, 'View QR Code')
      
    #     # Save the workbook
    #     workbook.close
    # end
      
  
    def get_last_row(file_path)
        xlsx = Roo::Excelx.new(file_path)
        sheet = xlsx.sheet(0)
        last_row = sheet.last_row || 0
        last_row + 1 # Return the next available row
    end
  
    def user_params
        params.require(:user).permit(:name, :id_number, :age)
    end
  end
  